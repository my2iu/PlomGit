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
        body: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(children: [
              Expanded(
                child: _CommitFilesView(repositoryName, repositoryUri),
              ),
              SizedBox(height: kDefaultSectionSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
  CommitFinalView(this.repositoryName, this.repositoryUri, this.isMerge) {
    msgSig = _MessageAndSignatureData();
    initialAuthorName =
        PlomGitPrefs.instance.readSuggestedAuthorName(repositoryName);
    initialAuthorEmail =
        PlomGitPrefs.instance.readSuggestedAuthorEmail(repositoryName);
    initialCommitMsg =
        PlomGitPrefs.instance.readRepositoryCommitMessage(repositoryName);
    loadInitialCommitInfo =
        Future.wait([initialCommitMsg, initialAuthorName, initialAuthorEmail]);
  }

  final String repositoryName;
  final Uri repositoryUri;
  String get repositoryDir => repositoryUri.toFilePath();
  late final _MessageAndSignatureData msgSig;
  final bool isMerge;
  final _formKey = GlobalKey<FormState>();
  late final Future<String> initialAuthorName;
  late final Future<String> initialAuthorEmail;
  late final Future<String> initialCommitMsg;
  late final Future<List<String>> loadInitialCommitInfo;

  void doCommit(context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      GitIsolate.instance
          .commit(repositoryDir, msgSig.message, msgSig.name, msgSig.email)
          .then((_) {
        saveCommitInfo(true);
        Navigator.pop(context, "Commit successful");
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ' + error.toString())));
      });
    }
  }

  void saveCommitInfo(bool isCommit) {
    if (isCommit) {
      PlomGitPrefs.instance.writeRepositoryCommitMessage(repositoryName, "");
    } else {
      _formKey.currentState!.save();
      PlomGitPrefs.instance
          .writeRepositoryCommitMessage(repositoryName, msgSig.message);
    }
    loadInitialCommitInfo.then((info) {
      if (msgSig.email != info[2] || msgSig.name != info[1] || isCommit) {
        PlomGitPrefs.instance
            .writeLastAuthor(repositoryName, msgSig.name, msgSig.email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    TextTheme appBarTextTheme = Theme.of(context).appBarTheme.textTheme ??
        Theme.of(context).primaryTextTheme;

    return Scaffold(
        appBar: AppBar(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            isMerge ? Text('Merge Message') : Text('Commit Message'),
            Text(repositoryName, style: appBarTextTheme.caption)
          ]),
        ),
        body: Form(
          key: _formKey,
          onWillPop: () {
            saveCommitInfo(false);
            return Future.value(true);
          },
          child: Padding(
              padding: EdgeInsets.all(kDefaultPadding),
              child: Column(children: [
                Expanded(
                  child: FutureBuilder<List<String>>(
                      future: loadInitialCommitInfo,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          msgSig.message = snapshot.data![0];
                          msgSig.name = snapshot.data![1];
                          msgSig.email = snapshot.data![2];
                          return _CommitMessageView(msgSig, autofocus: true);
                        } else {
                          return Text('Loading');
                        }
                      }),
                ),
                SizedBox(height: kDefaultSectionSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                        child: Text('Commit'),
                        onPressed: () {
                          doCommit(context);
                        })
                  ],
                )
              ])),
        ));
  }
}

class _ChangedFileForStaging {
  final String name;
  final RawGitStatusFlags flags;
  const _ChangedFileForStaging(this.name, this.flags);
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
  late Future<dynamic> gitStatus;

  void _refresh() {
    setState(() {
      gitStatus = GitIsolate.instance.status(repositoryDir);
    });
  }

