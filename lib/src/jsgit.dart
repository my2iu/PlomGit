import 'dart:ffi';
import 'package:flutter_jscore/flutter_jscore.dart';
import 'package:flutter_jscore/binding/js_context_ref.dart';
import 'package:flutter/services.dart' show rootBundle;

class JsForGit {
  static Map<Pointer, JsForGit> ctxToJsForGit = Map<Pointer, JsForGit>();

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

    // Set-up functions for calling from JS back into Dart for doing stuff
    jsContext.globalObject.setProperty(
        'alert',
        JSObject.makeFunctionWithCallback(
                jsContext, 'alert', Pointer.fromFunction(_jsAlert))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);

    // Load in the JS code for git
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

  Pointer _alert(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    print('2');
    String msg = 'No Message';
    if (argumentCount != 0) {
      msg = '';
      for (int i = 0; i < argumentCount; i++) {
        if (i != 0) {
          msg += '\n';
        }
        var jsValueRef = arguments[i];
        msg += JSValue(jsContext, jsValueRef).string;
      }
    }
    print(msg);
    // showDialog(
    //     context: context,
    //     builder: (context) {
    //       return AlertDialog(
    //         title: Text('Alert'),
    //         content: Text(msg),
    //       );
    //     });
    return nullptr;
  }
}

Pointer _jsAlert(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._alert(function, thisObject, argumentCount, arguments, exception);
}
