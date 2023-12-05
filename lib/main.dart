import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:f_websocker/constants.dart';
import 'package:f_websocker/handler_functions.dart';

class WebSocketDemo extends StatefulWidget {
  @override
  _WebSocketDemoState createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  late WebSocketChannel channel;
  late StreamSubscription<dynamic> subscription;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final StreamController<Map<String, dynamic>> _streamController =
      StreamController<Map<String, dynamic>>.broadcast();

  String url = '';
  static List<Map<String, String>> _messages = [];
  bool isSendButtonEnabled = false;
  bool isNameAvailable = false;

  Future<void> _showNameInputDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter your name'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            onChanged: (text) {
              setState(() {
                isNameAvailable = text.isNotEmpty;
              });
            },
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                setState(() {
                  ConstantsClass.username = _nameController.text;
                });
                _nameController.clear();
                connect();
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    List<String> dataList = HandlerFunctions.buildUrl();
    url = '${dataList[0]}?header=${dataList[1]}&payload=${dataList[2]}';
    Future.delayed(Duration.zero, () {
      _showNameInputDialog();
    });
  }

  void connect() {
    channel = WebSocketChannel.connect(
      Uri.parse(url),
      protocols: ['graphql-ws'],
    );

    // Start the connection
    HandlerFunctions.sendConnectionInit(channel);
    subscription = channel.stream.listen((dynamic message) {
      print('Received raw message: $message');
      handleWebSocketData(message);
    });
  }

  void handleWebSocketData(dynamic message) {
    print('Handling WebSocket data: $message');
    Map<String, dynamic> data = json.decode(message);
    if (data.containsKey('payload') &&
        data['payload'].containsKey('data') &&
        data['payload']['data'].containsKey('newMessage')) {
      Map<String, String> newData = {
        'content': data['payload']['data']['newMessage']['content'],
        'senderName': data['payload']['data']['newMessage']['senderName'],
        'id': data['payload']['data']['newMessage']['id'],
      };
      if (_messages.contains(newData)) {
        return;
      } else {
        setState(() {
          _messages.add(newData);
        });
      }
    }
    switch (data['type']) {
      case 'connection_ack':
        // Connection acknowledged, you can now send subscriptions
        HandlerFunctions.sendSubscription(channel);
        break;
      case 'start_ack':
        // Subscription acknowledged, you can start processing data
        print('Subscription acknowledged, start processing data...');
        break;
      case 'data':
        // Process the received data
        HandlerFunctions.processSubscriptionData(data);
        break;
      case 'complete':
        // Subscription complete, no more messages for this subscription
        print('Subscription complete, no more messages for this subscription.');
        break;
      case 'error':
        // Handle error messages
        HandlerFunctions.handleError(data['payload']);
        break;
      default:
        // Handle other message types if needed
        break;
    }
  }

  @override
  void dispose() {
    // Disconnect and clean up resources
    subscription.cancel();
    channel.sink.close();
    // Close the stream controller
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                _showNameInputDialog();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
          title: const Text('EduChat'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Text(
                          _messages[index]["senderName"]!.substring(0, 2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(_messages[index]["senderName"]!),
                      subtitle: Text(_messages[index]["content"]!),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          HandlerFunctions.httpMutation(
                            operationType: 'delete',
                            messageId: _messages[index]["id"]!,
                          );
                          setState(() {
                            _messages.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(2.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (text) {
                setState(() {
                  isSendButtonEnabled = text.isNotEmpty;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Type a message...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: isSendButtonEnabled
                ? () {
                    HandlerFunctions.httpMutation(
                      operationType: 'create',
                      messageContent: _messageController.text,
                    );
                    _messageController.clear();
                    setState(() {
                      isSendButtonEnabled = false;
                    });
                    print("The data in the list is: $_messages");
                  }
                : null, // Set onPressed to null if button is disabled
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: WebSocketDemo(),
  ));
}