  Widget _makeCommitUi(List<dynamic> allChanges) {
    List<_ChangedFileForStaging> staged = <_ChangedFileForStaging>[];
    List<_ChangedFileForStaging> unstaged = <_ChangedFileForStaging>[];
    allChanges.forEach((entry) {
      var gitFlags = RawGitStatusFlags.fromStatus(entry[2]);
      if (gitFlags.staged) staged.add(_ChangedFileForStaging(entry[0] ?? entry[1], gitFlags));
      if (gitFlags.unstaged) unstaged.add(_ChangedFileForStaging(entry[0] ?? entry[1], gitFlags));
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
        Widget>[
      // MaterialBanner(content: Text("Staged Changed"), actions: []),
      Padding(
          padding: EdgeInsets.fromLTRB(kDefaultPadding, kDefaultSectionSpacing,
              kDefaultPadding, kDefaultPadding),
          child: Text('Staged Changes',
              style: Theme.of(context).textTheme.subtitle1)),
      Expanded(
          child: Card(
              child: ListView.builder(
        itemCount: staged.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(staged[index].name),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: "Remove",
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    GitIsolate.instance
                        .removeFromIndex(repositoryDir, staged[index].name)
                        .then((result) => _refresh())
                        .catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: ' + error.toString())));
                    });
                  },
                ),
              ]));
        },
      ))),
      Padding(
          padding: EdgeInsets.fromLTRB(kDefaultPadding, kDefaultSectionSpacing,
              kDefaultPadding, kDefaultPadding),
          child: Text('Changes', style: Theme.of(context).textTheme.subtitle1)),
      Expanded(
          child: Card(
              child: ListView.builder(
        itemCount: unstaged.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(unstaged[index].name),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: "Revert",
                  icon: Icon(Icons.undo),
                  onPressed: () {
                    showConfirmDialog(
                            context, "Revert", "Revert changes?", "Revert")
                        .then((response) {
                      if (response ?? false) {
                        GitIsolate.instance
                            .revertFile(repositoryDir, unstaged[index].name)
                            .then((result) => _refresh())
                            .catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error: ' + error.toString())));
                        });
                      }
                    });
                  },
                ),
                IconButton(
                  tooltip: "Add",
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (!unstaged[index].flags.workTreeDeleted) {
                      GitIsolate.instance
                          .addToIndex(repositoryDir, unstaged[index].name)
                          .then((result) => _refresh())
                          .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: ' + error.toString())));
                      });
                    } else {
                      GitIsolate.instance
                          .removeFromIndex(repositoryDir, unstaged[index].name)
                          .then((result) => _refresh())
                          .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: ' + error.toString())));
                      });
                    }
                  },
                ),
              ]));
        },
      ))),
    ]);
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

class _CommitMessageView extends StatelessWidget {
  _CommitMessageView(this.msgSig, {this.autofocus = false});

  final _MessageAndSignatureData msgSig;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _CommitMessageCard(
              autofocus: autofocus,
              initialValue: msgSig.message,
              onSaved: (val) => msgSig.message = val!,
            ),
          ),
          SizedBox(height: kDefaultSectionSpacing),
          _CommitAuthorCard(
            initialName: msgSig.name,
            initialEmail: msgSig.email,
            onNameSaved: (val) => msgSig.name = val!,
            onEmailSaved: (val) => msgSig.email = val!,
          ),
        ]);
  }
}

class _CommitMessageCard extends StatelessWidget {
  _CommitMessageCard({this.initialValue, this.onSaved, this.autofocus = false});
  final String? initialValue;
  final Function(String?)? onSaved;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: TextFormField(
                // controller: TextEditingController(text: message),
                // minLines: 3,
                autofocus: autofocus,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                initialValue: initialValue,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  // border: OutlineInputBorder(),
                  icon: Icon(Icons.notes),
                  // filled: true,
                  labelText: 'Commit message',
                ),
                onSaved: onSaved)));
  }
}

class _CommitAuthorCard extends StatelessWidget {
  _CommitAuthorCard(
      {this.initialName,
      this.initialEmail,
      this.onNameSaved,
      this.onEmailSaved});
  final String? initialName;
  final String? initialEmail;
  final Function(String?)? onNameSaved;
  final Function(String?)? onEmailSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                initialValue: initialName,
                onSaved: onNameSaved,
              ),
              TextFormField(
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    // border: OutlineInputBorder(),
                    icon: Icon(Icons.email),
                    // filled: true,
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  initialValue: initialEmail,
                  onSaved: onEmailSaved)
            ])));
  }
}
