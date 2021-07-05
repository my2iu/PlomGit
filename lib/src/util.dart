import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libgit2/libgit2.dart' show Libgit2Exception;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import 'dart:convert' show jsonDecode, jsonEncode;

class TextAndIcon extends StatelessWidget {
  TextAndIcon(this.text, [this.icon]);
  final Widget text;
  final Widget? icon;
  @override
  Widget build(BuildContext context) {
    var iconWidget = icon;
    if (iconWidget == null) iconWidget = Icon(null);
    return Row(
        children: <Widget>[iconWidget, SizedBox(width: kDefaultPadding), text]);
  }
}

class RepositoryNameTextFormField extends StatelessWidget {
  RepositoryNameTextFormField(
      {this.initialValue, this.onSaved, this.autofocus = false});
  final String? initialValue;
  final Function(String?)? onSaved;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return RepositoryOrRemoteNameTextFormField(
        initialValue: initialValue,
        onSaved: onSaved,
        forRemote: false,
        autofocus: autofocus);
  }
}

class RepositoryOrRemoteNameTextFormField extends ValidatingNameTextFormField {
  RepositoryOrRemoteNameTextFormField(
      {String? initialValue,
      Function(String?)? onSaved,
      bool forRemote = false,
      bool autofocus = false})
      : super(
            initialValue: initialValue,
            label: forRemote ? 'Remote name' : 'Repository name',
            onSaved: onSaved,
            autofocus: autofocus);
}

class ValidatingNameTextFormField extends StatelessWidget {
  ValidatingNameTextFormField(
      {this.initialValue,
      this.label = "Name",
      this.onSaved,
      this.autofocus = false});
  final String? initialValue;
  final String label;
  final Function(String?)? onSaved;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      autofocus: autofocus,
      decoration: InputDecoration(labelText: label),
      onSaved: onSaved,
      validator: (text) {
        if (text!.isEmpty) return "Please enter a name";
        if (text.contains("/")) return "The name should not use the / symbol";
        if (text.contains("\\")) return "The name should not use the \\ symbol";
        return null;
      },
    );
  }
}

