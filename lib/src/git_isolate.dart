import 'dart:async';
import 'dart:isolate';
import 'dart:collection' show Queue;
import 'package:libgit2/libgit2.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:stream_channel/isolate_channel.dart';

/// We use libgit2 for handling git, which is a blocking api, so we need
/// to run it in a separate isolate. We also compile libgit2 for
/// single-threaded use only, so we only have a singleton isolate that
/// serializes all git operations.
class GitIsolate {
  // Singleton instance
  static final GitIsolate instance = GitIsolate._create();

  final _logger = new Logger("plomgit.gitisolate");

  // For any request send to the isolate, there is a corresponding task in
  // the taskQueue with a Completer that will handle the response to the
  // request
  Queue<Completer<dynamic>> _taskQueue = new Queue();

  // All of this state is stored in the main isolate. The state of the
  // git isolate is stored entirely in isolateMain(). Currently, the
  // isolate expects all requests to be a list. list[0] should be a string
  // with the type of the event. The rest of the list can be
  // context-specific parameters for the event.
  IsolateChannel<dynamic> _isoChannel;

  // Private constructor
  GitIsolate._create() {
    ReceivePort receivePort = new ReceivePort();
    Isolate.spawn(isolateMain, receivePort.sendPort);
    _isoChannel = IsolateChannel<dynamic>.connectReceive(receivePort);

    // Listen for responses from the isolate
    _isoChannel.stream.listen((event) {
      _logger.finest("received response " + event.toString());
      if (event[0] == 0) {
        _taskQueue.removeFirst().complete(event[1]);
      } else if (event[0] == -1) {
        _taskQueue.removeFirst().completeError(
            Libgit2Exception(event[1][0], event[1][1], event[1][2]));
      } else {
        _taskQueue.removeFirst().completeError(event[1]);
      }
    });
  }

  // Sends a request for a git operation to the git isolate
  Future<dynamic> _sendRequest(RequestType request, [List params]) {
    List req;
    if (params != null) {
      req = [request.index];
      req.addAll(params);
    } else {
      req = [request.index];
    }
    _logger.finer("$request request");
    _isoChannel.sink.add(req);
    Completer completer = new Completer();
    _taskQueue.add(completer);
    return completer.future;
  }

  // API of different git operations that can be performed
  Future<dynamic> queryFeatures() {
    return _sendRequest(RequestType.queryFeatures);
  }

  Future<dynamic> initRepository(String dir) {
    return _sendRequest(RequestType.initRepository, [dir]);
  }

  Future<dynamic> clone(String url, String dir) {
    return _sendRequest(RequestType.clone, [url, dir]);
  }

  Future<dynamic> listRemotes(String dir) {
    return _sendRequest(RequestType.listRemotes, [dir]);
  }

  // Makes a response to a request from the isolate back to the requester
  static void _isolateResponse(IsolateChannel channel, dynamic data) {
    channel.sink.add([0, data]);
  }

  // Code for the isolate. It waits for requests for git operations to arrive,
  // performs them and then sends back the response.
  static void isolateMain(SendPort sendPort) {
    Libgit2.init();

    IsolateChannel channel = IsolateChannel.connectSend(sendPort);
    channel.stream.listen((event) {
      // Since we don't compile libgit2 to be thread-safe, don't return
      // from a listen handler unless a libgit2 request has been completely
      // processed (which is normally the case since libgit2 is a synchronous
      // blocking api). Otherwise, a second event might get dispatched
      // asynchronously while the previous one is still being executed.
      try {
        RequestType eventType = RequestType.values[event[0] as int];
        switch (eventType) {
          case RequestType.queryFeatures:
            _isolateResponse(channel, Libgit2.queryFeatures());
            break;
          case RequestType.initRepository:
            Libgit2.initRepository(event[1]);
            _isolateResponse(channel, "");
            break;
          case RequestType.clone:
            Libgit2.clone(event[1], event[2]);
            _isolateResponse(channel, "");
            break;
          case RequestType.listRemotes:
            _isolateResponse(channel, Libgit2.remoteList(event[1]));
            break;
        }
      } on Libgit2Exception catch (e) {
        // Automatically serialize libgit2 errors
        channel.sink.add([
          -1,
          [e.errorCode, e.message, e.klass]
        ]);
      } catch (e) {
        channel.sink.add([-2, e.toString()]);
      }
    });
  }
}

/// Identifies the type of request/operation being sent to the git isolate
enum RequestType { queryFeatures, initRepository, clone, listRemotes }
