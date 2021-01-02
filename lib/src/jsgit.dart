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
      print(jsContext.evaluate(js).string);
      return rootBundle.loadString('assets/js/isomorphic-git-http.js');
    }).then((js) {
      print(jsContext.evaluate(js).string);
      print(jsContext.evaluate("alert('hello'+git)").string);
      jsContext.release();
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
              "git.clone({fs:null, http:http, dir:'', url:'https://example.com'})" +
                  ".then(function(val) {flutter.signalCompletion(val);})" +
                  ".catch(function(err) {flutter.signalError(err);});")
          .string);
      print(jsContext.exception.getValue(jsContext).string);
      print('end clone');
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
    if (argumentCount > 1) {
      print('completer error');
      completer.completeError(JSValue(jsContext, arguments[1]).string);
    } else if (argumentCount > 0) {
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
      print('completer nothing');
      completer.completeError(null);
    }
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

Pointer _jsHttpFetch(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return nullptr;
}
