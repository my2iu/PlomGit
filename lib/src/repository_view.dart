import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:PlomGit/src/git_isolate.dart' show GitIsolate;

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
  List<String> remoteList;

  _RepositoryViewState(this.repositoryName, this.repositoryUri, this._path) {
    dirContents =
        Directory.fromUri(repositoryUri.resolve(_path)).list().toList();
    GitIsolate.instance.listRemotes(repositoryDir).then((remotes) {
      remoteList = remotes;
    });
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
                    GitIsolate.instance
                        .fetch(repositoryDir, remote)
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
                    GitIsolate.instance
                        .push(repositoryDir, remote)
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
          }
          return entries;
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
                    itemBuilder: (context, index) {
                      // return Text(snapshot.data[index].path);
                      var fname = path.basename(snapshot.data[index].path);
                      var isDir = snapshot.data[index] is Directory;
                      if (isDir) fname += '/';
                      return ListTile(
                          title: Text(fname),
                          onTap: () {
                            if (isDir) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute<String>(
                                      builder: (BuildContext context) =>
                                          RepositoryView(repositoryName,
                                              repositoryUri, _path + fname)));
                            }
                          });
                    });
              } else {
                return Text('Loading');
              }
            }));
  }
}
