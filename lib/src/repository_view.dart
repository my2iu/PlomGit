import 'dart:io';

import 'package:flutter/material.dart';
import 'package:PlomGit/src/jsgit.dart' show JsForGit;
import 'package:path/path.dart' as path;

class RepositoryView extends StatefulWidget {
  final String repositoryName;
  final JsForGit jsGit;
  final Uri repositoryUri;
  RepositoryView(this.repositoryName, this.repositoryUri, this.jsGit);
  @override
  _RepositoryViewState createState() =>
      _RepositoryViewState(repositoryName, repositoryUri);
}

class _RepositoryViewState extends State<RepositoryView> {
  final String repositoryName;
  final Uri repositoryUri;
  Future<List<FileSystemEntity>> dirContents;
  _RepositoryViewState(this.repositoryName, this.repositoryUri) {
    dirContents = Directory.fromUri(repositoryUri).list().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(repositoryName),
        ),
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
