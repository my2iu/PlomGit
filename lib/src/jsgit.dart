import 'dart:async';
import 'dart:ffi';
import 'package:flutter_jscore/flutter_jscore.dart';
import 'package:flutter_jscore/binding/js_context_ref.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  JSContext jsContext;
  JsForGit() {
    jsContext = JSContext.createInGroup();
    ctxToJsForGit[jsContext.pointer] = this;
    print(jsContext.pointer);
    print(jsContext.group.pointer);

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

  Future<dynamic> clone() {
    synchronizer = synchronizer.whenComplete(() {
      completer = new Completer<dynamic>();

      print('start clone');
      print(jsContext.exception.getValue(jsContext).string);
      print(jsContext
          .evaluate(
              "git.clone({fs:fs, http:http, dir:'', url:'https://example.com'})" +
                  ".then(function(val) {flutter.signalCompletion(val);})" +
                  ".catch(function(err) {flutter.signalError(err);});")
          .string);
      print(jsContext.exception.getValue(jsContext).string);
      print('end clone');
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
          ".catch(function(err) {flutter.signalError(err);});" +
          "})");
      var exception = JSValuePointer();
      fun.toObject().callAsFunction(JSObject(jsContext, nullptr),
          JSValuePointer.array([JSValue.makeString(jsContext, name)]),
          exception: exception);
      print(exception.getValue(jsContext).string);
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
      print('completer ok');
      completer.complete(JSValue(jsContext, arguments[0]).string);
    } else {
      print('completer nothing');
      completer.complete(null);
    }
    return nullptr;
  }

  Pointer _signalError(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      print('completer error');
      completer.completeError(JSValue(jsContext, arguments[0]).string);
    } else {
      print('completer error nothing');
      completer.completeError(null);
    }
    return nullptr;
  }

  Pointer _fsOperation(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    var operation = JSValue(jsContext, arguments[0]).string;
    print(operation);
    print(exception);
    switch (operation) {
      case 'readFile':
        var path = JSValue(jsContext, arguments[0]);
        var options = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        break;
      case 'writeFile':
        var file = JSValue(jsContext, arguments[0]);
        var data = JSValue(jsContext, arguments[1]);
        var options = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        break;
      case 'unlink':
        var path = JSValue(jsContext, arguments[0]);
        var callback = JSValue(jsContext, arguments[1]);
        break;
      case 'readdir':
        var path = JSValue(jsContext, arguments[0]);
        var options = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        break;
      case 'mkdir':
        var path = JSValue(jsContext, arguments[0]);
        var mode = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        if (callback.isNull || callback.isUndefined) {
          callback = mode;
          mode = null;
        }
        break;
      case 'rmdir':
        var path = JSValue(jsContext, arguments[0]);
        var callback = JSValue(jsContext, arguments[1]);
        break;
      case 'stat':
        var path = JSValue(jsContext, arguments[0]);
        var options = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        break;
      case 'lstat':
        var path = JSValue(jsContext, arguments[0]);
        var options = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        break;
      case 'readlink':
        var path = JSValue(jsContext, arguments[0]);
        var options = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        if (callback.isNull || callback.isUndefined) {
          callback = options;
          options = null;
        }
        // Not implemented
        break;
      case 'symlink':
        var target = JSValue(jsContext, arguments[0]);
        var path = JSValue(jsContext, arguments[1]);
        var type = JSValue(jsContext, arguments[2]);
        var callback = JSValue(jsContext, arguments[3]);
        if (callback.isNull || callback.isUndefined) {
          callback = type;
          type = null;
        }
        // Not implemented
        break;
      case 'chmod':
        var path = JSValue(jsContext, arguments[0]);
        var mode = JSValue(jsContext, arguments[1]);
        var callback = JSValue(jsContext, arguments[2]);
        // Not used
        break;
      default:
        (exception[0] as Pointer<Pointer>)[0] = JSValuePointer.array(
            [JSValue.makeString(jsContext, "Not supported")]).pointer;
    }
    (exception[0] as Pointer<Pointer>)[0] =
        JSValuePointer.array([JSValue.makeString(jsContext, "Not supported")])
            .pointer;
    return nullptr;
  }
}

Pointer _jsSignalCompletion(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  print('completer before');
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._signalCompletion(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsSignalError(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  print('completer before');
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._signalError(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsFsOperation(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  print('fsOperation');
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._fsOperation(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsHttpFetch(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return nullptr;
}
