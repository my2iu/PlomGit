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

  @override
  Widget build(BuildContext context) {
    // TextTheme appBarTextTheme = Theme.of(context).appBarTheme.textTheme ??
    //     Theme.of(context).primaryTextTheme;
    // if (_path.isNotEmpty) {
    //   title = Column(children: [
    //     Text(repositoryName),
    //     Text(_path, style: appBarTextTheme.caption)
    //   ]);
    // } else {
    //   title = Text(repositoryName);
    // }
    List<String> staged = <String>['hello'];
    List<String> unstaged = <String>[
      'hello',
      'one',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'one',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'one',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ];
    return Scaffold(
        appBar: AppBar(
          title: Text('Commit $repositoryName'),
          // actions: <Widget>[buildActionsPopupMenu(context)]
        ),
        body: FutureBuilder(
            future: gitStatus,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                return Padding(
                    padding: EdgeInsets.all(5),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // MaterialBanner(content: Text("Staged Changed"), actions: []),
                          Padding(
                              padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
                              child: Text('Staged Changes',
                                  style:
                                      Theme.of(context).textTheme.subtitle1)),
                          Expanded(
                              child: Card(
                                  child: ListView.builder(
                            itemCount: staged.length,
                            itemBuilder: (context, index) {
                              return ListTile(title: Text(staged[index]));
                            },
                          ))),
                          Padding(
                              padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
                              child: Text('Changes',
                                  style:
                                      Theme.of(context).textTheme.subtitle1)),
                          Expanded(
                              child: Card(
                                  child: ListView.builder(
                            itemCount: unstaged.length,
                            itemBuilder: (context, index) {
                              return ListTile(title: Text(unstaged[index]));
                            },
                          ))),
                          Row(
                            children: <Widget>[
                              ElevatedButton(
                                  child: Text('Commit'), onPressed: () {})
                            ],
                          )
                        ]));
              } else {
                return Text('Loading');
              }
            }));
  }
}
