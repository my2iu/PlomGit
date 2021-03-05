import 'package:PlomGit/src/util.dart';
import 'package:flutter/material.dart';
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'util.dart';

class CommitPrepareChangesView extends StatelessWidget {
  CommitPrepareChangesView(
      this.repositoryName, this.repositoryUri, this.isMerged);

  final bool isMerged;
  final String repositoryName;
  final Uri repositoryUri;

  @override
  Widget build(BuildContext context) {
    TextTheme appBarTextTheme = Theme.of(context).appBarTheme.textTheme ??
        Theme.of(context).primaryTextTheme;
    return Scaffold(
        appBar: AppBar(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            isMerged ? Text('Commit Merge') : Text('Commit'),
            Text(repositoryName, style: appBarTextTheme.caption)
          ]),
        ),
        body: Builder(
            builder: (BuildContext context) => Column(children: [
                  Expanded(
                    child: _CommitFilesView(repositoryName, repositoryUri),
                  ),
                  Row(
                    children: <Widget>[
                      ElevatedButton(
                          child: Text('Next'),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute<String>(
                                    builder: (BuildContext context) =>
                                        CommitFinalView(
                                            repositoryName,
                                            repositoryUri,
                                            isMerged))).then((result) {
                              if (result != null) {
                                Navigator.pop(context, result);
                              }
                            });
                          })
                    ],
                  )
                ])));
  }
}

class _MessageAndSignatureData {
  String name = "";
  String email = "";
  String message = "";
}

class CommitFinalView extends StatelessWidget {
  CommitFinalView(this.repositoryName, this.repositoryUri, this.isMerged);

  final String repositoryName;
  final Uri repositoryUri;
  String get repositoryDir => repositoryUri.toFilePath();
  final _MessageAndSignatureData msgSig = _MessageAndSignatureData();
  final bool isMerged;

  @override
  Widget build(BuildContext context) {
    TextTheme appBarTextTheme = Theme.of(context).appBarTheme.textTheme ??
        Theme.of(context).primaryTextTheme;

    return Scaffold(
        appBar: AppBar(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            isMerged ? Text('Merge Message') : Text('Commit Message'),
            Text(repositoryName, style: appBarTextTheme.caption)
          ]),
        ),
        body: Builder(
            builder: (BuildContext context) => Column(children: [
                  Expanded(
                      child: _CommitMessageView(
                          repositoryName, repositoryUri, msgSig)),
                  Row(
                    children: <Widget>[
                      ElevatedButton(
                          child: Text('Commit'),
                          onPressed: () {
                            GitIsolate.instance
                                .commit(repositoryDir, msgSig.message,
                                    msgSig.name, msgSig.email)
                                .then((_) {
                              Navigator.pop(context, "Commit successful");
                            }).catchError((error) {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text('Error: ' + error.toString())));
                            });
                          })
                    ],
                  )
                ])));
  }
}

class _CommitFilesView extends StatefulWidget {
  _CommitFilesView(this.repositoryName, this.repositoryUri);

  final String repositoryName;
  final Uri repositoryUri;

  @override
  _CommitFilesViewState createState() =>
      _CommitFilesViewState(repositoryName, repositoryUri);
}

class _CommitFilesViewState extends State<_CommitFilesView> {
  _CommitFilesViewState(this.repositoryName, this.repositoryUri) {
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

  Widget _makeConfirmDialog(String title, String message, String actionMessage,
      [String cancelMessage = "Cancel"]) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text(cancelMessage),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        TextButton(
          child: Text(actionMessage),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  Widget _makeCommitUi(List<dynamic> allChanges) {
    List<String> staged = <String>[];
    List<String> unstaged = <String>[];
    allChanges.forEach((entry) {
      var gitFlags = RawGitStatusFlags.fromStatus(entry[2]);
      if (gitFlags.staged) staged.add(entry[0] ?? entry[1]);
      if (gitFlags.unstaged) unstaged.add(entry[0] ?? entry[1]);
    });
    return Padding(
        padding: EdgeInsets.all(kDefaultPadding),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // MaterialBanner(content: Text("Staged Changed"), actions: []),
              Padding(
                  padding: EdgeInsets.fromLTRB(kDefaultPadding,
                      kDefaultSectionSpacing, kDefaultPadding, kDefaultPadding),
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
                  padding: EdgeInsets.fromLTRB(kDefaultPadding,
                      kDefaultSectionSpacing, kDefaultPadding, kDefaultPadding),
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
                          onPressed: () {
                            showDialog<bool>(
                                    context: context,
                                    builder: (context) => _makeConfirmDialog(
                                        "Revert", "Revert changes?", "Revert"))
                                .then((response) {
                              if (response) {
                                GitIsolate.instance
                                    .revertFile(repositoryDir, unstaged[index])
                                    .then((result) => _refresh())
                                    .catchError((error) {
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                      content:
                                          Text('Error: ' + error.toString())));
                                });
                              }
                            });
                          },
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
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: gitStatus,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return _makeCommitUi(snapshot.data);
          } else {
            return Text('Loading');
          }
        });
  }
}

class _CommitMessageView extends StatefulWidget {
  _CommitMessageView(this.repositoryName, this.repositoryUri, this.msgSig);

  final String repositoryName;
  final Uri repositoryUri;
  final _MessageAndSignatureData msgSig;

  @override
  _CommitMessageViewState createState() =>
      _CommitMessageViewState(repositoryName, repositoryUri, msgSig);
}

class _CommitMessageViewState extends State<_CommitMessageView> {
  _CommitMessageViewState(this.repositoryName, this.repositoryUri, this.msgSig);

  String repositoryName;
  Uri repositoryUri;
  String get repositoryDir => repositoryUri.toFilePath();
  _MessageAndSignatureData msgSig;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(kDefaultPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
            Widget>[
          Expanded(
              child: Card(
                  child: Padding(
                      padding: EdgeInsets.all(kDefaultPadding),
                      child: TextFormField(
                          // controller: TextEditingController(text: message),
                          // minLines: 3,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          initialValue: msgSig.message,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            // border: OutlineInputBorder(),
                            icon: Icon(Icons.notes),
                            // filled: true,
                            labelText: 'Commit message',
                          ),
                          onChanged: (val) =>
                              setState(() => msgSig.message = val))))),
          SizedBox(height: kDefaultPadding),
          Card(
              child: Padding(
                  padding: EdgeInsets.all(kDefaultPadding),
                  child: Column(children: [
                    TextFormField(
                        decoration: InputDecoration(
                          // border: OutlineInputBorder(),
                          icon: Icon(Icons.person),
                          // filled: true,
                          labelText: 'Name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        initialValue: msgSig.name,
                        onChanged: (val) => setState(() => msgSig.name = val)),
                    TextFormField(
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(
                          // border: OutlineInputBorder(),
                          icon: Icon(Icons.email),
                          // filled: true,
                          labelText: 'Email',
                        ),
                        initialValue: msgSig.email,
                        onChanged: (val) => setState(() => msgSig.email = val))
                  ]))),
        ]));
  }
}
