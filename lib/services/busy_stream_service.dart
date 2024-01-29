import 'dart:async';

class BusyStreamService {

  final StreamController<bool> streamController = StreamController.broadcast();
  Stream<bool> get busyStream => streamController.stream;

  setBusy(bool busy) {
    streamController.sink.add(busy);
  }
}
