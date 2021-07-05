import 'package:flutter/material.dart';
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'util.dart'
    show
        PlomGitPrefs,
        RepositoryOrRemoteNameTextFormField,
        RemoteUserTextFormField,
        RemotePasswordTextFormField,
        RemoteCredentialsType,
        RemoteCredentialsInfo,
        AccountCredentialDescription,
        kDefaultPadding,
        kDefaultSectionSpacing,
        showProgressWhileWaitingFor,
        DEFAULT_REPO_NAME,
        DEFAULT_REPO_URL;

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
      MaterialPageRoute<RepositoryRemoteInfo>(
        builder: (BuildContext context) =>
            NewRemoteDialog(RepositoryRemoteInfo()),
      ),
    ).then((result) {
      if (result == null) return;
      String url = result.url;
      String name = result.name;

      showProgressWhileWaitingFor(context,
              GitIsolate.instance.createRemote(repositoryDir, name, url))
          .then((_) => PlomGitPrefs.instance.writeRemoteCredentialsInfo(
              repositoryName, name, result.credentialInfo))
          .then((_) {
        if (result.credentialInfo.type == RemoteCredentialsType.userPassword)
          return PlomGitPrefs.instance.writeEncryptedUserPassword(
              name, name, result.user, result.password);
        else
          return PlomGitPrefs.instance
              .writeEncryptedUserPassword(repositoryName, name, null, null);
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
  NewRemoteDialog(this.remoteInfo);
  final RepositoryRemoteInfo remoteInfo;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('New Remote'),
        ),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(children: [
              Form(
                  key: _formKey,
                  child: RemoteConfigurationWidget(
                    remoteInfo,
                    forRemote: true,
                    autofocus: true,
                  )),
              SizedBox(height: kDefaultSectionSpacing),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.pop(context, remoteInfo);
                    }
                  },
                  child: Text('Create')),
            ])));
  }
}

class RepositoryRemoteInfo {
  String name = DEFAULT_REPO_NAME;
  String url = DEFAULT_REPO_URL;
  String user = "";
  String password = "";
  RemoteCredentialsInfo credentialInfo = RemoteCredentialsInfo();
}

class RemoteConfigurationWidget extends StatelessWidget {
  RemoteConfigurationWidget(this.remoteInfo,
      {this.forRemote = false, this.autofocus = false});
  final RepositoryRemoteInfo remoteInfo;
  final bool forRemote;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
          child: Padding(
              padding: EdgeInsets.all(kDefaultPadding),
              child: Column(children: [
                RepositoryOrRemoteNameTextFormField(
                    autofocus: autofocus,
                    initialValue: remoteInfo.name,
                    onSaved: (text) => remoteInfo.name = text!,
                    forRemote: forRemote),
                TextFormField(
                  initialValue: remoteInfo.url,
                  decoration: InputDecoration(labelText: 'Remote url'),
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  onSaved: (text) => remoteInfo.url = text!,
                ),
              ]))),
      SizedBox(height: kDefaultSectionSpacing),
      RemoteCredentialsWidget(remoteInfo),
    ]);
  }
}

class RemoteCredentialsWidget extends StatefulWidget {
  const RemoteCredentialsWidget(this.remoteInfo, {Key? key}) : super(key: key);

  final RepositoryRemoteInfo remoteInfo;

  @override
  State<RemoteCredentialsWidget> createState() =>
      _RemoteCredentialsWidgetState(remoteInfo);
}

class _RemoteCredentialsWidgetState extends State<RemoteCredentialsWidget> {
  _RemoteCredentialsWidgetState(this.remoteInfo);
  final RepositoryRemoteInfo remoteInfo;

  Widget buildUserPasswordCard(BuildContext context) {
    return Card(
        child: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(children: [
              RemoteUserTextFormField(
                initialValue: remoteInfo.user,
                onSaved: (text) => remoteInfo.user = text!,
              ),
              RemotePasswordTextFormField(
                initialValue: remoteInfo.password,
                onSaved: (text) => remoteInfo.password = text!,
              ),
            ])));
  }

  Widget buildSavedCredentialsCard(BuildContext context) {
    return Card(
        child: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: FutureBuilder<List<AccountCredentialDescription>>(
                future: PlomGitPrefs.instance.readAccountCredentialsList(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<AccountCredentialDescription>>
                        snapshot) {
                  if (snapshot.hasData) {
                    int? idx = snapshot.data?.indexWhere((cred) =>
                        cred.id ==
                        remoteInfo.credentialInfo.savedCredentialsId);
                    AccountCredentialDescription? selectedCredential =
                        idx == null || idx < 0 ? null : snapshot.data![idx];
                    // Force a selection if there are options available and none
                    // are selected
                    if (selectedCredential == null &&
                        snapshot.data != null &&
                        snapshot.data!.isNotEmpty) {
                      selectedCredential = snapshot.data!.first;
                      remoteInfo.credentialInfo.savedCredentialsId =
                          selectedCredential.id;
                    }
                    return DropdownButton<AccountCredentialDescription>(
                      isExpanded: true,
                      value: selectedCredential,
                      onChanged: (AccountCredentialDescription? newValue) {
                        setState(() {
                          remoteInfo.credentialInfo.savedCredentialsId =
                              newValue!.id;
                        });
                      },
                      items: snapshot.data
                          ?.map((credential) => DropdownMenuItem(
                              value: credential, child: Text(credential.name)))
                          .toList(),
                    );
                  } else {
                    return Text('Loading');
                  }
                })));
  }

  @override
  Widget build(BuildContext context) {
    Widget credentialsWidget;
    switch (remoteInfo.credentialInfo.type) {
      case RemoteCredentialsType.userPassword:
        credentialsWidget = buildUserPasswordCard(context);
        break;
      case RemoteCredentialsType.savedCredentials:
        credentialsWidget = buildSavedCredentialsCard(context);
        break;
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButton<RemoteCredentialsType>(
          value: remoteInfo.credentialInfo.type,
          onChanged: (RemoteCredentialsType? newValue) {
            setState(() {
              remoteInfo.credentialInfo.type = newValue!;
            });
          },
          items: [
            DropdownMenuItem<RemoteCredentialsType>(
              value: RemoteCredentialsType.userPassword,
              child: Text("Optional Password Login"),
            ),
            DropdownMenuItem<RemoteCredentialsType>(
              value: RemoteCredentialsType.savedCredentials,
              child: Text("Saved Credentials"),
            ),
          ]),
      credentialsWidget,
    ]);
  }
}
