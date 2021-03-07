import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:PlomGit/src/jsgit.dart' show JsForGit;
import 'package:PlomGit/src/repository_view.dart' show RepositoryView;
import 'package:PlomGit/src/util.dart'
    show
        retryWithAskCredentials,
        PlomGitPrefs,
        kDefaultPadding,
        kDefaultSectionSpacing;
import 'package:libgit2/git_isolate.dart' show GitIsolate;
import 'package:universal_platform/universal_platform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart' as log;
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'package:tuple/tuple.dart';

// TODO: Don't allow "/" in repository and remote names since we used that elsewhere
// TODO: Fix-up error checking in modifications to C code
// TODO: Use ffigen to autogenerate C bindings

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
    return MaterialApp(
      title: 'PlomGit',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'PlomGit Repositories'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Future<List<Directory>> dirContents;

  _MyHomePageState() {
    dirContents = _getRepositoryBaseDir().then((uri) => Directory.fromUri(uri)
        .list()
        .where((entry) => entry is Directory)
        .map((entry) => entry as Directory)
        .toList());
  }

  void _setCounter(int val) {
    setState(() {
      _counter = val;
      dirContents = _getRepositoryBaseDir().then((uri) => Directory.fromUri(uri)
          .list()
          .where((entry) => entry is Directory)
          .map((entry) => entry as Directory)
          .toList());
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
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
                      MaterialPageRoute<Tuple4<String, String, String, String>>(
                        builder: (BuildContext context) =>
                            RepositoryLocationAndRemoteDialog(),
                      ),
                    ).then((result) {
                      if (result == null) return;
                      String url = result.item1;
                      String name = result.item2;
                      String user = result.item3;
                      String password = result.item4;
                      _cloneRepository(context, name, url, user, password);
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

  _pressed(BuildContext context) {
    // Libgit2.platformVersion
    //     .then((val) => print(val))
    //     .catchError((err) => print(err.toString()));

    // var jsGit = JsForGit(null);
    // jsGit
    //     .clone()
    //     .then((val) => Scaffold.of(context)
    //         .showSnackBar(SnackBar(content: Text('Clone successful'))))
    //     .catchError((error) => Scaffold.of(context)
    //         .showSnackBar(SnackBar(content: Text('Error: ' + error))))
    //     .whenComplete(() => print('done2'));
  }

  Future<Uri> _getRepositoryBaseDir() {
    var repositoryPath;
    if (UniversalPlatform.isAndroid) {
      repositoryPath = getExternalStorageDirectory().then((dir) {
        var uri = dir.uri;
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
      String user, String password) {
    Future<dynamic> waitWriteCredentials = Future.value(null);
    if (user.isNotEmpty) {
      waitWriteCredentials = waitWriteCredentials.then((_) =>
          PlomGitPrefs.instance.writeEncryptedUser(name, "origin", user));
    }
    if (password.isNotEmpty) {
      waitWriteCredentials = waitWriteCredentials.then((_) => PlomGitPrefs
          .instance
          .writeEncryptedPassword(name, "origin", password));
    }
    waitWriteCredentials.then((_) {
      _getRepositoryDirForName(name).then((pathUri) {
        retryWithAskCredentials(
                name,
                "origin",
                (user, password) => GitIsolate.instance
                    .clone(url, pathUri.toFilePath(), user, password),
                context)
            .then((val) {
          Navigator.push(
              context,
              MaterialPageRoute<String>(
                builder: (BuildContext context) =>
                    RepositoryView(name, pathUri),
              )).then((result) => _refreshRepositories());
        }).catchError((error) {
          _refreshRepositories();
          Scaffold.of(context)
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
        Scaffold.of(context).showSnackBar(
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
    _getRepositoryDirForName(name)
        .then((uri) => Directory.fromUri(uri).delete(recursive: true))
        .then((_) => PlomGitPrefs.instance.eraseRepositoryPreferences(name))
        .then((result) {
      _refreshRepositories();
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text('Repository deleted')));
    });
  }

  // I should create a proper model for storing the list of repositories that
  // can then refresh different views, but I'm too lazy to implement that right now
  void _refreshRepositories() {
    _setCounter(0);
  }

  Widget _buildRepositoryList(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      return Expanded(
          child: ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (itemBuilderContext, index) {
                var name = path.basename(snapshot.data[index].path);
                return ListTile(
                    title: Text(name),
                    trailing: buildRepositoryOptionsPopupButton(name),
                    onTap: () => _showRepository(name, context));
              }));
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
          title: Text(widget.title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Invoke "debug painting" (press "p" in the console, choose the
              // "Toggle Debug Paint" action from the Flutter Inspector in Android
              // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
              // to see the wireframe for each widget.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder(
                    future: dirContents,
                    builder: (futureContext, snapshot) {
                      return _buildRepositoryList(futureContext, snapshot);
                    }),
                Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headline4,
                ),
                ElevatedButton(
                    onPressed: () {
                      _pressed(context);
                    },
                    child: Text('Test')),
                ElevatedButton(
                    onPressed: () {
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
                    },
                    child: Text('Init')),
              ],
            ),
          );
        }),
        floatingActionButton: Builder(
          builder: (BuildContext context) => FloatingActionButton(
            onPressed: () => _newRepositoryPressed(context),
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
        ));
  }
}

class RepositoryLocationDialog extends StatefulWidget {
  @override
  _RepositoryLocationState createState() => _RepositoryLocationState();
}

class _RepositoryLocationState extends State<RepositoryLocationDialog> {
  String repositoryName = "Test";
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Repository Configuration'),
        ),
        body: Builder(builder: (BuildContext context) {
          return Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  initialValue: repositoryName,
                  decoration: InputDecoration(labelText: 'Repository name'),
                  onChanged: (text) {
                    repositoryName = text;
                  },
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, repositoryName);
                    },
                    child: Text('Create')),
              ]));
        }));
  }
}

