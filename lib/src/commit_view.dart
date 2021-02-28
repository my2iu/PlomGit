import 'package:PlomGit/src/util.dart';
import 'package:flutter/material.dart';
import 'package:libgit2/git_isolate.dart' show GitIsolate;

class CommitView extends StatefulWidget {
  CommitView(this.repositoryName, this.repositoryUri);

  final String repositoryName;
  final Uri repositoryUri;

  @override
  CommitViewState createState() =>
      CommitViewState(repositoryName, repositoryUri);
}

class CommitViewState extends State<CommitView> {
  CommitViewState(this.repositoryName, this.repositoryUri) {
    gitStatus = GitIsolate.instance.status(repositoryDir);
  }

  String repositoryName;
  Uri repositoryUri;
  String get repositoryDir => repositoryUri.toFilePath();
  Future<dynamic> gitStatus;

  Widget _makeCommitUi(List<dynamic> allChanges) {
    List<String> staged = <String>[];
    List<String> unstaged = <String>[];
    allChanges.forEach((entry) {
      var flags = GitStatusFlags.fromFlags(entry[2]);
      if (flags.isStaged) staged.add(entry[0] ?? entry[1]);
      if (flags.isNew || flags.isDeleted || flags.isModified)
        unstaged.add(entry[0] ?? entry[1]);
    });
    return Padding(
        padding: EdgeInsets.all(5),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // MaterialBanner(content: Text("Staged Changed"), actions: []),
              Padding(
                  padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text('Staged Changes',
                      style: Theme.of(context).textTheme.subtitle1)),
              Expanded(
                  child: Card(
                      child: ListView.builder(
                itemCount: staged.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(staged[index]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {},
                        ),
                      ]));
                },
              ))),
              Padding(
                  padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text('Changes',
                      style: Theme.of(context).textTheme.subtitle1)),
              Expanded(
                  child: Card(
                      child: ListView.builder(
                itemCount: unstaged.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(unstaged[index]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Icon(Icons.undo),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {},
                        ),
                      ]));
                },
              ))),
              Row(
                children: <Widget>[
                  ElevatedButton(child: Text('Commit'), onPressed: () {})
                ],
              )
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Commit $repositoryName'),
        ),
        body: FutureBuilder(
            future: gitStatus,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                return _makeCommitUi(snapshot.data);
              } else {
                return Text('Loading');
              }
            }));
  }
}
