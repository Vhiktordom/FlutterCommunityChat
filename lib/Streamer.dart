
import 'dart:async';

import 'package:chatter/Model.dart';


// STEP1:  Stream setup
class StreamSocket {
  final _socketResponse = StreamController<ChatModel>();

  void Function(ChatModel) get addResponse => _socketResponse.sink.add;

  Stream<ChatModel> get getResponse => _socketResponse.stream;

  void dispose() {
    _socketResponse.close();
  }
}