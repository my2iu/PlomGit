import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'commit_view.dart';
import 'util.dart';

class RepositoryView extends StatefulWidget {
  final String repositoryName;
  // final JsForGit jsGit;
  final Uri repositoryUri;
  final String pathInRepository;

  RepositoryView(this.repositoryName, this.repositoryUri,
      [this.pathInRepository = ""]);
  @override
  _RepositoryViewState createState() =>
      _RepositoryViewState(repositoryName, repositoryUri, pathInRepository);
}

class _GitStatusFlags {
  bool isStaged = false;
  bool isModified = false;
  bool isNew = false;
  bool isDeleted = false;

  bool dirHasUnstagedModifications = false;
  bool dirHasStagedModifications = false;
  bool dirIsInGit = false;
}

class _RepositoryViewState extends State<RepositoryView> {
  final String repositoryName;
  final Uri repositoryUri;
  final String _path;
  String get repositoryDir => repositoryUri.toFilePath();
  Future<List<FileSystemEntity>> dirContents;
  Future<Map<String, _GitStatusFlags>> gitStatus;
  List<String> remoteList;

  _RepositoryViewState(this.repositoryName, this.repositoryUri, this._path) {
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
    GitIsolate.instance.listRemotes(repositoryDir).then((remotes) {
      remoteList = remotes;
    });
  }

