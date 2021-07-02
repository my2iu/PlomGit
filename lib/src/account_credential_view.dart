import 'package:flutter/material.dart';
import 'util.dart'
    show
        PlomGitPrefs,
        ValidatingNameTextFormField,
        RemoteUserTextFormField,
        RemotePasswordTextFormField,
        AccountCredentialDescription,
        AccountSecurityCredentials,
        kDefaultPadding,
        kDefaultSectionSpacing;

class AccountCredentialListView extends StatefulWidget {
  AccountCredentialListView();

  @override
  _AccountCredentialListViewState createState() =>
      _AccountCredentialListViewState();
}

class _AccountCredentialListViewState extends State<AccountCredentialListView> {
  _AccountCredentialListViewState() {
    accounts = PlomGitPrefs.instance.readAccountCredentialsList();
  }

  late Future<List<AccountCredentialDescription>> accounts;

  void _refresh() {
    setState(() {
      accounts = PlomGitPrefs.instance.readAccountCredentialsList();
    });
  }

  ListTile _makeAccountListTile(
      BuildContext context, AccountCredentialDescription account) {
    return ListTile(
        title: Text(account.name),
        trailing: _buildAccountOptionsPopupButton(account),
        onTap: () {
          showAccountCredentialsDialog(account);
        });
  }

  PopupMenuButton _buildAccountOptionsPopupButton(
      AccountCredentialDescription account) {
    return PopupMenuButton(
        onSelected: (fn) => fn(),
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              PopupMenuItem(
                  value: () {
                    PlomGitPrefs.instance
                        .eraseAccountCredential(account.id)
                        .then((_) => _refresh())
                        .catchError((error) {
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')));
                    });
                  },
                  child: Text('Delete')),
            ]);
  }

  void showAccountCredentialsDialog(AccountCredentialDescription accountInfo) {
    // Read the security credentials for the account
    Future<AccountSecurityCredentials> securityCredentials;
    if (accountInfo.id > 0)
      securityCredentials = PlomGitPrefs.instance
          .readEncryptedAccountSecurityCredentials(accountInfo.id);
    else
      securityCredentials = Future.value(AccountSecurityCredentials());
    securityCredentials
        .then((credentials) => Navigator.push(
              context,
              MaterialPageRoute<_AccountCredentials>(
                builder: (BuildContext context) {
                  return AccountCredentialsDialog(
                      _AccountCredentials(accountInfo, credentials),
                      accountInfo.id > 0);
                },
              ),
            ))
        .then((result) {
      if (result == null) return;

      PlomGitPrefs.instance.readAccountCredentialsList().then((list) {
        // Add the account to the list to get an id if it doesn't have one
        result.info.addAccountCredentialToList(list);
        return PlomGitPrefs.instance.writeAccountCredentialsList(list);
      }).then((_) {
        // Once we have an id assigned, we can encrypt the password for the account credentials
        return PlomGitPrefs.instance.writeEncryptedAccountSecurityCredentials(
            result.info.id, result.security);
      }).then((_) {
        _refresh();
      }).catchError((error) {
        _refresh();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $error')));
      });
    });
  }

  void _newAccountCredentialsPressed(BuildContext context) {
    showAccountCredentialsDialog(AccountCredentialDescription());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
            children: [Icon(Icons.manage_accounts), Text(" Manage Accounts")]),

        // title: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [Text("Account Credentials")]),
      ),
      body: FutureBuilder<List<AccountCredentialDescription>>(
          future: accounts,
          builder: (BuildContext context,
              AsyncSnapshot<List<AccountCredentialDescription>> snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) =>
                      _makeAccountListTile(context, snapshot.data![index]));
            } else {
              return Text('Loading');
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newAccountCredentialsPressed(context),
        tooltip: 'New Account Credentials',
        child: Icon(Icons.add),
      ),
    );
  }
}

class AccountCredentialsDialog extends StatelessWidget {
  AccountCredentialsDialog(this.accountInfo, this.forEdit);
  final _AccountCredentials accountInfo;
  final bool forEdit; // Editing an account or creating a new one
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Account Credentials'),
        ),
        body: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(children: [
              Form(
                  key: _formKey,
                  child: _AccoundCredentialsUserPasswordWidget(
                    accountInfo,
                    autofocus: true,
                  )),
              SizedBox(height: kDefaultSectionSpacing),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.pop(context, accountInfo);
                    }
                  },
                  child: Text(forEdit ? 'Apply' : 'Create')),
            ])));
  }
}

class _AccountCredentials {
  _AccountCredentials(this.info, this.security);
  AccountCredentialDescription info;
  AccountSecurityCredentials security;
}

class _AccoundCredentialsUserPasswordWidget extends StatelessWidget {
  _AccoundCredentialsUserPasswordWidget(this.credentials,
      {this.autofocus = false});
  final _AccountCredentials credentials;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
          child: Padding(
              padding: EdgeInsets.all(kDefaultPadding),
              child: Column(children: [
                ValidatingNameTextFormField(
                    autofocus: autofocus,
                    initialValue: credentials.info.name,
                    onSaved: (text) => credentials.info.name = text!,
                    label: "Name"),
              ]))),
      SizedBox(height: kDefaultSectionSpacing),
      Card(
          child: Padding(
              padding: EdgeInsets.all(kDefaultPadding),
              child: Column(children: [
                RemoteUserTextFormField(
                  initialValue: credentials.security.user,
                  onSaved: (text) => credentials.security.user = text!,
                ),
                RemotePasswordTextFormField(
                  initialValue: credentials.security.password,
                  onSaved: (text) => credentials.security.password = text!,
                ),
              ]))),
    ]);
  }
}