class RemoteUserTextFormField extends StatelessWidget {
  RemoteUserTextFormField(
      {this.initialValue, this.onSaved, this.autofocus = false});
  final String? initialValue;
  final Function(String?)? onSaved;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      autofocus: autofocus,
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
  final String? initialValue;
  final Function(String?)? onSaved;

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
  final String? message;
  final FormFieldValidator<bool>? validator;
  final FormFieldSetter<bool>? onSaved;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: initialValue,
      builder: (state) {
        Widget main;
        if (message == null) {
          main = Checkbox(
            value: state.value,
            onChanged: (bool? newVal) => state.didChange(newVal),
          );
        } else {
          var text = state.hasError
              ? Text(message!,
                  style: TextStyle(color: Theme.of(context).errorColor))
              : Text(message!);
          main = CheckboxListTile(
            value: state.value,
            onChanged: (bool? newVal) => state.didChange(newVal),
            title: text,
            controlAffinity: ListTileControlAffinity.leading,
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

Future<bool?> showConfirmDialog(
    BuildContext context, String title, String message, String actionMessage,
    [String cancelMessage = "Cancel"]) {
  return showDialog<bool>(
      context: context,
      builder: (context) => _makeConfirmDialog(
          context, title, message, actionMessage, cancelMessage));
}

Widget _makeConfirmDialog(
    BuildContext context, String title, String message, String actionMessage,
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

Widget makeLoginDialog(BuildContext context, String repository, String remote,
    String initialUser, String initialPassword) {
  var username = initialUser;
  var password = initialPassword;
  bool saveLogin = false;
  Future<Tuple2<String, String>> readingRemoteData = PlomGitPrefs.instance
      .readEncryptedUser(repository, remote)
      .then<void>((val) {
        if (val != null) username = val;
      })
      .then((_) =>
          PlomGitPrefs.instance.readEncryptedPassword(repository, remote))
      .then((val) {
        if (val != null) password = val;
        return Tuple2(username, password);
      });
  final formKey = GlobalKey<FormState>();
  return FutureBuilder<Tuple2<String, String>>(
      future: readingRemoteData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AlertDialog(
            title: Text("Login"),
            content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RemoteUserTextFormField(
                      autofocus: true,
                      initialValue: username,
                      onSaved: (val) => username = val!,
                    ),
                    RemotePasswordTextFormField(
                      initialValue: password,
                      onSaved: (val) => password = val!,
                    ),
                    SizedBox(height: kDefaultPadding),
                    CheckboxFormField(
                      initialValue: saveLogin,
                      message: "Remember login",
                      onSaved: (val) => saveLogin = val!,
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
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    if (saveLogin) {
                      PlomGitPrefs.instance.writeEncryptedUserPassword(
                          repository, remote, username, password);
                    }
                    Navigator.pop(context, Tuple2(username, password));
                  }
                },
              ),
            ],
          );
        } else {
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
      .readRemoteCredentialsInfo(repositoryName, remoteName)
      .then((credential) {
        if (credential.type == RemoteCredentialsType.savedCredentials) {
          return PlomGitPrefs.instance
              .readEncryptedAccountSecurityCredentials(
                  credential.savedCredentialsId)
              .then((accountCredentials) {
            user = accountCredentials.user ?? "";
            password = accountCredentials.password ?? "";
          });
        } else {
          return PlomGitPrefs.instance
              .readEncryptedUser(repositoryName, remoteName)
              .then<void>((val) {
                if (val != null) user = val;
              })
              .then((_) => PlomGitPrefs.instance
                  .readEncryptedPassword(repositoryName, remoteName))
              .then<void>((val) {
                if (val != null) password = val;
              });
        }
      })
      .then((_) => fn(user, password))
      .catchError((error) {
        // Ask for a username and password and pass those values into the function
        return showDialog<Tuple2<String, String>>(
                context: context,
                builder: (context) => makeLoginDialog(
                    context, repositoryName, remoteName, user, password))
            .then((Tuple2<String, String>? login) {
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

class AccountCredentialDescription {
  int id = 0;
  String name = "";

  AccountCredentialDescription();
  AccountCredentialDescription.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'] {
    String type = json['type'];
    assert(type == 'userpass');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': 'userpass',
      };

  static int findNextAccountCredentialIdInList(
      List<AccountCredentialDescription> list) {
    for (int n = 1;; n++) {
      if (!list.any((account) => account.id == n)) return n;
    }
  }

  void addAccountCredentialToList(List<AccountCredentialDescription> list) {
    if (id != 0) {
      int idx = list.indexWhere((entry) => entry.id == id);
      assert(idx >= 0);
      list[idx] = this;
      return;
    }
    id = findNextAccountCredentialIdInList(list);
    list.add(this);
  }
}

class AccountSecurityCredentials {
  String? user = '';
  String? password = '';
  AccountSecurityCredentials();

  AccountSecurityCredentials.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('user')) user = json['user'] as String;
    if (json.containsKey('password')) password = json['password'] as String;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null && user!.isNotEmpty) json['user'] = user;
    if (password != null && password!.isNotEmpty) json['password'] = password;
    return json;
  }
}

// Whether a repository's remote has a user-password directly stored or whether
// it refers to a separate account/saved-crecentials
enum RemoteCredentialsType { userPassword, savedCredentials }

// Describes which security credentials should be used for a repository's remote
class RemoteCredentialsInfo {
  RemoteCredentialsType type = RemoteCredentialsType.userPassword;

  // If using saved credentials, this is the id of which account or saved
  // credentials to use (or -1 for none)
  int savedCredentialsId = -1;

  RemoteCredentialsInfo();

  static RemoteCredentialsType _stringToCredentialsType(String? str) {
    switch (str) {
      case "userpass":
        return RemoteCredentialsType.userPassword;
      case "savedcredentials":
        return RemoteCredentialsType.savedCredentials;
      default:
        return RemoteCredentialsType.userPassword;
    }
  }

  RemoteCredentialsInfo.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('type'))
      type = _stringToCredentialsType(json['type'] as String);
    if (json.containsKey('savedCredentials'))
      savedCredentialsId = (json['savedCredentials'] as num).toInt();
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case RemoteCredentialsType.userPassword:
        typeString = "userpass";
        break;
      case RemoteCredentialsType.savedCredentials:
        typeString = "savedcredentials";
        break;
    }

    Map<String, dynamic> json = {};
    json['type'] = typeString;
    if (savedCredentialsId >= 0) json['savedCredentials'] = savedCredentialsId;
    return json;
  }
}

class PlomGitPrefs {
  // Singleton instance
  static final PlomGitPrefs instance = PlomGitPrefs._create();

  late FlutterSecureStorage storage;
  late Future<SharedPreferences> sharedPreferences =
      SharedPreferences.getInstance();

  PlomGitPrefs._create() {
    storage = new FlutterSecureStorage();
  }

  Future<void> writeEncryptedUserPassword(
      String repository, String remote, String? user, String? password) {
    return Future.value(null).then((_) {
      if (user?.isEmpty ?? true) user = null;
      return storage.write(
          key: "repo/$repository/remote/$remote/user", value: user);
    }).then((_) {
      if (password?.isEmpty ?? true) password = null;
      return storage.write(
          key: "repo/$repository/remote/$remote/password", value: password);
    });
  }

