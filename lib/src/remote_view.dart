import 'package:flutter/material.dart';
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'util.dart'
    show
        PlomGitPrefs,
        RepositoryOrRemoteNameTextFormField,
        RemoteUserTextFormField,
        RemotePasswordTextFormField,
        kDefaultPadding,
        kDefaultSectionSpacing,
        showProgressWhileWaitingFor;
import 'package:tuple/tuple.dart';

class RemoteListView extends StatefulWidget {
  RemoteListView(this.repositoryName, this.repositoryUri);
  final String repositoryName;
  final Uri repositoryUri;

  @override
  _RemoteListViewState createState() =>
      _RemoteListViewState(repositoryName, repositoryUri);
}

class _RemoteListViewState extends State<RemoteListView> {
  _RemoteListViewState(this.repositoryName, this.repositoryUri) {
    remotes = GitIsolate.instance.listRemotes(repositoryDir);
  }
  final String repositoryName;
  final Uri repositoryUri;

  String get repositoryDir => repositoryUri.toFilePath();
  late Future<List<String>> remotes;

  ListTile _makeRemoteListTile(BuildContext context, String remoteName) {
    return ListTile(
      title: Text(remoteName),
      trailing: buildRemoteOptionsPopupButton(remoteName),
    );
  }

  void _refresh() {
    setState(() {
      remotes = GitIsolate.instance.listRemotes(repositoryDir);
    });
  }

  PopupMenuButton buildRemoteOptionsPopupButton(String name) {
    return PopupMenuButton(
        onSelected: (fn) => fn(),
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              PopupMenuItem(
                  value: () => GitIsolate.instance
                          .deleteRemote(repositoryDir, name)
                          .then((_) => _refresh())
                          .catchError((error) {
                        _refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')));
                      }),
                  child: Text('Delete')),
            ]);
  }

  void _newRemotePressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<Tuple4<String, String, String, String>>(
        builder: (BuildContext context) => NewRemoteDialog(),
      ),
    ).then((result) {
      if (result == null) return;
      String url = result.item1;
      String name = result.item2;
      String user = result.item3;
      String password = result.item4;
      Future<dynamic> waitWriteCredentials = Future.value(null);

      showProgressWhileWaitingFor(context,
              GitIsolate.instance.createRemote(repositoryDir, name, url))
          .then((_) {
        if (user.isNotEmpty) {
          return PlomGitPrefs.instance.writeEncryptedUser(name, name, user);
        } else {
          return Future.value();
        }
      }).then((_) {
        if (password.isNotEmpty) {
          waitWriteCredentials = waitWriteCredentials.then((_) => PlomGitPrefs
              .instance
              .writeEncryptedPassword(name, name, password));
        } else {
          return Future.value();
        }
      }).then((_) {
        _refresh();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Remote created')));
      }).catchError((error) {
        _refresh();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $error')));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    TextTheme appBarTextTheme = Theme.of(context).appBarTheme.textTheme ??
        Theme.of(context).primaryTextTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Remotes"),
          Text(repositoryName, style: appBarTextTheme.caption)
        ]),
      ),
      body: FutureBuilder<List<String>>(
          future: remotes,
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) =>
                      _makeRemoteListTile(context, snapshot.data![index]));
            } else {
              return Text('Loading');
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newRemotePressed(context),
        tooltip: 'New remote',
        child: Icon(Icons.add),
      ),
    );
  }
}

class NewRemoteDialog extends StatelessWidget {
  final RepositoryRemoteInfo remoteInfo = RepositoryRemoteInfo();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('New Remote'),
        ),
        body: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(children: [
              Form(
                  key: _formKey,
                  child:
                      RemoteConfigurationWidget(remoteInfo, forRemote: true)),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.pop(
                          context,
                          Tuple4(remoteInfo.url, remoteInfo.name,
                              remoteInfo.user, remoteInfo.password));
                    }
                  },
                  child: Text('Create')),
            ])));
  }
}

class RepositoryRemoteInfo {
  String name = "Test";
  String url = "https://github.com/my2iu/PlomGit.git";
  String user = "";
  String password = "";
}

class RemoteConfigurationWidget extends StatelessWidget {
  RemoteConfigurationWidget(this.remoteInfo, {this.forRemote = false});
  final RepositoryRemoteInfo remoteInfo;
  final bool forRemote;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
          child: Padding(
              padding: EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding,
                  kDefaultPadding, kDefaultPadding),
              child: Column(children: [
                RepositoryOrRemoteNameTextFormField(
                    initialValue: remoteInfo.name,
                    onSaved: (text) => remoteInfo.name = text!,
                    forRemote: forRemote),
                TextFormField(
                  initialValue: remoteInfo.url,
                  decoration: InputDecoration(labelText: 'Remote url'),
                  onSaved: (text) => remoteInfo.url = text!,
                ),
              ]))),
      SizedBox(height: kDefaultSectionSpacing),
      Card(
          child: Padding(
              padding: EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding,
                  kDefaultPadding, kDefaultPadding),
              child: Column(children: [
                RemoteUserTextFormField(
                  initialValue: remoteInfo.user,
                  onSaved: (text) => remoteInfo.user = text!,
                ),
                RemotePasswordTextFormField(
                  initialValue: remoteInfo.password,
                  onSaved: (text) => remoteInfo.password = text!,
                ),
              ]))),
    ]);
  }
}
