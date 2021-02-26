import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:libgit2/git_isolate.dart' show GitIsolate;
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

class _RepositoryViewState extends State<RepositoryView> {
  final String repositoryName;
  final Uri repositoryUri;
  final String _path;
  String get repositoryDir => repositoryUri.toFilePath();
  Future<List<FileSystemEntity>> dirContents;
  Future<Map<String, int>> gitStatus;
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

  Map<String, int> _processGitStatusEntries(List<dynamic> entries) {
    Map<String, int> statusMap = {};
    entries.forEach((entry) {
      statusMap[entry[0] ?? entry[1]] = entry[2];
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
                  child: Text('Fetch from $remote')));
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
                  child: Text('Push to $remote')));
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
        builder:
            (BuildContext context, AsyncSnapshot<Map<String, int>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.containsKey(relativePath)) {
              if (snapshot.data[relativePath] & 128 != 0) {
                return Icon(Icons.add);
              }
              if (snapshot.data[relativePath] == 0)
                return Icon(Icons.lens_outlined);
              print(snapshot.data[relativePath]);
            }
            if (isDir && fname.startsWith('l'))
              return Icon(Icons.build_circle);
            else if (isDir && fname.startsWith('t'))
              return Icon(Icons.radio_button_off);
            else if (isDir)
              return Icon(null);
            else
              return Icon(Icons.lens_outlined);
          } else {
            return Icon(null);
          }
        });
    return ListTile(
        title: Row(children: [icon, SizedBox(width: 5), Text(fname)]),
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
