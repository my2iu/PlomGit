import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libgit2/libgit2.dart' show Libgit2Exception;
import 'package:tuple/tuple.dart';

class TextAndIcon extends StatelessWidget {
  TextAndIcon(this.text, [this.icon]);
  final Widget text;
  final Widget icon;
  @override
  Widget build(BuildContext context) {
    var iconWidget = icon;
    if (icon == null) iconWidget = Icon(null);
    return Row(
        children: <Widget>[iconWidget, SizedBox(width: kDefaultPadding), text]);
  }
}

class RepositoryNameTextFormField extends StatelessWidget {
  RepositoryNameTextFormField({this.initialValue, this.onSaved});
  final String initialValue;
  final Function(String) onSaved;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: 'Repository name'),
      onSaved: onSaved,
      validator: (text) {
        if (text.isEmpty) return "Please enter a name";
        if (text.contains("/")) return "The name should not use the / symbol";
        if (text.contains("\\")) return "The name should not use the \\ symbol";
        return null;
      },
    );
  }
}

class RemoteUserTextFormField extends StatelessWidget {
  RemoteUserTextFormField({this.initialValue, this.onSaved});
  final String initialValue;
  final Function(String) onSaved;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        icon: Icon(Icons.account_circle),
        labelText: 'User',
      ),
      onSaved: onSaved,
    );
  }
}

class RemotePasswordTextFormField extends StatelessWidget {
  RemotePasswordTextFormField({this.initialValue, this.onSaved});
  final String initialValue;
  final Function(String) onSaved;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      obscureText: true,
      decoration: InputDecoration(
        icon: Icon(Icons.lock),
        labelText: 'Password or token',
      ),
      onSaved: onSaved,
    );
  }
}

class CheckboxFormField extends StatelessWidget {
  CheckboxFormField(
      {this.initialValue = false, this.message, this.validator, this.onSaved});
  final bool initialValue;
  final String message;
  final FormFieldValidator<bool> validator;
  final FormFieldSetter<bool> onSaved;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: initialValue,
      builder: (state) {
        Widget main;
        if (message == null) {
          main = Checkbox(
            value: state.value,
            onChanged: (bool newVal) => state.didChange(newVal),
          );
        } else {
          var text = state.hasError
              ? Text(message,
                  style: TextStyle(color: Theme.of(context).errorColor))
              : Text(message);
          main = Row(
            children: <Widget>[
              Checkbox(
                value: state.value,
                onChanged: (bool newVal) => state.didChange(newVal),
              ),
              SizedBox(width: kDefaultPadding),
              text,
            ],
          );
        }
        if (state.hasError) {
          main = InputDecorator(
            child: main,
            decoration: InputDecoration(
                errorText: state.errorText,
                isCollapsed: true,
                errorBorder: InputBorder.none),
          );
        }
        return main;
      },
      validator: validator,
      onSaved: onSaved,
    );
  }
}

Widget makeLoginDialog(BuildContext context, String repository, String remote) {
  var username = "";
  var password = "";
  bool saveLogin = false;
  Future<Tuple2<String, String>> readingRemoteData = PlomGitPrefs.instance
      .readEncryptedUser(repository, remote)
      .then((val) {
        if (val != null) username = val;
      })
      .then((_) =>
          PlomGitPrefs.instance.readEncryptedPassword(repository, remote))
      .then((val) {
        if (val != null) password = val;
        return Tuple2(username, password);
      });
  final formKey = GlobalKey<FormState>();
  return FutureBuilder(
      future: readingRemoteData,
      builder: (context, data) {
        if (data.hasData) {
          return AlertDialog(
            title: Text("Login"),
            content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RemoteUserTextFormField(
                      initialValue: "",
                      onSaved: (val) => username = val,
                    ),
                    RemotePasswordTextFormField(
                      initialValue: "",
                      onSaved: (val) => password = val,
                    ),
                    SizedBox(height: kDefaultPadding),
                    CheckboxFormField(
                      initialValue: saveLogin,
                      message: "Remember login",
                      onSaved: (val) => saveLogin = val,
                    ),
                  ],
                )),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  if (formKey.currentState.validate()) {
                    formKey.currentState.save();
                    if (saveLogin) {
                      PlomGitPrefs.instance
                          .writeEncryptedUser(repository, remote, username);
                      PlomGitPrefs.instance
                          .writeEncryptedPassword(repository, remote, password);
                    }
                    Navigator.pop(context, Tuple2(username, password));
                  }
                },
              ),
            ],
          );
        } else {
          print("waiting");
          return AlertDialog(
            title: Text("Login"),
            content: SizedBox(width: 32, height: 32),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
            ],
          );
        }
      });
}