  Map<String, _GitStatusFlags> _processGitStatusEntries(List<dynamic> entries) {
    Map<String, _GitStatusFlags> statusMap = {};
    entries.forEach((entry) {
      _GitStatusFlags flags = _GitStatusFlags();

      // TODO: Handle rename and copy and status for directories
      int gitFlags = entry[2];
      flags.isStaged = (gitFlags & (1 | 2 | 4 | 8 | 16)) != 0;
      flags.isNew = (gitFlags & (1 | 128)) != 0;
      flags.isModified = (gitFlags & (2 | 16 | 256 | 2048)) != 0;
      flags.isDeleted = (gitFlags & (4 | 512)) != 0;
      statusMap[entry[0] ?? entry[1]] = flags;

      // Add entries for parent directories
      var parents = path.split(entry[0] ?? entry[1]);
      parents.removeLast();
      String parentPath = "";
      parents.forEach((dirname) {
        parentPath += dirname + '/';
        if (!statusMap.containsKey(parentPath))
          statusMap[parentPath] = _GitStatusFlags();
        _GitStatusFlags parentFlags = statusMap[parentPath];
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
    return PopupMenuButton(
        onSelected: (fn) => fn(),
        itemBuilder: (BuildContext context) {
          List<PopupMenuEntry> entries = List();
          if (remoteList != null) {
            remoteList.forEach((remote) {
              entries.add(PopupMenuItem(
                  value: () {
                    retryWithAskCredentials(
                            (user, password) => GitIsolate.instance
                                .fetch(repositoryDir, remote),
                            context)
                        .then((result) {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text('Fetch successful')));
                    }).catchError((error) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Error: ' + error.toString())));
                    });
                  },
                  child: TextAndIcon(
                      Text('Fetch from $remote'),
                      Icon(Icons.cloud_download_outlined,
                          color: Theme.of(context).iconTheme.color))));
            });
            remoteList.forEach((remote) {
              entries.add(PopupMenuItem(
                  value: () {
                    retryWithAskCredentials(
                            (username, password) => GitIsolate.instance.push(
                                repositoryDir, remote, username, password),
                            context)
                        .then((result) {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text('Push successful')));
                    }).catchError((error) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Error: ' + error.toString())));
                    });
                  },
                  child: TextAndIcon(
                      Text('Push to $remote'),
                      Icon(Icons.cloud_upload_outlined,
                          color: Theme.of(context).iconTheme.color))));
            });
            entries.add(PopupMenuItem(
                value: () {
                  GitIsolate.instance.status(repositoryDir).then((result) {
                    Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text('Status successful')));
                  }).catchError((error) {
                    Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ' + error.toString())));
                  });
                },
                child: Text('Test status')));
            entries.add(PopupMenuItem(
                value: () {
                  File(repositoryDir + '/test.txt').writeAsString("hello");
                },
                child: Text('Test make file')));
            entries.add(PopupMenuItem(
                value: () {
                  showDialog(
                          context: context,
                          builder: (context) => makeLoginDialog(context))
                      .then((result) {
                    print(result);
                  });
                },
                child: Text('Test dialog')));
            entries.add(PopupMenuItem(
                value: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute<String>(
                          builder: (BuildContext context) =>
                              CommitView(repositoryName, repositoryUri)));

                  // Show the commit screen
                },
                child: TextAndIcon(
                    Text("Commit"),
                    Icon(Icons.save_alt,
                        color: Theme.of(context).iconTheme.color))));
          }
          return entries;
        });
  }

  Widget _makeFileListTile(BuildContext context, FileSystemEntity entry) {
    // return Text(snapshot.data[index].path);
    var fname = path.basename(entry.path);
    var isDir = entry is Directory;
    if (isDir) fname += '/';
    var relativePath = path.relative(entry.path, from: repositoryDir);
    if (isDir) relativePath += '/';
    var icon = FutureBuilder(
        future: gitStatus,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, _GitStatusFlags>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.containsKey(relativePath)) {
              var statusFlags = snapshot.data[relativePath];
              if (!isDir) {
                if (statusFlags.isNew) {
                  if (statusFlags.isStaged)
                    return Icon(Icons.add_circle);
                  else
                    return Icon(Icons.add);
                }
                if (statusFlags.isModified) {
                  if (statusFlags.isStaged)
                    return Icon(Icons.build_circle);
                  else
                    return Icon(Icons.build_circle_outlined);
                }
                if (statusFlags.isDeleted) {
                  if (statusFlags.isStaged)
                    return Icon(Icons.remove_circle);
                  else
                    return Icon(Icons.remove_circle_outlined);
                }
                if (!statusFlags.isStaged) return Icon(Icons.lens_outlined);
              } else {
                if (statusFlags.dirHasStagedModifications &&
                    !statusFlags.dirHasUnstagedModifications)
                  return Icon(Icons.folder);
                else if (statusFlags.dirHasStagedModifications &&
                    statusFlags.dirHasUnstagedModifications)
                  return Icon(Icons.snippet_folder);
                else if (!statusFlags.dirHasStagedModifications &&
                    statusFlags.dirHasUnstagedModifications &&
                    statusFlags.dirIsInGit)
                  return Icon(Icons.snippet_folder_outlined);
                else if (!statusFlags.dirHasStagedModifications &&
                    statusFlags.dirHasUnstagedModifications &&
                    !statusFlags.dirIsInGit)
                  return Icon(Icons.create_new_folder_outlined);
                else if (statusFlags.dirIsInGit)
                  return Icon(Icons.folder_outlined);
                else
                  return Icon(null);
              }
            }
            // Icons.adjust, Icons.album, Icons.album_outlined, Icons.radio_button_checked, Icons.scatter_plot
            // Icons.stop, Icons.stop_cicle_outlined, Icons.stop_circle_sharp, Icons.stop_circle, Icons.stop_outlined
            // Icons.pause, Icons.pause_circle_outline, Icons.pause_circle_filled, Icons.circle
            // Icons.cancel, Icons.cancel_outlined, Icons.clear
            // Icons.source, Icons.source_outlined
            // Icons.note_add, Icons.note_add_outlined, Icons.description, Icons.description_outlined, Icons.insert_drive_file, Icons.insert_drive_file_outlined
            // Icons.radio_button_off
            //   return Icon(Icons.stop_circle, color: Colors.blueGrey);
            return Icon(null);
          } else {
            return Icon(null);
          }
        });
    return ListTile(
        title: TextAndIcon(Text(fname), icon),
        // leading: icon,
        onTap: () {
          if (isDir) {
            Navigator.push(
                context,
                MaterialPageRoute<String>(
                    builder: (BuildContext context) => RepositoryView(
                        repositoryName, repositoryUri, _path + fname)));
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget title;
    TextTheme appBarTextTheme = Theme.of(context).appBarTheme.textTheme ??
        Theme.of(context).primaryTextTheme;
    if (_path.isNotEmpty) {
      title = Column(children: [
        Text(repositoryName),
        Text(_path, style: appBarTextTheme.caption)
      ]);
    } else {
      title = Text(repositoryName);
    }
    return Scaffold(
        appBar: AppBar(
            title: title, actions: <Widget>[buildActionsPopupMenu(context)]),
        body: FutureBuilder(
            future: dirContents,
            builder: (BuildContext context,
                AsyncSnapshot<List<FileSystemEntity>> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) =>
                        _makeFileListTile(context, snapshot.data[index]));
              } else {
                return Text('Loading');
              }
            }));
  }
}
