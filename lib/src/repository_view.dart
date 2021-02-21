import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:PlomGit/src/git_isolate.dart' show GitIsolate;

class RepositoryView extends StatefulWidget {
  final String repositoryName;
  // final JsForGit jsGit;
  final Uri repositoryUri;

  RepositoryView(this.repositoryName, this.repositoryUri);
  @override
  _RepositoryViewState createState() =>
      _RepositoryViewState(repositoryName, repositoryUri);
}

class _RepositoryViewState extends State<RepositoryView> {
  final String repositoryName;
  final Uri repositoryUri;
  String get repositoryDir => repositoryUri.toFilePath();
  Future<List<FileSystemEntity>> dirContents;
  List<String> remoteList;

  _RepositoryViewState(this.repositoryName, this.repositoryUri) {
    dirContents = Directory.fromUri(repositoryUri).list().toList();
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
          }
          return entries;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(repositoryName),
            actions: <Widget>[buildActionsPopupMenu(context)]),
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
                      if (snapshot.data[index] is Directory) fname += '/';
                      return ListTile(title: Text(fname));
                    });
              } else {
                return Text('Loading');
              }
            }));
  }
}
