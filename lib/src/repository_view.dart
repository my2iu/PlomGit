import 'dart:io';

import 'package:flutter/material.dart';
import 'package:libgit2/libgit2.dart';
import 'package:path/path.dart' as path;
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'commit_view.dart';
import 'remote_view.dart' show RemoteListView;
import 'util.dart'
    show
        GitStatusFlags,
        GitRepositoryState,
        TextAndIcon,
        PlomGitPrefs,
        showProgressWhileWaitingFor,
        retryWithAskCredentials;

class RepositoryView extends StatefulWidget {
  final String repositoryName;
  final Uri repositoryUri;
  final String pathInRepository;

  const RepositoryView(this.repositoryName, this.repositoryUri,
      [this.pathInRepository = ""]);
  @override
  State<RepositoryView> createState() =>
      _RepositoryViewState(repositoryName, repositoryUri, pathInRepository);
}

class _RepositoryViewState extends State<RepositoryView> {
  final String repositoryName;
  final Uri repositoryUri;
  final String _path;
  String get repositoryDir => repositoryUri.toFilePath();
  late Future<List<FileSystemEntity>> dirContents;
  late Future<Map<String, GitStatusFlags>> gitStatus;
  late Future<GitRepositoryState> repoStateFuture;

  List<String> remoteList = [];
  GitRepositoryState? repoState;
  int? ahead;
  int? behind;

  _RepositoryViewState(this.repositoryName, this.repositoryUri, this._path) {
    _loadRepositoryInfo();
  }