  Future<String?> readEncryptedUser(String repository, String remote) {
    return storage.read(key: "repo/$repository/remote/$remote/user");
  }

  Future<String?> readEncryptedPassword(String repository, String remote) {
    return storage.read(key: "repo/$repository/remote/$remote/password");
  }

  Future<void> writeEncryptedAccountSecurityCredentials(
      int accountId, AccountSecurityCredentials credentials) {
    return storage.write(
        key: "account/$accountId/credentials", value: jsonEncode(credentials));
  }

  Future<AccountSecurityCredentials> readEncryptedAccountSecurityCredentials(
      int accountId) {
    return storage
        .read(key: "account/$accountId/credentials")
        .then((str) =>
            AccountSecurityCredentials.fromJson(jsonDecode(str ?? "{}")))
        .catchError((e) => AccountSecurityCredentials());
  }

  Future<void> writeRemoteCredentialsInfo(
      String repository, String remote, RemoteCredentialsInfo info) {
    return sharedPreferences.then((prefs) {
      prefs.setString(
          "repo/$repository/remote/$remote/credentials", jsonEncode(info));
    });
  }

  Future<RemoteCredentialsInfo> readRemoteCredentialsInfo(
      String repository, String remote) {
    return sharedPreferences
        .then((prefs) =>
            prefs.getString("repo/$repository/remote/$remote/credentials"))
        .then(
            (json) => RemoteCredentialsInfo.fromJson(jsonDecode(json ?? "{}")));
  }

  void writeLastAuthor(String repository, String name, String email) {
    sharedPreferences.then((prefs) {
      prefs.setStringList("repo/$repository/author", [name, email]);
      prefs.setStringList("global/author.last", [name, email]);
    });
  }

  Future<List<String>?> _readSuggestedAuthor(String repository) {
    return sharedPreferences.then((prefs) =>
        prefs.getStringList("repo/$repository/author") ??
        prefs.getStringList("global/author.last"));
  }

  Future<String> readSuggestedAuthorName(String repository) {
    return _readSuggestedAuthor(repository).then((author) => author?[0] ?? "");
  }

  Future<String> readSuggestedAuthorEmail(String repository) {
    return _readSuggestedAuthor(repository).then((author) => author?[1] ?? "");
  }

  Future<bool> writeRepositoryCommitMessage(
      String repository, String commitMessage) {
    return sharedPreferences.then((prefs) =>
        prefs.setString("repo/$repository/commit.msg", commitMessage));
  }

  Future<String> readRepositoryCommitMessage(String repository) {
    return sharedPreferences
        .then((prefs) => prefs.getString("repo/$repository/commit.msg") ?? "");
  }

  Future<void> eraseRepositoryPreferences(String repository) {
    return storage
        .readAll()
        .then((map) {
          map.keys.forEach((key) {
            if (key.startsWith("repo/$repository/")) {
              storage.delete(key: key);
            }
          });
        })
        .then((_) => sharedPreferences)
        .then((prefs) {
          prefs.getKeys().forEach((key) {
            if (key.startsWith("repo/$repository/")) {
              prefs.remove(key);
            }
          });
        });
  }

  Future<List<AccountCredentialDescription>> readAccountCredentialsList() {
    return sharedPreferences
        .then((prefs) => prefs.getString("global/accounts.list") ?? "[]")
        .then((json) => jsonDecode(json) as List<dynamic>)
        .then((dynlist) => dynlist
            .map((dyn) => AccountCredentialDescription.fromJson(
                dyn as Map<String, dynamic>))
            .toList());
  }

  Future<void> writeAccountCredentialsList(
      List<AccountCredentialDescription> credentials) {
    return sharedPreferences.then((prefs) =>
        prefs.setString("global/accounts.list", jsonEncode(credentials)));
  }

  Future<void> eraseAccountCredential(int credentialId) {
    Future<void> eraseFuture;
    if (credentialId > 0) {
      // Delete user-password from secure storage
      eraseFuture = storage
          .delete(key: "account/$credentialId/credentials")
          .catchError((e) {
        // Ignore errors
      }).then((_) {
        // TODO: Remove references to the account from repositories
      });
    } else {
      eraseFuture = Future.value();
    }
    return eraseFuture
        .then((_) => readAccountCredentialsList())
        .then((accounts) {
      int idx = accounts.indexWhere((acct) => acct.id == credentialId);
      if (idx >= 0) {
        accounts.removeAt(idx);
      }
      writeAccountCredentialsList(accounts);
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

const String DEFAULT_REPO_NAME = "";
const String DEFAULT_REPO_URL = "https://";
