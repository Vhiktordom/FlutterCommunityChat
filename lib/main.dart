import 'dart:async';
import 'dart:convert';
import 'package:chatter/Model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';
import 'Message.dart';
StreamController<ChatModel> streamSocket = StreamController<ChatModel>();

final tokenizer =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NGIwNjZhOWQzYWMxMjRhN2JkZGY3YzAiLCJlbWFpbCI6Imh1Ym9mZGF0YUBnbWFpbC5jb20iLCJyb2xlcyI6WyJpbnZlc3RvciIsImFkbWluIl0sImlhdCI6MTY5MjEzMjUzNSwiZXhwIjoxNjkyMTM2MTM1LCJpc3MiOiJwZXJyeWJvdCJ9.RN28o_C0SxmUO40FBehtmVEcUxm_wkumjKTvqL_b0Qk';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket socket;
  TextEditingController _messageController = TextEditingController();
  // List<String> messages = [];
  List<ChatModel> messages = [];

  @override
  void initState() {
    super.initState();

    socket = IO.io(
        'ws://routes.perrycoop.com',
        OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            // .setExtraHeaders({'token': accessToken}) // optional
            .setAuth(({'token': "$tokenizer"}))
            .build());

    socket.onConnect((data) {
      print('connected successful');
      socket.emit('group:join', {"group": "64d17e2348899e11c17ac2f8"});
      socket.on('group:joined', (data) {
        // print(data);
      });

      socket.emit('message:load', {"group": "64d17e2348899e11c17ac2f8"});

      socket.on('message:loaded', (data) => print('message loaded:$data'));
      // socket.on('message:loaded',
      //         (data) => streamSocket.addResponse(data));
      socket.on('message:loaded', (data) {
        setState(() {
          List<dynamic> dataList = data as List<dynamic>;
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              ChatModel newMessage = ChatModel.fromJson(item);
              messages.add(newMessage);
            }
          }
        });
        List<dynamic> messageList = data;

        for (var jsonData in messageList) {
          ChatModel newMessage = ChatModel.fromJson(jsonData);
          streamSocket.add(newMessage);
        }
      });
    });
    socket.onConnectError((data) => print('Connect error: $data'));
    socket
        .onDisconnect((data) => print('Socket.IO server disconnected: $data'));
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      // Send message to the server
      socket.emit('message:send', {
        "group": "64d17e2348899e11c17ac2f8",
        "content": _messageController.text
      });

      socket.emit('message:load', {
        "group": "64d17e2348899e11c17ac2f8",
      });

      socket.on('message:recieved', (data) {

        List<dynamic> dataList = data as List<dynamic>;
        for (var item in dataList) {
          if (item is Map<String, dynamic>) {
            ChatModel newMessage = ChatModel.fromJson(item);
            messages.add(newMessage);
          }
        }
      });


      _messageController.clear();
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  Uint8List cleanAndDecodeBase64Image(String base64Image) {
    String cleanedBase64 = base64Image.replaceAll(RegExp(r'[\r\n]'), '');
    String withoutPrefix = cleanedBase64.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
    return base64.decode(withoutPrefix);
  }



  Widget _buildMessageItem(message) {

    Uint8List imageBytes = cleanAndDecodeBase64Image(message.picture);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: Image.memory(imageBytes).image,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${message.firstname} ${message.lastname}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(10),
                child: Text(message.content),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: streamSocket.stream, // Replace with your message stream
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  print("Connection State");
                  print(snapshot.connectionState);
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageItem(message);
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );


  }
}