class RepositoryLocationAndRemoteDialog extends StatelessWidget {
  final RepositoryRemoteInfo remoteInfo = RepositoryRemoteInfo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Repository Configuration'),
        ),
        body: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(children: [
              RemoteConfigurationWidget(remoteInfo),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                        context,
                        Tuple4(remoteInfo.url, remoteInfo.repositoryName,
                            remoteInfo.user, remoteInfo.password));
                  },
                  child: Text('Clone')),
            ])));
  }
}

class RepositoryRemoteInfo {
  String repositoryName = "Test";
  String url = "https://github.com/my2iu/PlomGit.git";
  String user = "";
  String password = "";
}

class RemoteConfigurationWidget extends StatefulWidget {
  RemoteConfigurationWidget(this.remoteInfo);
  final RepositoryRemoteInfo remoteInfo;
  @override
  _RepositoryLocationAndRemoteState createState() =>
      _RepositoryLocationAndRemoteState(remoteInfo);
}

class _RepositoryLocationAndRemoteState
    extends State<RemoteConfigurationWidget> {
  _RepositoryLocationAndRemoteState(this.remoteInfo);

  final _formKey = GlobalKey<FormState>();
  RepositoryRemoteInfo remoteInfo;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(children: [
          Card(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding,
                      kDefaultPadding, kDefaultPadding),
                  child: Column(children: [
                    TextFormField(
                      initialValue: remoteInfo.repositoryName,
                      decoration: InputDecoration(labelText: 'Repository name'),
                      onChanged: (text) => remoteInfo.repositoryName = text,
                    ),
                    TextFormField(
                      initialValue: remoteInfo.url,
                      decoration: InputDecoration(labelText: 'Remote url'),
                      onChanged: (text) => remoteInfo.url = text,
                    ),
                  ]))),
          SizedBox(height: kDefaultPadding),
          Card(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding,
                      kDefaultPadding, kDefaultPadding),
                  child: Column(children: [
                    TextFormField(
                      initialValue: remoteInfo.user,
                      decoration: InputDecoration(
                        icon: Icon(Icons.account_circle),
                        labelText: 'User',
                      ),
                      onChanged: (text) => remoteInfo.user = text,
                    ),
                    TextFormField(
                      initialValue: remoteInfo.password,
                      obscureText: true,
                      decoration: InputDecoration(
                        icon: Icon(Icons.lock),
                        labelText: 'Password or token',
                      ),
                      onChanged: (text) => remoteInfo.password = text,
                    ),
                  ]))),
        ]));
  }
}
