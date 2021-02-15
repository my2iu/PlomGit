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
      _taskQueue.removeFirst().complete(event);
    });
  }

  Future<dynamic> queryFeatures() {
    _logger.finer("queryFeatures request");
    _isoChannel.sink.add([RequestType.queryFeatures.index]);
    Completer completer = new Completer();
    _taskQueue.add(completer);
    return completer.future;
  }

  Future<dynamic> initRepository(String dir) {
    _logger.finer("initRepository request");
    _isoChannel.sink.add([RequestType.initRepository.index, dir]);
    Completer completer = new Completer();
    _taskQueue.add(completer);
    return completer.future;
  }

  static void isolateMain(SendPort sendPort) {
    Libgit2.init();

    IsolateChannel channel = IsolateChannel.connectSend(sendPort);
    channel.stream.listen((event) {
      // Since we don't compile libgit2 to be thread-safe, don't return
      // from a listen handler unless a libgit2 request has been completely
      // processed (which is normally the case since libgit2 is a synchronous
      // blocking api). Otherwise, a second event might get dispatched
      // asynchronously while the previous one is still being executed.
      RequestType eventType = RequestType.values[event[0] as int];
      switch (eventType) {
        case RequestType.queryFeatures:
          channel.sink.add(Libgit2.queryFeatures());
          break;
        case RequestType.initRepository:
          Libgit2.initRepository(event[1]);
          channel.sink.add("");
          break;
      }
    });
  }
}

/// Identifies the type of request/operation being sent to the git isolate
enum RequestType { queryFeatures, initRepository }
