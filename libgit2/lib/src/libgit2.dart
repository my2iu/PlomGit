import 'dart:ffi';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'native_git.dart';
import 'generated_bindings.dart';

final NativeLibrary _git = NativeLibrary(Platform.isAndroid
    ? DynamicLibrary.open("libgit2.so")
    : DynamicLibrary.process());

class Libgit2 {
  // I don't really need this MethodChannel stuff since I don't need
  // interop with Java/Objective-C, but I'll keep it around anyway just
  // in case.
  static const MethodChannel _channel = const MethodChannel('libgit2');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static void init() {
    _git.libgit2_init();
  }

  static int queryFeatures() {
    return _git.libgit2_features();
  }

  /// Checks the return code for errors and if so, convert it to a thrown
  /// exception
  static int _checkErrors(int errorCode) {
    if (errorCode < 0) throw Libgit2Exception.fromErrorCode(errorCode);
    return errorCode;
  }

  static void initRepository(String dir) {
    Pointer<Pointer<git_repository>> repository =
        calloc<Pointer<git_repository>>();
    repository.value = nullptr;
    var dirPtr = dir.toNativeUtf8();
    var mainPtr = "refs/heads/main".toNativeUtf8();
    try {
      _checkErrors(_git.repository_init(repository, dirPtr.cast<Int8>(), 0));
      // Using repository_init_ext doesn't seem to change the branch for head
      // so I'm just manually setting it to main
      _checkErrors(
          _git.repository_set_head(repository.value, mainPtr.cast<Int8>()));
    } finally {
      calloc.free(dirPtr);
      if (repository.value != nullptr) _git.repository_free(repository.value);
      calloc.free(repository);
      calloc.free(mainPtr);
    }
  }

  static void clone(String url, String dir, String username, String password) {
    setupCredentials(username, password);
    Pointer<Pointer<git_repository>> repository =
        calloc<Pointer<git_repository>>();
    repository.value = nullptr;
    Pointer<git_clone_options> cloneOptions = calloc<git_clone_options>();
    var dirPtr = dir.toNativeUtf8();
    var urlPtr = url.toNativeUtf8();
    try {
      _checkErrors(_git.clone_options_init(
          cloneOptions, gitHelpers.clone_options_version()));
      gitHelpers.clone_options_set_credentials_cb(
          cloneOptions,
          Pointer.fromFunction<git_credential_acquire_cb>(
              credentialsCallback, Libgit2Exception.GIT_PASSTHROUGH));
      _checkErrors(_git.clone(
          repository, urlPtr.cast<Int8>(), dirPtr.cast<Int8>(), cloneOptions));
    } finally {
      calloc.free(dirPtr);
      calloc.free(urlPtr);
      if (repository.value != nullptr) _git.repository_free(repository.value);
      calloc.free(repository);
      calloc.free(cloneOptions);
    }
  }

  static T _withRepository<T>(
      String dir, T Function(Pointer<git_repository>) fn) {
    Pointer<Pointer<git_repository>> repository =
        calloc<Pointer<git_repository>>();
    repository.value = nullptr;
    var dirPtr = dir.toNativeUtf8();
    try {
      _checkErrors(_git.repository_open(repository, dirPtr.cast<Int8>()));
      return fn(repository.value);
    } finally {
      calloc.free(dirPtr);
      if (repository.value != nullptr) _git.repository_free(repository.value);
      calloc.free(repository);
    }
  }

