import 'package:flutter/material.dart';
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'util.dart'
    show
        RepositoryOrRemoteNameTextFormField,
        RemoteCredentialsWidget,
        RepositoryRemoteLoginInfo,
        writeLoginInfo,
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
          .then((_) => writeLoginInfo(repositoryName, name, result.login))
          .then((_) {
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
    TextTheme appBarTextTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text("Remotes"),
          Text(repositoryName, style: appBarTextTheme.bodySmall)
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
  RepositoryRemoteLoginInfo login = RepositoryRemoteLoginInfo();
}

class RemoteConfigurationWidget extends StatelessWidget {
  const RemoteConfigurationWidget(this.remoteInfo,
      {super.key,
      this.forRemote = false,
      this.autofocus = false,
      this.onUrlChange});
  final RepositoryRemoteInfo remoteInfo;
  final bool forRemote;
  final bool autofocus;
  final void Function(String url)? onUrlChange;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
          child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(children: [
                RepositoryOrRemoteNameTextFormField(
                    autofocus: autofocus,
                    initialValue: remoteInfo.name,
                    onSaved: (text) => remoteInfo.name = text!,
                    forRemote: forRemote),
                TextFormField(
                  initialValue: remoteInfo.url,
                  decoration: const InputDecoration(labelText: 'Remote url'),
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  onSaved: (text) => remoteInfo.url = text!,
                  onChanged: onUrlChange,
                ),
              ]))),
      const SizedBox(height: kDefaultSectionSpacing),
      RemoteCredentialsWidget(remoteInfo.login),
    ]);
  }
}