  void _loadRepositoryInfo() {
    dirContents = Directory.fromUri(repositoryUri.resolve(_path))
        .list()
        .toList()
        .then((list) {
      list.sort((a, b) {
        if (a is Directory && !(b is Directory)) return -1;
        if (!(a is Directory) && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      return list;
    });
    gitStatus = dirContents
        .then((_) => GitIsolate.instance.status(repositoryDir))
        .then((entries) => _processGitStatusEntries(entries));
    repoStateFuture = gitStatus
        .catchError((err) {
          // Ignore errors
          return <String, GitStatusFlags>{};
        })
        .then((_) => GitIsolate.instance.repositoryState(repositoryDir))
        .then((state) {
          var s = GitRepositoryState.fromState(state);
          setState(() {
            repoState = s;
          });
          return s;
        });
    repoStateFuture
        .catchError((err) {
          // Ignore errors
        })
        .then((_) => GitIsolate.instance.aheadBehind(repositoryDir))
        .then((diffList) {
          setState(() {
            ahead = diffList[0];
            behind = diffList[1];
          });
        });
    GitIsolate.instance.listRemotes(repositoryDir).then((remotes) {
      remoteList = remotes;
    });
  }

  void _refresh() {
    setState(() {
      _loadRepositoryInfo();
    });
  }

  Map<String, GitStatusFlags> _processGitStatusEntries(List<dynamic> entries) {
    Map<String, GitStatusFlags> statusMap = {};
    entries.forEach((entry) {
      // TODO: Handle rename and copy and status for directories
      GitStatusFlags flags = GitStatusFlags.fromFlags(entry[2]);
      statusMap[entry[0] ?? entry[1]] = flags;

      // Add entries for parent directories
      var parents = path.split(entry[0] ?? entry[1]);
      parents.removeLast();
      String parentPath = "";
      parents.forEach((dirname) {
        parentPath += '$dirname/';
        GitStatusFlags parentFlags =
            statusMap.putIfAbsent(parentPath, () => GitStatusFlags());
        if (flags.isStaged)
          parentFlags.dirHasStagedModifications = true;
        else if (flags.isNew || flags.isModified || flags.isDeleted)
          parentFlags.dirHasUnstagedModifications = true;
        if (!flags.isNew) parentFlags.dirIsInGit = true;
      });
    });
    return statusMap;
  }

  Widget buildActionsPopupMenu(BuildContext context) {
    List<Widget> entries = [];
    {
      for (var remote in remoteList) {
        entries.add(MenuItemButton(
            onPressed: () => _fetchFromRemote(context, remote),
            child: TextAndIcon(
                Text('Fetch from $remote'),
                Icon(Icons.cloud_download_outlined,
                    color: Theme.of(context).iconTheme.color))));
      }
      for (var remote in remoteList) {
        entries.add(MenuItemButton(
            onPressed: () => _pushToRemote(context, remote),
            child: TextAndIcon(
                Text('Push to $remote'),
                Icon(Icons.cloud_upload_outlined,
                    color: Theme.of(context).iconTheme.color))));
      }
      entries.add(MenuItemButton(
        onPressed: () => _mergeWithUpstream(context),
        child: TextAndIcon(const Text('Merge with upstream'),
            Icon(Icons.call_merge, color: Theme.of(context).iconTheme.color)),
      ));
      entries.add(MenuItemButton(
          onPressed: () => _refresh(),
          child: TextAndIcon(const Text("Refresh"),
              Icon(Icons.refresh, color: Theme.of(context).iconTheme.color))));
      entries.add(MenuItemButton(
          onPressed: () => _showCommitScreen(context),
          child: TextAndIcon(const Text("Commit..."),
              Icon(Icons.save_alt, color: Theme.of(context).iconTheme.color))));
      entries.add(const Divider());
      entries.add(MenuItemButton(
          onPressed: () => _showRemoteListScreen(context),
          child: TextAndIcon(
              const Text("Remotes..."),
              Icon(Icons.cloud_outlined,
                  color: Theme.of(context).iconTheme.color))));
    }

    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            controller.isOpen ? controller.close() : controller.open();
          },
        );
      },
      menuChildren: entries,
    );
  }

  void _fetchFromRemote(BuildContext context, String remote) {
    showProgressWhileWaitingFor(
            context,
            retryWithAskCredentials(
                repositoryName,
                remote,
                (user, password) => GitIsolate.instance
                    .fetch(repositoryDir, remote, user, password),
                context))
        .then((result) {
      _refresh();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fetch successful')));
    }).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    });
  }

  void _pushToRemote(BuildContext context, String remote) {
    showProgressWhileWaitingFor(
            context,
            retryWithAskCredentials(
                repositoryName,
                remote,
                (username, password) => GitIsolate.instance
                    .push(repositoryDir, remote, username, password),
                context))
        .then((result) {
      _refresh();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Push successful')));
    }).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    });
  }

  void _mergeWithUpstream(BuildContext context) {
    GitIsolate.instance.mergeWithUpstream(repositoryDir).then((result) {
      String message;
      switch (result) {
        case MergeStatus.FAST_FORWARD:
          message = "Merge fast-forward";
          break;
        case MergeStatus.MERGE_FAILED:
          message = "Cannot merge";
          break;
        case MergeStatus.NORMAL_MERGE:
          message = "Merge complete, please commit";
          break;
        case MergeStatus.NO_HEAD:
          message = "No HEAD commit to merge";
          break;
        case MergeStatus.UP_TO_DATE:
          message = "Merge already up-to-date";
          break;
      }
      if (result == MergeStatus.NORMAL_MERGE) {
        PlomGitPrefs.instance
            .writeRepositoryCommitMessage(repositoryName, "Merge");
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      _refresh();
    }).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    });
  }

  void _showCommitScreen(BuildContext context) {
    repoStateFuture
        .then((state) => Navigator.push(
            context,
            MaterialPageRoute<String>(
                builder: (BuildContext context) => CommitPrepareChangesView(
                    repositoryName, repositoryUri, state.merge))))
        .then((result) {
      _refresh();
      if (result != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      }
    });
    // Show the commit screen
  }

  void _showRemoteListScreen(BuildContext context) {
    repoStateFuture
        .then((state) => Navigator.push(
            context,
            MaterialPageRoute<String>(
                builder: (BuildContext context) =>
                    RemoteListView(repositoryName, repositoryUri))))
        .then((result) {
      _refresh();
      if (result != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      }
    });
    // Show the remote list screen
  }

  Widget _makeFileListTile(BuildContext context, FileSystemEntity entry) {
    // return Text(snapshot.data[index].path);
    var fname = path.basename(entry.path);
    var isDir = entry is Directory;
    if (isDir) fname += '/';
    var relativePath = path.relative(entry.path, from: repositoryDir);
    if (isDir) relativePath += '/';
    var icon = FutureBuilder<Map<String, GitStatusFlags>>(
        future: gitStatus,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, GitStatusFlags>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.containsKey(relativePath)) {
              GitStatusFlags statusFlags = snapshot.data![relativePath]!;
              if (!isDir) {
                if (statusFlags.isNew) {
                  if (statusFlags.isStaged)
                    return const Icon(Icons.add_circle);
                  else
                    return const Icon(Icons.add);
                }
                if (statusFlags.isModified) {
                  if (statusFlags.isStaged)
                    return const Icon(Icons.build_circle);
                  else
                    return const Icon(Icons.build_circle_outlined);
                }
                if (statusFlags.isDeleted) {
                  if (statusFlags.isStaged)
                    return const Icon(Icons.remove_circle);
                  else
                    return const Icon(Icons.remove_circle_outlined);
                }
                if (statusFlags.isConflicted) {
                  if (statusFlags.isStaged)
                    return const Icon(Icons.swap_horizontal_circle);
                  else
                    return const Icon(Icons.swap_horizontal_circle_outlined);
                }
                if (!statusFlags.isStaged)
                  return const Icon(Icons.lens_outlined);
              } else {
                if (statusFlags.dirHasStagedModifications &&
                    !statusFlags.dirHasUnstagedModifications)
                  return const Icon(Icons.folder);
                else if (statusFlags.dirHasStagedModifications &&
                    statusFlags.dirHasUnstagedModifications)
                  return const Icon(Icons.snippet_folder);
                else if (!statusFlags.dirHasStagedModifications &&
                    statusFlags.dirHasUnstagedModifications &&
                    statusFlags.dirIsInGit)
                  return const Icon(Icons.snippet_folder_outlined);
                else if (!statusFlags.dirHasStagedModifications &&
                    statusFlags.dirHasUnstagedModifications &&
                    !statusFlags.dirIsInGit)
                  return const Icon(Icons.create_new_folder_outlined);
                else if (statusFlags.dirIsInGit)
                  return const Icon(Icons.folder_outlined);
                else
                  return const Icon(null);
              }
            }
            // Icons.adjust, Icons.album, Icons.album_outlined, Icons.radio_button_checked, Icons.scatter_plot
            // Icons.stop, Icons.stop_cicle_outlined, Icons.stop_circle_sharp, Icons.stop_circle, Icons.stop_outlined
            // Icons.pause, Icons.pause_circle_outline, Icons.pause_circle_filled, Icons.circle
            // Icons.cancel, Icons.cancel_outlined, Icons.clear
            // Icons.source, Icons.source_outlined
            // Icons.note_add, Icons.note_add_outlined, Icons.description, Icons.description_outlined, Icons.insert_drive_file, Icons.insert_drive_file_outlined
            // Icons.radio_button_off
            // Icons.swap_horiz, Icons.swap_horizontal_circle, Icons.swap_horizontal_circle_outlined
            //   return Icon(Icons.stop_circle, color: Colors.blueGrey);
            return const Icon(null);
          } else {
            return const Icon(null);
          }
        });
    return ListTile(
        title: TextAndIcon(Text(fname), icon),
        onTap: () {
          if (isDir) {
            Navigator.push(
                    context,
                    MaterialPageRoute<String>(
                        builder: (BuildContext context) => RepositoryView(
                            repositoryName, repositoryUri, _path + fname)))
                .then((_) => _refresh());
          }
        });
  }

  Widget? _makeStatusBar() {
    TextStyle textStyle = Theme.of(context).textTheme.titleSmall!;
    double size = textStyle.fontSize!;
    // String repoStateMessage = "";
    if ((repoState == null || !repoState!.normal) &&
        (ahead == null || ahead == 0) &&
        (behind == null || behind == 0)) return null;
    List<Widget> children = [];
    if (repoState != null && repoState!.merge) {
      children.add(Icon(Icons.call_merge, color: textStyle.color, size: size));
    }
    if (ahead != null && ahead != 0) {
      if (children.isNotEmpty) children.add(SizedBox(width: size / 2));
      children.add(Text(ahead.toString(), style: textStyle));
      children
          .add(Icon(Icons.arrow_upward, color: textStyle.color, size: size));
    }
    if (behind != null && behind != 0) {
      if (children.isNotEmpty) children.add(SizedBox(width: size / 2));
      children.add(Text(behind.toString(), style: textStyle));
      children
          .add(Icon(Icons.arrow_downward, color: textStyle.color, size: size));
    }
    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    Widget title;
    TextTheme appBarTextTheme = //Theme.of(context).appBarTheme.textTheme ??
        Theme.of(context).textTheme;
    if (_path.isNotEmpty) {
      title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(repositoryName),
        Text(_path, style: appBarTextTheme.bodySmall)
      ]);
    } else {
      title = Text(repositoryName);
    }
    List<Widget> appBarActions = [];
    Widget? statusInfo = _makeStatusBar();
    if (statusInfo != null) appBarActions.add(statusInfo);
    appBarActions.add(buildActionsPopupMenu(context));
    return Scaffold(
        appBar: AppBar(
          title: title,
          actions: appBarActions,
        ),
        body: FutureBuilder<List<FileSystemEntity>>(
            future: dirContents,
            builder: (BuildContext context,
                AsyncSnapshot<List<FileSystemEntity>> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) =>
                        _makeFileListTile(context, snapshot.data![index]));
              } else {
                return const Text('Loading');
              }
            }));
  }
}