  static T _withRepositoryAndRemote<T>(String dir, String remoteStr,
      T Function(Pointer<git_repository>, Pointer<git_remote>) fn) {
    Pointer<Pointer<git_remote>> remote = calloc<Pointer<git_remote>>();
    remote.value = nullptr;
    var remoteStrPtr = remoteStr.toNativeUtf8();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(
            _git.remote_lookup(remote, repo, remoteStrPtr.cast<Int8>()));
        return fn(repo, remote.value);
      });
    } finally {
      calloc.free(remoteStrPtr);
      if (remote.value != nullptr) _git.remote_free(remote.value);
      calloc.free(remote);
    }
  }

  static T _withRepositoryAndIndex<T>(
      String dir, T Function(Pointer<git_repository>, Pointer<git_index>) fn) {
    Pointer<Pointer<git_index>> index = calloc<Pointer<git_index>>();
    index.value = nullptr;
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git.repository_index(index, repo));
        return fn(repo, index.value);
      });
    } finally {
      if (index.value != nullptr) _git.index_free(index.value);
      calloc.free(index);
    }
  }

  static List<String> remoteList(String dir) {
    Pointer<git_strarray> remotesStrings = calloc<git_strarray>();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git.remote_list(remotesStrings, repo));
        List<String> remotes = [];
        for (int n = 0; n < remotesStrings.ref.count; n++)
          remotes
              .add(remotesStrings.ref.strings[n].cast<Utf8>().toDartString());
        return remotes;
      });
    } finally {
      _git.strarray_dispose(remotesStrings);
      calloc.free(remotesStrings);
    }
  }

  static void fetch(
      String dir, String remoteStr, String username, String password) {
    setupCredentials(username, password);
    Pointer<git_fetch_options> fetchOptions = calloc<git_fetch_options>();
    try {
      return _withRepositoryAndRemote(dir, remoteStr, (repo, remote) {
        _checkErrors(_git.fetch_options_init(
            fetchOptions, gitHelpers.fetch_options_version()));
        gitHelpers.fetch_options_set_credentials_cb(
            fetchOptions,
            Pointer.fromFunction<git_credential_acquire_cb>(
                credentialsCallback, Libgit2Exception.GIT_PASSTHROUGH));
        _checkErrors(_git.remote_fetch(remote, nullptr, fetchOptions, nullptr));
      });
    } finally {
      calloc.free(fetchOptions);
    }
  }

  // Since Dart is single-threaded, we can only have one libgit2 call
  // in-flight at once, so it's safe to store data needed for callbacks
  // in static variables
  static String _lastUrlCredentialCheck = "";
  static String _credentialUsername = "";
  static String _credentialPassword = "";
  static int credentialsCallback(
      Pointer<Pointer<git_credential>> out,
      Pointer<Int8> url,
      Pointer<Int8> username_from_url,
      @Uint32() int allowed_type,
      Pointer<Void> payload) {
    // We don't interactively ask the user for a password, so if we
    // get asked for the password for the same page twice, we'll
    // abort instead of repeatedly retrying the same password.
    String currentUrl = url.cast<Utf8>().toDartString();
    if (currentUrl == _lastUrlCredentialCheck) {
      Pointer<Utf8> msg = "Security credentials not accepted".toNativeUtf8();
      _git.error_set_str(0, msg.cast<Int8>());
      calloc.free(msg);
      return Libgit2Exception.GIT_EUSER;
    }
    _lastUrlCredentialCheck = currentUrl;

    if (_credentialUsername.isEmpty && _credentialPassword.isEmpty) {
      // No authentication credentials available, so ask the user for them
      return Libgit2Exception.GIT_EUSER;
    }

    // User and password combination
    if ((allowed_type & 1) != 0) {
      Pointer<Utf8> username = _credentialUsername.toNativeUtf8();
      Pointer<Utf8> password = _credentialPassword.toNativeUtf8();
      try {
        return _git.credential_userpass_plaintext_new(
            out, username.cast<Int8>(), password.cast<Int8>());
      } finally {
        calloc.free(username);
        calloc.free(password);
      }
    }
    return Libgit2Exception.GIT_PASSTHROUGH;
  }

  static void setupCredentials(String username, String password) {
    _credentialUsername = username;
    _credentialPassword = password;
    _lastUrlCredentialCheck = "";
  }

  static void push(
      String dir, String remoteStr, String username, String password) {
    setupCredentials(username, password);
    Pointer<git_push_options> pushOptions = calloc<git_push_options>();
    Pointer<git_strarray> refStrings = calloc<git_strarray>();
    refStrings.ref.count = 1;
    refStrings.ref.strings = calloc.call<Pointer<Int8>>(1);
    Pointer<Pointer<git_reference>> headRef = calloc<Pointer<git_reference>>();
    headRef.value = nullptr;
    try {
      return _withRepositoryAndRemote(dir, remoteStr, (repo, remote) {
        // Just push head to wherever for now
        _checkErrors(_git.repository_head(headRef, repo));
        refStrings.ref.strings[0] = _git.reference_name(headRef.value);

        _checkErrors(_git.push_options_init(
            pushOptions, gitHelpers.push_options_version()));
        gitHelpers.push_options_set_credentials_cb(
            pushOptions,
            Pointer.fromFunction<git_credential_acquire_cb>(
                credentialsCallback, Libgit2Exception.GIT_PASSTHROUGH));
        _checkErrors(_git.remote_push(remote, refStrings, pushOptions));
      });
    } finally {
      calloc.free(pushOptions);
      if (headRef.value != nullptr) _git.reference_free(headRef.value);
      calloc.free(headRef);
      calloc.free(refStrings.ref.strings);
      calloc.free(refStrings);
    }
  }

  static dynamic status(String dir) {
    Pointer<git_status_options> statusOptions = calloc<git_status_options>();
    Pointer<Pointer<git_status_list>> statusList =
        calloc<Pointer<git_status_list>>();
    statusList.value = nullptr;
    // Pointer<Pointer<Utf8>> path = calloc.call<Pointer<Utf8>>( 1);
    // path.value = "*".toNativeUtf8();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git.status_options_init(
            statusOptions, gitHelpers.status_options_version()));
        gitHelpers.status_options_config(statusOptions, nullptr);
        _checkErrors(_git.status_list_new(statusList, repo, statusOptions));
        int numStatuses = _git.status_list_entrycount(statusList.value);
        if (numStatuses > 0) {
          var statusEntries = [];
          for (int n = 0; n < numStatuses; n++) {
            Pointer<git_status_entry> entry =
                _git.status_byindex(statusList.value, n);
            var entryData = [];
            if (entry.ref.index_to_workdir != nullptr &&
                entry.ref.index_to_workdir.ref.new_file.path != nullptr)
              entryData.add(entry.ref.index_to_workdir.ref.new_file.path
                  .cast<Utf8>()
                  .toDartString());
            else
              entryData.add(null);
            if (entry.ref.head_to_index != nullptr &&
                entry.ref.head_to_index.ref.old_file.path != nullptr)
              entryData.add(entry.ref.head_to_index.ref.old_file.path
                  .cast<Utf8>()
                  .toDartString());
            else
              entryData.add(null);
            entryData.add(entry.ref.status);
            statusEntries.add(entryData);
          }
          return statusEntries;
        }
        return [];
      });
    } finally {
      calloc.free(statusOptions);
      if (statusList.value != nullptr) _git.status_list_free(statusList.value);
      calloc.free(statusList);
      // calloc.free(path.value);
      // calloc.free(path);
    }
  }

  static void addToIndex(String dir, String file) {
    var filePtr = file.toNativeUtf8();
    try {
      _withRepositoryAndIndex(dir, (repo, index) {
        _checkErrors(_git.index_add_bypath(index, filePtr.cast<Int8>()));
        _checkErrors(_git.index_write(index));
      });
    } finally {
      calloc.free(filePtr);
    }
  }

  static void removeFromIndex(String dir, String file) {
    var filePtr = file.toNativeUtf8();
    try {
      _withRepositoryAndIndex(dir, (repo, index) {
        _checkErrors(_git.index_remove_bypath(index, filePtr.cast<Int8>()));
        _checkErrors(_git.index_write(index));
      });
    } finally {
      calloc.free(filePtr);
    }
  }

  // Since Dart is single-threaded, we can only have one libgit2 call
  // in-flight at once, so it's safe to store data needed for callbacks
  // in static variables
  static List<Pointer<git_oid>>? mergeHeadsFromCallback;
  static int mergeHeadsCallback(Pointer<git_oid> oid, Pointer<Void> payload) {
    Pointer<git_oid> newOid = calloc<git_oid>();
    _git.oid_cpy(newOid, oid);
    mergeHeadsFromCallback!.add(newOid);
    return 0;
  }

  static void commit(String dir, String message, String name, String email) {
    Pointer<git_oid> headOid = calloc<git_oid>();
    Pointer<git_oid> treeOid = calloc<git_oid>();
    Pointer<git_oid> finalCommitOid = calloc<git_oid>();
    Pointer<Utf8> headStr = "HEAD".toNativeUtf8();
    Pointer<Utf8> messageStr = message.toNativeUtf8();
    Pointer<Utf8> nameStr = name.toNativeUtf8();
    Pointer<Utf8> emailStr = email.toNativeUtf8();
    Pointer<Pointer<git_tree>> indexTree = calloc<Pointer<git_tree>>();
    indexTree.value = nullptr;
    int numParentCommits = 0;
    Pointer<Pointer<git_commit>> parentCommits = nullptr;
    Pointer<Pointer<git_signature>> authorSig =
        calloc<Pointer<git_signature>>();
    authorSig.value = nullptr;
    try {
      _withRepositoryAndIndex(dir, (repo, index) {
        // Check if we're in the middle of a merge
        int repoState = _git.repository_state(repo);

        // Check if there is a head
        var hasNoHead = _git.repository_head_unborn(repo);
        _checkErrors(hasNoHead);

        // Figure out the different heads that we're merging
        mergeHeadsFromCallback = [];
        try {
          if (repoState == 1) {
            _git.repository_mergehead_foreach(
                repo,
                Pointer.fromFunction<
                        Int32 Function(Pointer<git_oid>, Pointer<Void>)>(
                    mergeHeadsCallback, 1),
                nullptr);
          }
          // Allocate parent commits
          numParentCommits =
              mergeHeadsFromCallback!.length + (hasNoHead == 1 ? 0 : 1);
          parentCommits = calloc.call<Pointer<git_commit>>(numParentCommits);
          for (int n = 0; n < numParentCommits; n++) parentCommits[n] = nullptr;

          // Convert merge heads to annotated_commits
          for (int n = 0; n < mergeHeadsFromCallback!.length; n++) {
            _checkErrors(_git.commit_lookup(parentCommits.elementAt(n + 1),
                repo, mergeHeadsFromCallback![n]));
          }
        } finally {
          mergeHeadsFromCallback!.forEach((oid) {
            calloc.free(oid);
          });
          mergeHeadsFromCallback = null;
        }

        // Convert index to a tree
        _checkErrors(_git.index_write_tree(treeOid, index));
        _checkErrors(_git.tree_lookup(indexTree, repo, treeOid));

        // If the repository has no head, then this initial commit has nothing
        // to branch off of
        if (hasNoHead == 0) {
          // Get head commit that we're branching off of
          _checkErrors(
              _git.reference_name_to_id(headOid, repo, headStr.cast<Int8>()));
          _checkErrors(
              _git.commit_lookup(parentCommits.elementAt(0), repo, headOid));
        }

        // Use the same info for author and commiter signature
        _checkErrors(_git.signature_now(
            authorSig, nameStr.cast<Int8>(), emailStr.cast<Int8>()));

        // Perform the commit
        _checkErrors(_git.commit_create(
            finalCommitOid,
            repo,
            headStr.cast<Int8>(),
            authorSig.value,
            authorSig.value,
            nullptr,
            messageStr.cast<Int8>(),
            indexTree.value,
            numParentCommits,
            parentCommits));

        _checkErrors(_git.repository_state_cleanup(repo));
      });
    } finally {
      calloc.free(finalCommitOid);
      calloc.free(headOid);
      calloc.free(treeOid);
      calloc.free(headStr);
      if (indexTree.value != nullptr) _git.tree_free(indexTree.value);
      calloc.free(indexTree);
      if (parentCommits != nullptr) {
        for (int n = 0; n < numParentCommits; n++) {
          if (parentCommits[n] != nullptr) _git.commit_free(parentCommits[n]);
        }
        calloc.free(parentCommits);
      }
      calloc.free(messageStr);
      calloc.free(nameStr);
      calloc.free(emailStr);
      if (authorSig.value != nullptr) _git.signature_free(authorSig.value);
      calloc.free(authorSig);
    }
  }

  static void revertFile(String dir, String file) {
    var filePtr = file.toNativeUtf8();
    Pointer<git_checkout_options> checkoutOptions =
        calloc<git_checkout_options>();
    Pointer<Pointer<Int8>> fileStrStr = calloc.call<Pointer<Int8>>(1);
    fileStrStr[0] = file.toNativeUtf8().cast<Int8>();
    try {
      _withRepository(dir, (repo) {
        _checkErrors(_git.checkout_options_init(
            checkoutOptions, gitHelpers.checkout_options_version()));
        gitHelpers.checkout_options_config_for_revert(
            checkoutOptions, fileStrStr);
        _checkErrors(_git.checkout_head(repo, checkoutOptions));
      });
    } finally {
      calloc.free(checkoutOptions);
      calloc.free(filePtr);
      calloc.free(fileStrStr[0]);
      calloc.free(fileStrStr);
    }
  }

  static int _mergeAnalysis(Pointer<git_repository> repo,
      Pointer<Pointer<git_annotated_commit>> upstreamToMerge) {
    Pointer<Int32> mergeAnalysis = calloc<Int32>();
    mergeAnalysis.value = 0;
    Pointer<Int32> mergePreferences = calloc<Int32>();
    mergePreferences.value = 0;
    try {
      _checkErrors(_git.merge_analysis(
          mergeAnalysis, mergePreferences, repo, upstreamToMerge, 1));
      int toReturn = mergeAnalysis.value;
      return toReturn;
    } finally {
      calloc.free(mergeAnalysis);
      calloc.free(mergePreferences);
    }
  }

  static MergeStatus mergeWithUpstream(String dir) {
    Pointer<Pointer<git_annotated_commit>> upstreamToMerge =
        calloc.call<Pointer<git_annotated_commit>>(1);
    upstreamToMerge.elementAt(0).value = nullptr;

    Pointer<Pointer<git_reference>> headRefToMergeWith =
        calloc<Pointer<git_reference>>();
    headRefToMergeWith.value = nullptr;
    Pointer<Utf8> headRefString = "HEAD".toNativeUtf8();
    Pointer<git_buf> buf = gitHelpers.allocateGitBuf();

    Pointer<Pointer<git_reference>> headRef = calloc<Pointer<git_reference>>();
    headRef.value = nullptr;
    Pointer<Pointer<git_reference>> upstreamRef =
        calloc<Pointer<git_reference>>();
    upstreamRef.value = nullptr;
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git.repository_head(headRef, repo));
        _checkErrors(_git.branch_upstream(upstreamRef, headRef.value));
        _checkErrors(_git.annotated_commit_from_ref(
            upstreamToMerge.elementAt(0), repo, upstreamRef.value));
        int analysisResults = _mergeAnalysis(repo, upstreamToMerge);
        if ((analysisResults & 2) != 0) {
          return MergeStatus.UP_TO_DATE;
        } else if ((analysisResults & (8)) != 0) {
          return MergeStatus.NO_HEAD;
        } else if ((analysisResults & (4)) != 0) {
          Pointer<git_oid> upstreamCommitId =
              _git.annotated_commit_id(upstreamToMerge[0]);
          Pointer<git_checkout_options> checkoutOptions =
              calloc<git_checkout_options>();
          Pointer<Pointer<git_commit>> upstreamCommit =
              calloc<Pointer<git_commit>>();
          upstreamCommit.value = nullptr;
          Pointer<Pointer<git_reference>> newHeadRef =
              calloc<Pointer<git_reference>>();
          newHeadRef.value = nullptr;
          try {
            // Get the commit to merge to
            _checkErrors(
                _git.commit_lookup(upstreamCommit, repo, upstreamCommitId));

            // Checkout upstream to fast-forward
            _checkErrors(_git.checkout_options_init(
                checkoutOptions, gitHelpers.checkout_options_version()));
            gitHelpers.checkout_options_config_for_fastforward(checkoutOptions);
            _checkErrors(_git.checkout_tree(repo,
                upstreamCommit.value.cast<git_object>(), checkoutOptions));

            // Move HEAD
            _checkErrors(_git.reference_set_target(
                newHeadRef, headRef.value, upstreamCommitId, nullptr));
            return MergeStatus.FAST_FORWARD;
          } finally {
            calloc.free(checkoutOptions);
            if (upstreamCommit.value != nullptr)
              _git.commit_free(upstreamCommit.value);
            calloc.free(upstreamCommit);
            if (newHeadRef.value != nullptr)
              _git.reference_free(newHeadRef.value);
            calloc.free(newHeadRef);
          }
        } else if ((analysisResults & 1) != 0) {
          Pointer<git_checkout_options> checkoutOptions =
              calloc<git_checkout_options>();
          Pointer<git_merge_options> mergeOptions = calloc<git_merge_options>();

          try {
            _checkErrors(_git.checkout_options_init(
                checkoutOptions, gitHelpers.checkout_options_version()));
            gitHelpers.checkout_options_config_for_merge(checkoutOptions);
            _checkErrors(_git.merge_options_init(
                mergeOptions, gitHelpers.merge_options_version()));

            _checkErrors(_git.merge(
                repo, upstreamToMerge, 1, mergeOptions, checkoutOptions));

            return MergeStatus.NORMAL_MERGE;
          } finally {
            calloc.free(checkoutOptions);
            calloc.free(mergeOptions);
          }
        }
        return MergeStatus.MERGE_FAILED;
      });
    } finally {
      if (upstreamToMerge.value != nullptr)
        _git.annotated_commit_free(upstreamToMerge.value);
      calloc.free(upstreamToMerge);
      if (headRefToMergeWith.value != nullptr)
        _git.reference_free(headRefToMergeWith.value);
      calloc.free(headRefToMergeWith);
      calloc.free(headRefString);
      _git.buf_dispose(buf);
      calloc.free(buf);

      if (headRef.value != nullptr) _git.reference_free(headRef.value);
      calloc.free(headRef);
      if (upstreamRef.value != nullptr) _git.reference_free(upstreamRef.value);
      calloc.free(upstreamRef);
    }
  }

  static int repositoryState(String dir) {
    return _withRepository(dir, (repo) {
      return _git.repository_state(repo);
    });
  }

  static List<int> aheadBehind(String dir) {
    Pointer<IntPtr> ahead = calloc<IntPtr>();
    Pointer<IntPtr> behind = calloc<IntPtr>();
    Pointer<Pointer<git_reference>> headRef = calloc<Pointer<git_reference>>();
    headRef.value = nullptr;
    Pointer<Pointer<git_reference>> headDirectRef =
        calloc<Pointer<git_reference>>();
    headDirectRef.value = nullptr;
    Pointer<Pointer<git_reference>> upstreamRef =
        calloc<Pointer<git_reference>>();
    upstreamRef.value = nullptr;
    Pointer<Pointer<git_reference>> upstreamDirectRef =
        calloc<Pointer<git_reference>>();
    upstreamDirectRef.value = nullptr;

    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git.repository_head(headRef, repo));
        _checkErrors(_git.reference_resolve(headDirectRef, headRef.value));

        _checkErrors(_git.branch_upstream(upstreamRef, headRef.value));
        _checkErrors(
            _git.reference_resolve(upstreamDirectRef, upstreamRef.value));

        _checkErrors(_git.graph_ahead_behind(
            ahead,
            behind,
            repo,
            _git.reference_target(headDirectRef.value),
            _git.reference_target(upstreamDirectRef.value)));
        return <int>[ahead.value, behind.value];
      });
    } finally {
      calloc.free(ahead);
      calloc.free(behind);
      if (headRef.value != nullptr) _git.reference_free(headRef.value);
      calloc.free(headRef);
      if (headDirectRef.value != nullptr)
        _git.reference_free(headDirectRef.value);
      calloc.free(headDirectRef);
      if (upstreamRef.value != nullptr) _git.reference_free(upstreamRef.value);
      calloc.free(upstreamRef);
      if (upstreamDirectRef.value != nullptr)
        _git.reference_free(upstreamDirectRef.value);
      calloc.free(upstreamDirectRef);
    }
  }

  static void createRemote(String dir, String remoteName, String url) {
    Pointer<Utf8> remoteStr = remoteName.toNativeUtf8();
    Pointer<Utf8> urlStr = url.toNativeUtf8();
    Pointer<Pointer<git_remote>> remote = calloc<Pointer<git_remote>>();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git.remote_create(
            remote, repo, remoteStr.cast<Int8>(), urlStr.cast<Int8>()));
      });
    } finally {
      if (remote.value != nullptr) _git.remote_free(remote.value);
      calloc.free(remote);
      calloc.free(remoteStr);
      calloc.free(urlStr);
    }
  }

  static void deleteRemote(String dir, String remote) {
    Pointer<Utf8> remoteStr = remote.toNativeUtf8();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git.remote_delete(repo, remoteStr.cast<Int8>()));
      });
    } finally {
      calloc.free(remoteStr);
    }
  }
}

enum MergeStatus {
  UP_TO_DATE, // "Merge already up-to-date"
  NO_HEAD, // "No HEAD commit to merge"
  FAST_FORWARD, // "Merge fast-forward"
  NORMAL_MERGE, // "Merge complete, please commit"
  MERGE_FAILED, // "Cannot merge"
}

/// Packages up Libgit2 error code and error message in a single class
class Libgit2Exception implements Exception {
  String? message;
  int? errorCode;
  int? klass;

  Libgit2Exception(this.errorCode, this.message, this.klass);

  Libgit2Exception.fromErrorCode(this.errorCode) {
    var err = _git.error_last();
    if (err != nullptr) {
      message = err.ref.message.cast<Utf8>().toDartString();
      klass = err.ref.klass;
    }
  }

  // Some error codes
  static const int GIT_PASSTHROUGH = -30;
  static const int GIT_EUSER = -7;

  String toString() {
    if (message != null) return (message ?? "") + '($errorCode:$klass)';
    return 'Libgit2Exception($errorCode)';
  }
}
