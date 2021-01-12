import 'dart:async';
import 'dart:ffi';
import 'package:flutter_jscore/flutter_jscore.dart';
import 'package:flutter_jscore/binding/js_context_ref.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'dart:io';

class JsForGit {
  static Map<Pointer, JsForGit> ctxToJsForGit = Map<Pointer, JsForGit>();
  // For synchronizing access to JavaScriptCore
  static Future<dynamic> synchronizer;
  // Not really necessary to use all this promise and Completer stuff
  // because it seems that JavaScriptCore is executing all the promises
  // before returning from evaluate(). So having complicated code to call
  // a callback when a JS promise finishes ends up being unnecessary, but
  // we'll do it to be safe anyway
  Completer<dynamic> completer;

  // JS VM for running JS Git code
  JSContext jsContext;

  // Path to the repository location
  Uri repositoryUri;

  JsForGit(Uri repositoryUri) {
    this.repositoryUri = repositoryUri;
    configureJs();
  }

  JsForGit.forNewDirectory(Uri repositoryUri) {
    Directory.fromUri(repositoryUri).createSync(recursive: true);
    this.repositoryUri = repositoryUri;
    configureJs();
  }

  void configureJs() {
    jsContext = JSContext.createInGroup();
    ctxToJsForGit[jsContext.pointer] = this;

    // Set up self and window properties to point to global object
    jsContext.globalObject.setProperty(
        'window',
        jsContext.globalObject.toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    jsContext.globalObject.setProperty('self', jsContext.globalObject.toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);

    // Create an object to hold callbacks from JS to Dart
    JSObject flutterNamespace = JSObject.make(jsContext, JSClass(nullptr));
    jsContext.globalObject.setProperty('flutter', flutterNamespace.toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    // Set-up functions for calling from JS back into Dart for doing stuff
    flutterNamespace.setProperty(
        'httpFetch',
        JSObject.makeFunctionWithCallback(
                jsContext, 'httpFetch', Pointer.fromFunction(_jsHttpFetch))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    flutterNamespace.setProperty(
        'fsOperation',
        JSObject.makeFunctionWithCallback(
                jsContext, 'fsOperation', Pointer.fromFunction(_jsFsOperation))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    flutterNamespace.setProperty(
        'signalCompletion',
        JSObject.makeFunctionWithCallback(jsContext, 'signalCompletion',
                Pointer.fromFunction(_jsSignalCompletion))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    flutterNamespace.setProperty(
        'signalError',
        JSObject.makeFunctionWithCallback(
                jsContext, 'signalError', Pointer.fromFunction(_jsSignalError))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);

    // Load in the JS code for git
    synchronizer =
        rootBundle.loadString('assets/js/isomorphic-git.js').then((js) {
      print('1' + jsContext.evaluate(js).string);
      return rootBundle.loadString('assets/js/isomorphic-git-http.js');
    }).then((js) {
      print('2' + jsContext.evaluate(js).string);
      return rootBundle.loadString('assets/js/fs.js');
    }).then((js) {
      print('3' + jsContext.evaluate(js).string);
    });
  }

  void release() {
    ctxToJsForGit.remove(jsContext.pointer);
  }

  Future<dynamic> clone(String name, String url) {
    synchronizer = synchronizer.whenComplete(() {
      completer = new Completer<dynamic>();
      var fun = jsContext.evaluate("(function(name, url) {" +
          "git.clone({fs:fs, http:http, dir:'', url: url})" +
          ".then(function(val) {flutter.signalCompletion(val);})" +
          ".catch(function(err) { if (err instanceof Error) flutter.signalError(err.message); else flutter.signalError(err);});" +
          "})");
      var exception = JSValuePointer();
      fun.toObject().callAsFunction(
          JSObject(jsContext, nullptr),
          JSValuePointer.array([
            JSValue.makeString(jsContext, name),
            JSValue.makeString(jsContext, url)
          ]),
          exception: exception);
      return completer.future;
    });
    return synchronizer;
  }

  Future<dynamic> init(String name) {
    synchronizer = synchronizer.whenComplete(() {
      completer = new Completer<dynamic>();
      var fun = jsContext.evaluate("(function(name) {" +
          "git.init({fs:fs, dir:''})" +
          ".then(function(val) {flutter.signalCompletion(val);})" +
          ".catch(function(err) { if (err instanceof Error) flutter.signalError(err.message); else flutter.signalError(err);});" +
          "})");
      var exception = JSValuePointer();
      fun.toObject().callAsFunction(JSObject(jsContext, nullptr),
          JSValuePointer.array([JSValue.makeString(jsContext, name)]),
          exception: exception);
      return completer.future;
    });
    return synchronizer;
  }

  Pointer _signalCompletion(
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      completer.complete(JSValue(jsContext, arguments[0]).string);
    } else {
      completer.complete(null);
    }
    return nullptr;
  }

  Pointer _signalError(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      completer.completeError(JSValue(jsContext, arguments[0]).string);
    } else {
      completer.completeError(null);
    }
    return nullptr;
  }

  JSValue _createFsError(String msg, String errCode) {
    final err = jsContext.globalObject
        .getProperty('Error')
        .toObject()
        .callAsConstructor(
            JSValuePointer.array([JSValue.makeString(jsContext, msg)]));
    err.setProperty('code', JSValue.makeString(jsContext, errCode),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    return err.toValue();
  }

  void _callFsCallbackWithException(
      JSValue callback, String msg, String errCode) {
    var exception = JSValuePointer();
    callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
        JSValuePointer.array([_createFsError(msg, errCode)]),
        exception: exception);
  }

  final fsLogger = new Logger("plomgit.fs");

  Pointer _fsOperation(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    var operation = JSValue(jsContext, arguments[0]).string;
    switch (operation) {
      case 'readFile':
        var path = JSValue(jsContext, arguments[1]).string;
        var options = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        bool readString = false;
        if (options != null) {
          if (options.isString) {
            readString = true;
          } else if (options.isObject) {
            var encoding = options.toObject().getProperty("encoding");
            if (!encoding.isNull && !encoding.isUndefined) readString = true;
          }
        }
        File f = File.fromUri(
            repositoryUri.replace(path: repositoryUri.path + path));
        fsLogger.fine('readFile ' + path);
        var reader;
        if (readString) {
          reader = f.readAsString().then((str) {
            var exception = JSValuePointer();
            callback.toObject().callAsFunction(
                JSObject(jsContext, nullptr),
                JSValuePointer.array([
                  JSValue.makeNull(jsContext),
                  JSValue.makeString(jsContext, str)
                ]),
                exception: exception);
          });
        } else {
          reader = f.readAsBytes().then((bytes) {
            var exception = JSValuePointer();
            JSObject jsData = JSObject.makeTypedArray(jsContext,
                JSTypedArrayType.kJSTypedArrayTypeUint8Array, bytes.length,
                exception: exception);
            Pointer<Int8> intPointer =
                Pointer.fromAddress(jsData.arrayBufferBytes().pointer.address);
            intPointer
                .asTypedList(jsData.arrayBufferBytes().length)
                .setAll(0, bytes);
            callback.toObject().callAsFunction(
                JSObject(jsContext, nullptr),
                JSValuePointer.array(
                    [JSValue.makeNull(jsContext), jsData.toValue()]),
                exception: exception);
          });
        }
        reader.catchError((err) {
          _callFsCallbackWithException(callback, "Error when reading file", "");
        });
        return nullptr;
      case 'writeFile':
        var file = JSValue(jsContext, arguments[1]).string;
        var data = JSValue(jsContext, arguments[2]);
        var options = JSValue(jsContext, arguments[3]);
        var callback = JSValue(jsContext, arguments[4]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        File f = File.fromUri(
            repositoryUri.replace(path: repositoryUri.path + file));
        fsLogger.fine('writeFile ' + file);
        Future<File> writer;
        if (data.isString) {
          writer = f.writeAsString(data.string);
        } else {
          var typedArrayType = data.getTypedArrayType();
          if (typedArrayType == JSTypedArrayType.kJSTypedArrayTypeNone) {
            _callFsCallbackWithException(callback,
                "Unsupported value written to file", "ERR_INVALID_ARG_VALUE");
            return nullptr;
          }
          JSObject typedArrayObj = data.toObject();
          Bytes backingStore = typedArrayObj.typedArrayBytes();
          var offset = typedArrayObj.typedArrayByteOffset();
          var len = typedArrayObj.typedArrayByteLength();
          Pointer<Int8> intPointer =
              Pointer.fromAddress(backingStore.pointer.address);
          var dataList = intPointer.asTypedList(offset + len).sublist(offset);
          writer = f.writeAsBytes(dataList);
        }
        writer.then((f) {
          var exception = JSValuePointer();
          callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
              JSValuePointer.array([JSValue.makeNull(jsContext)]),
              exception: exception);
        }).catchError((err) {
          _callFsCallbackWithException(callback, "Error when writing file", "");
        });
        return nullptr;
      case 'unlink':
        var path = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        break;
      case 'readdir':
        var path = JSValue(jsContext, arguments[1]);
        var options = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        break;
      case 'mkdir':
        var path = JSValue(jsContext, arguments[1]).string;
        var mode = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = mode;
          mode = null;
        }
        fsLogger.fine('mkdir ' + path);
        Directory.fromUri(
                repositoryUri.replace(path: repositoryUri.path + path))
            .create()
            .then((dir) {
          // Note: in Flutter, creation will succeed if directory already exists
          var exception = JSValuePointer();
          callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
              JSValuePointer.array([JSValue.makeNull(jsContext)]),
              exception: exception);
        }).catchError((err) {
          // We can't tell the type of exception, so we'll just assume that
          // it's an exception for can't find parent directory
          _callFsCallbackWithException(
              callback,
              "Directory creation failed, possibly due to missing parent directory",
              "ENOENT");
        });
        return nullptr;
      case 'rmdir':
        var path = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        break;
      case 'stat':
        var path = JSValue(jsContext, arguments[1]).string;
        var options = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        File f = File.fromUri(
            repositoryUri.replace(path: repositoryUri.path + path));
        fsLogger.fine('stat ' + path);
        f.stat().then((filestat) {
          if (filestat.type == FileSystemEntityType.notFound) {
            _callFsCallbackWithException(callback, 'File not found', 'ENOENT');
          } else {
            var exception = JSValuePointer();
            var jsFileStat = jsContext.globalObject
                .getProperty('fs')
                .toObject()
                .getProperty('createFileStat')
                .toObject()
                .callAsFunction(
                    JSObject(jsContext, nullptr),
                    JSValuePointer.array([
                      JSValue.makeBoolean(jsContext,
                          filestat.type == FileSystemEntityType.directory),
                      JSValue.makeNumber(jsContext, filestat.size.toDouble()),
                      JSValue.makeNumber(jsContext,
                          filestat.modified.millisecondsSinceEpoch.toDouble())
                    ]),
                    exception: exception);
            callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
                JSValuePointer.array([JSValue.makeNull(jsContext), jsFileStat]),
                exception: exception);
          }
        });
        return nullptr;
      case 'lstat':
        var path = JSValue(jsContext, arguments[1]);
        var options = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        break;
      case 'readlink':
        var path = JSValue(jsContext, arguments[1]);
        var options = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        // Not implemented
        break;
      case 'symlink':
        var target = JSValue(jsContext, arguments[1]);
        var path = JSValue(jsContext, arguments[2]);
        var type = JSValue(jsContext, arguments[3]);
        var callback = JSValue(jsContext, arguments[4]);
        if (callback.isNull || callback.isUndefined) {
          callback = type;
          type = null;
        }
        // Not implemented
        break;
      case 'chmod':
        var path = JSValue(jsContext, arguments[1]);
        var mode = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        // Not used
        break;
      default:
        break;
    }
    // Throw an exception for all operations that we don't handle. Isomorphic-git
    // requires that we throw an actual Error object and not an arbitrary object
    // like a string.
    print('fsOperation ' + operation);
    exception[0] = _createFsError("Not supported", "").pointer;
    return nullptr;
  }
}

Pointer _jsSignalCompletion(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._signalCompletion(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsSignalError(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._signalError(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsFsOperation(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._fsOperation(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsHttpFetch(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return nullptr;
}
