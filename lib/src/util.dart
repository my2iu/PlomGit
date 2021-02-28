import 'package:flutter/material.dart';
import 'package:libgit2/libgit2.dart' show Libgit2Exception;
import 'package:tuple/tuple.dart';

Widget TextAndIcon(Widget text, [Widget icon]) {
  if (icon == null) icon = Icon(null);
  return Row(children: <Widget>[icon, SizedBox(width: 5), text]);
}

Widget makeLoginDialog(BuildContext context) {
  var username = "";
  var password = "";
  return AlertDialog(
    title: Text("Login"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
            decoration: InputDecoration(
              icon: Icon(Icons.account_circle),
              labelText: 'User',
            ),
            onChanged: (val) => username = val),
        TextField(
            obscureText: true,
            decoration: InputDecoration(
              icon: Icon(Icons.lock),
              labelText: 'Password',
            ),
            onChanged: (val) => password = val),
      ],
    ),
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
          Navigator.pop(context, Tuple2(username, password));
        },
      ),
    ],
  );
}

Future<T> retryWithAskCredentials<T>(
    Future<T> Function(String, String) fn, BuildContext context) {
  return fn("", "").catchError((error) {
    // Ask for a username and password and pass those values into the function
    return showDialog<Tuple2>(
        context: context,
        builder: (context) => makeLoginDialog(context)).then((Tuple2 login) {
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