Future<T> retryWithAskCredentials<T>(String repositoryName, String remoteName,
    Future<T> Function(String, String) fn, BuildContext context) {
  // Check if we have any saved credentials
  String user = "";
  String password = "";
  return PlomGitPrefs.instance
      .readEncryptedUser(repositoryName, remoteName)
      .then((val) {
        if (val != null) user = val;
      })
      .then((_) => PlomGitPrefs.instance
          .readEncryptedPassword(repositoryName, remoteName))
      .then((val) {
        if (val != null) password = val;
      })
      .then((_) => fn(user, password))
      .catchError((error) {
        // Ask for a username and password and pass those values into the function
        return showDialog<Tuple2>(
                context: context,
                builder: (context) =>
                    makeLoginDialog(context, repositoryName, remoteName))
            .then((Tuple2 login) {
          if (login != null) {
            return fn(login.item1, login.item2);
          }
          throw "Cancelled";
        });
      },
          test: (error) =>
              error is Libgit2Exception &&
              error.errorCode == Libgit2Exception.GIT_EUSER);
}

class GitRepositoryState {
  int state;
  GitRepositoryState.fromState(this.state);
  bool get normal => (state == 0);
  bool get merge => (state == 1);
}

class RawGitStatusFlags {
  RawGitStatusFlags.fromStatus(int status) {
    indexNew = ((status & 1) != 0);
    indexModified = ((status & 2) != 0);
    indexDeleted = ((status & 4) != 0);
    indexRenamed = ((status & 8) != 0);
    indexTypechange = ((status & 16) != 0);
    workTreeNew = ((status & 128) != 0);
    workTreeModified = ((status & 256) != 0);
    workTreeDeleted = ((status & 512) != 0);
    workTreeTypechange = ((status & 1024) != 0);
    workTreeRenamed = ((status & 2048) != 0);
    workTreeUnreadable = ((status & 4096) != 0);
    ignored = ((status & 16384) != 0);
    conflicted = ((status & 32768) != 0);
  }

  bool indexNew = false;
  bool indexModified = false;
  bool indexDeleted = false;
  bool indexRenamed = false;
  bool indexTypechange = false;
  bool workTreeNew = false;
  bool workTreeModified = false;
  bool workTreeDeleted = false;
  bool workTreeTypechange = false;
  bool workTreeRenamed = false;
  bool workTreeUnreadable = false;
  bool ignored = false;
  bool conflicted = false;
  bool get staged =>
      indexNew | indexModified | indexDeleted | indexRenamed | indexTypechange;
  bool get unstaged =>
      workTreeNew |
      workTreeModified |
      workTreeDeleted |
      workTreeTypechange |
      workTreeUnreadable |
      conflicted;
}

class GitStatusFlags {
  bool isStaged = false;
  bool isModified = false;
  bool isNew = false;
  bool isDeleted = false;
  bool isConflicted = false;

  bool dirHasUnstagedModifications = false;
  bool dirHasStagedModifications = false;
  bool dirIsInGit = false;

  GitStatusFlags();
  GitStatusFlags.fromFlags(int gitFlags) {
    var status = RawGitStatusFlags.fromStatus(gitFlags);
    isStaged = status.staged;
    isNew = status.workTreeNew || status.indexNew;
    isModified = status.indexModified |
        status.indexTypechange |
        status.workTreeModified |
        status.workTreeTypechange;
    isDeleted = status.indexDeleted | status.workTreeDeleted;
    isConflicted = status.conflicted;
  }
}

class PlomGitPrefs {
  // Singleton instance
  static final PlomGitPrefs instance = PlomGitPrefs._create();

  FlutterSecureStorage storage;

  PlomGitPrefs._create() {
    storage = new FlutterSecureStorage();
  }

  Future<void> writeEncryptedUser(
      String repository, String remote, String user) {
    return storage.write(key: "repo/$repository/$remote/user", value: user);
  }

  Future<void> writeEncryptedPassword(
      String repository, String remote, String password) {
    return storage.write(
        key: "repo/$repository/$remote/password", value: password);
  }

  Future<String> readEncryptedUser(String repository, String remote) {
    return storage.read(key: "repo/$repository/$remote/user");
  }

  Future<String> readEncryptedPassword(String repository, String remote) {
    return storage.read(key: "repo/$repository/$remote/password");
  }

  Future<void> eraseRepositoryPreferences(String repository) {
    return storage.readAll().then((map) {
      map.keys.forEach((key) {
        if (key.startsWith("repo/$repository/")) {
          storage.delete(key: key);
        }
      });
    });
  }
}

Future<U> showProgressWhileWaitingFor<U>(
    BuildContext context, Future<U> future) {
  showDialog(
      context: context,
      barrierColor: null,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
          onWillPop: () => Future.value(false),
          child: Align(
              alignment: Alignment(0.0, -0.25),
              child: Card(
                  elevation: 3,
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Container(
                          child: CircularProgressIndicator(),
                          width: 32,
                          height: 32))))));

  return future.whenComplete(() {
    Navigator.of(context).pop();
  });
}

const double kDefaultPadding = 5;
const double kDefaultSectionSpacing = 12;
