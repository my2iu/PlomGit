import 'package:flutter/material.dart';
import 'package:PlomGit/src/jsgit.dart' show JsForGit;
import 'package:PlomGit/src/repository_view.dart' show RepositoryView;
import 'package:universal_platform/universal_platform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'dart:developer' as developer;

void main() {
  hierarchicalLoggingEnabled = true;
  Logger("plomgit.fs").level = Level.ALL;
  Logger.root.onRecord.listen((record) {
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
      title: 'Flutter Demo',
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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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

  void _setCounter(int val) {
    setState(() {
      _counter = val;
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

  _pressed(BuildContext context) {
    var jsGit = JsForGit(null);
    jsGit
        .clone()
        .then((val) => Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Clone successful'))))
        .catchError((error) => Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ' + error))))
        .whenComplete(() => print('done2'));
  }

  _createLocalRepository(BuildContext context, String name) {
    var repositoryPath;
    if (UniversalPlatform.isAndroid) {
      repositoryPath = getExternalStorageDirectory().then((dir) {
        var uri = dir.uri;
        return uri.replace(path: uri.path + 'repositories/' + name + '/');
      });
    } else {
      repositoryPath = getApplicationDocumentsDirectory().then((dir) {
        var uri = dir.uri;
        return uri.replace(path: uri.path + 'repositories/' + name + '/');
      });
    }
    repositoryPath.then((pathUri) {
      var jsGit = JsForGit.forNewDirectory(pathUri);
      jsGit.init(name).then((val) {
        Navigator.push(
            context,
            MaterialPageRoute<String>(
              builder: (BuildContext context) =>
                  RepositoryView(name, pathUri, jsGit),
            ));
      }).catchError((error) => Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ' + error))));
    });
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
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
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
