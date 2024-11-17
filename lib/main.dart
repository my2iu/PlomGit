import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plomgit/src/repository_view.dart' show RepositoryView;
import 'package:plomgit/src/remote_view.dart'
    show RemoteConfigurationWidget, RepositoryRemoteInfo;
import 'package:plomgit/src/account_credential_view.dart'
    show AccountCredentialListView;
import 'package:plomgit/src/util.dart'
    show
        RepositoryNameTextFormField,
        RemoteCredentialsInfo,
        RepositoryRemoteLoginInfo,
        PlomGitPrefs,
        kDefaultPadding,
        kDefaultSectionSpacing,
        DEFAULT_REPO_NAME,
        retryWithAskCredentials,
        showProgressWhileWaitingFor,
        showConfirmDialog,
        writeLoginInfo,
        TextAndIcon;
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'package:universal_platform/universal_platform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart' as log;
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

// TODO: Fix-up error checking in modifications to C code
// TODO: Use ffigen to autogenerate C bindings
// TODO: switch upstream of current branch
// TODO: abort a merge
// TODO: on a merge, replace files with your/their version
// TODO: checkout branches
// TODO: file status icons in commit view
// TODO: change user agent on android http client

void main() {
  log.hierarchicalLoggingEnabled = true;
  log.Logger("plomgit.fs").level = log.Level.ALL;
  log.Logger("plomgit.http").level = log.Level.ALL;
  log.Logger("plomgit.gitisolate").level = log.Level.ALL;
  log.Logger.root.onRecord.listen((record) {
    developer.log('${record.loggerName}: ${record.message}',
        level: record.level.value, name: record.loggerName);
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var theme = ThemeData(
      // This is the theme of your application.
      //
      // Try running your application with "flutter run". You'll see the
      // application has a blue toolbar. Then, without quitting the app, try
      // changing the primarySwatch below to Colors.green and then invoke
      // "hot reload" (press "r" in the console where you ran "flutter run",
      // or simply save your changes to "hot reload" in a Flutter IDE).
      // Notice that the counter didn't reset back to zero; the application
      // is not restarted.
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
      useMaterial3: true,
      // This makes the visual density adapt to the platform that you run
      // the app on. For desktop platforms, the controls will be smaller and
      // closer together (more dense) than on mobile platforms.
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
    var darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      visualDensity: VisualDensity.adaptivePlatformDensity,
//      colorScheme: ColorScheme.dark(
//        surface: Colors.blueGrey.shade900,
        //background: const Color(0xff121212),
//        primary: Colors.blueGrey.shade300,
//        secondary: Colors.blueGrey.shade700,
//        onSecondary: Colors.white,
//      ),
    );
    return MaterialApp(
      title: 'PlomGit',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: MyHomePage(title: 'PlomGit Repositories'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Directory>> dirContents;

  _MyHomePageState() {
    dirContents = _getRepositoryBaseDir()
        .then((uri) => Directory.fromUri(uri)
            .list()
            .where((entry) => entry is Directory)
            .map((entry) => entry as Directory)
            .toList())
        .catchError((err) => <Directory>[]);
  }

  void _newRepositoryPressed(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return SimpleDialog(title: Text('New repository'), children: <Widget>[
            SimpleDialogOption(
                child: Text('Clone repository'),
                onPressed: () {
                  Navigator.pop(dialogContext, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<RepositoryRemoteInfo>(
                        builder: (BuildContext context) =>
                            RepositoryLocationAndRemoteDialog(),
                      ),
                    ).then((result) {
                      if (result == null) return;
                      String url = result.url;
                      String name = result.name;
                      _cloneRepository(
                          context,
                          name,
                          url,
                          result.login.credentialInfo,
                          result.login.user,
                          result.login.password);
                    });
                  });
                }),
            SimpleDialogOption(
                child: Text('Create local repository'),
                onPressed: () {
                  Navigator.pop(dialogContext, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<String>(
                        builder: (BuildContext context) =>
                            RepositoryLocationDialog(),
                      ),
                    ).then((result) {
                      if (result == null) return;
                      _createLocalRepository(context, result);
                    });
                  });
                }),
          ]);
        }).then((fn) {
      if (fn != null) fn();
    });
  }

  Future<Uri> _getRepositoryBaseDir() {
    var repositoryPath;
    if (UniversalPlatform.isAndroid) {
      repositoryPath = getExternalStorageDirectory().then((dir) {
        var uri = dir!.uri;
        return uri.replace(path: uri.path + 'repositories/');
      });
    } else {
      // On iOS, we're lazy and we'll just dump things directly in the documents
      // directory so that we can let iOS automatically share all the files
      // without us needing to explicitly create a file provider.
      repositoryPath = getApplicationDocumentsDirectory().then((dir) {
        var uri = dir.uri;
        return uri.replace(path: uri.path);
      });
    }
    return repositoryPath;
  }

  Future<Uri> _getRepositoryDirForName(String name) {
    var repositoryPath = _getRepositoryBaseDir();
    return repositoryPath
        .then((uri) => uri.replace(path: uri.path + name + '/'));
  }

  void _cloneRepository(BuildContext context, String name, String url,
      RemoteCredentialsInfo credentialsInfo, String user, String password) {
    RepositoryRemoteLoginInfo login = RepositoryRemoteLoginInfo();
    login.credentialInfo = credentialsInfo;
    login.user = user;
    login.password = password;
    writeLoginInfo(name, "origin", login).then((_) {
      _getRepositoryDirForName(name).then((pathUri) {
        showProgressWhileWaitingFor(
                context,
                retryWithAskCredentials(
                    name,
                    "origin",
                    (user, password) => GitIsolate.instance
                        .clone(url, pathUri.toFilePath(), user, password),
                    context))
            .then((val) {
          Navigator.push(
              context,
              MaterialPageRoute<String>(
                builder: (BuildContext context) =>
                    RepositoryView(name, pathUri),
              )).then((result) => _refreshRepositories());
        }).catchError((error) {
          _refreshRepositories();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $error')));
        });
      });
    });
  }

  void _createLocalRepository(BuildContext context, String name) {
    _getRepositoryDirForName(name).then((pathUri) {
      GitIsolate.instance.initRepository(pathUri.toFilePath()).then((val) {
        // _refreshRepositories();
        Navigator.push(
            context,
            MaterialPageRoute<String>(
              builder: (BuildContext context) => RepositoryView(name, pathUri),
            )).then((result) => _refreshRepositories());
      }).catchError((error) {
        _refreshRepositories();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ' + error.toString())));
      });
    });
  }

  void _showRepository(String name, BuildContext context) {
    _getRepositoryDirForName(name).then((uri) {
      Navigator.push(
              context,
              MaterialPageRoute<String>(
                  builder: (BuildContext context) => RepositoryView(name, uri)))
          .then((result) => _refreshRepositories());
    });
  }

  void _deleteRepository(String name, BuildContext context) {
    showConfirmDialog(context, "Delete", "Delete repository?", "Delete")
        .then((response) {
      if (response ?? false) {
        _getRepositoryDirForName(name)
            .then((uri) => Directory.fromUri(uri).delete(recursive: true))
            .then((_) => PlomGitPrefs.instance.eraseRepositoryPreferences(name))
            .then((result) {
          _refreshRepositories();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Repository deleted')));
        });
      }
    });
  }

  // I should create a proper model for storing the list of repositories that
  // can then refresh different views, but I'm too lazy to implement that right now
  void _refreshRepositories() {
    setState(() {
      dirContents = _getRepositoryBaseDir()
          .then((uri) => Directory.fromUri(uri)
              .list()
              .where((entry) => entry is Directory)
              .map((entry) => entry as Directory)
              .toList())
          .catchError((err) => <Directory>[]);
    });
  }

  Widget _buildRepositoryList(
      BuildContext context, AsyncSnapshot<List<Directory>> snapshot) {
    if (snapshot.hasData) {
      if (snapshot.data!.length == 0) {
        return Center(child: Text("You haven't created any repositories yet"));
      } else {
        return Expanded(
            child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (itemBuilderContext, index) {
                  var name = path.basename(snapshot.data![index].path);
                  return ListTile(
                      title: Text(name),
                      trailing: buildRepositoryOptionsPopupButton(name),
                      onTap: () => _showRepository(name, context));
                }));
      }
    } else {
      return SizedBox.shrink();
    }
  }

  PopupMenuButton buildRepositoryOptionsPopupButton(String name) {
    return PopupMenuButton(
        onSelected: (fn) => fn(),
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              PopupMenuItem(
                  value: () => _deleteRepository(name, context),
                  child: Text('Delete')),
            ]);
  }

  PopupMenuButton buildActionsPopupMenu(BuildContext ctx) {
    return PopupMenuButton(
        onSelected: (dynamic fn) => fn(),
        itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                  value: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute<String>(
                            builder: (BuildContext context) =>
                                AccountCredentialListView()));
                  },
                  child: TextAndIcon(
                      Text("Accounts..."),
                      Icon(Icons.manage_accounts,
                          color: Theme.of(context).iconTheme.color))),
            ]);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title!),
        actions: [buildActionsPopupMenu(context)],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FutureBuilder<List<Directory>>(
              future: dirContents,
              builder: (futureContext, snapshot) {
                return _buildRepositoryList(futureContext, snapshot);
              }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newRepositoryPressed(context),
        tooltip: 'New repository',
        child: Icon(Icons.add),
      ),
    );
  }
}

class RepositoryLocationDialog extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    String repositoryName = DEFAULT_REPO_NAME;
    return Scaffold(
        appBar: AppBar(
          title: Text('Repository Configuration'),
        ),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Form(
                key: _formKey,
                child: Column(children: [
                  Card(
                      child: Padding(
                          padding: EdgeInsets.all(kDefaultPadding),
                          child: Column(children: [
                            RepositoryNameTextFormField(
                                autofocus: true,
                                initialValue: repositoryName,
                                onSaved: (text) => repositoryName = text!),
                          ]))),
                  SizedBox(height: kDefaultSectionSpacing),
                  ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Navigator.pop(context, repositoryName);
                        }
                      },
                      child: Text('Create')),
                ]))));
  }
}

class RepositoryLocationAndRemoteDialog extends StatelessWidget {
  final RepositoryRemoteInfo remoteInfo = RepositoryRemoteInfo();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Repository Configuration'),
        ),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(children: [
              Form(
                  key: _formKey,
                  child: RemoteConfigurationWidget(
                    remoteInfo,
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
                  child: Text('Clone')),
            ])));
  }
}
