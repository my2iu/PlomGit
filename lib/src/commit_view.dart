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

  void _refresh() {
    setState(() {
      gitStatus = GitIsolate.instance.status(repositoryDir);
    });
  }

  Widget _makeCommitUi(List<dynamic> allChanges) {
    List<String> staged = <String>[];
    List<String> unstaged = <String>[];
    allChanges.forEach((entry) {
      var gitFlags = entry[2];
      if ((gitFlags & (1 | 2 | 4 | 8 | 16)) != 0)
        staged.add(entry[0] ?? entry[1]);
      if ((gitFlags & (128 | 256 | 512 | 1024 | 2048)) != 0)
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
                          tooltip: "Remove",
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            GitIsolate.instance
                                .removeFromIndex(repositoryDir, staged[index])
                                .then((result) => _refresh())
                                .catchError((error) {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text('Error: ' + error.toString())));
                            });
                          },
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
                          tooltip: "Revert",
                          icon: Icon(Icons.undo),
                          onPressed: () {},
                        ),
                        IconButton(
                          tooltip: "Add",
                          icon: Icon(Icons.add),
                          onPressed: () {
                            GitIsolate.instance
                                .addToIndex(repositoryDir, unstaged[index])
                                .then((result) => _refresh())
                                .catchError((error) {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text('Error: ' + error.toString())));
                            });
                          },
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
