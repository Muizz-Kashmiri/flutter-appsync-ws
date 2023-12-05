import 'dart:convert';

import 'package:f_websocker/constants.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class HandlerFunctions {
  static buildUrl() {
    final Map<String, dynamic> payload = {};
    final String base64ApiHeader =
        base64Encode(utf8.encode(jsonEncode(ConstantsClass.apiHeader)));
    final String base64Payload = base64Encode(utf8.encode(jsonEncode(payload)));
    return [
      ConstantsClass.wss,
      base64ApiHeader,
      base64Payload,
    ];
  }

  static void sendMessage(
      WebSocketChannel channel, Map<String, dynamic> message) {
    if (channel.sink != null) {
      print('Sending message: $message');
      channel.sink.add(json.encode(message));
    }
  }

  static void handleError(Map<String, dynamic> errorPayload) {
    // Handle errors
    List<dynamic> errors = errorPayload['errors'];
    for (var error in errors) {
      String errorType = error['errorType'];
      String errorMessage = error['message'];
      print('$errorType: $errorMessage');
    }
  }

  static void sendConnectionInit(WebSocketChannel channel) {
    print('Sending connection_init message...');
    HandlerFunctions.sendMessage(channel, {
      'type': 'connection_init',
    });
  }

  static void processSubscriptionData(Map<String, dynamic> data) {
    print('Processing subscription data: $data');

    if (data['type'] == 'data' && data.containsKey('payload')) {
      // Process the received data
      Map<String, dynamic> payload = data['payload'];
      Map<String, dynamic> newMessage = payload['data']['newMessage'];
    } else if (data['type'] == 'complete') {
      print('Subscription complete, no more messages for this subscription.');
    }
  }

  static void sendSubscription(WebSocketChannel channel) {
    print('Sending subscription message...');
    sendMessage(channel, {
      "id": "1",
      "payload": {
        "data":
            "{\"query\":\"subscription MySub {\\n newMessage {\\n content\\n id\\n senderName\\n }\\n }\",\"variables\":{}}",
        "extensions": {
          "authorization": {
            "x-api-key": ConstantsClass.apiHeader['x-api-key'],
            "host": ConstantsClass.apiHeader['host'],
          }
        }
      },
      "type": "start"
    });
  }

  static Future<void> httpMutation({
    required String operationType, // 'create' or 'delete'
    String? messageId, // Only needed for delete operation
    String? messageContent, // Only needed for create operation
  }) async {
    const String apiUrl = ConstantsClass
        .graphQlUrlEndpoint; // Replace with your actual API endpoint

    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ConstantsClass.apiHeader['x-api-key'] ?? '',
        },
        body: jsonEncode({
          'query': '''
          mutation MyMutation {
            ${operationType == 'create' ? 'createMessage' : 'deleteMessage'}(
              input: {
                ${operationType == 'create' ? 'content: "$messageContent",' : ''}
                ${operationType == 'delete' ? 'id: "$messageId",' : ''}
                senderName: "${ConstantsClass.username}"
              }
            ) {
              content
              id
              senderName
            }
          }
        ''',
        }),
      );

      print('HTTP $operationType Mutation Response: ${response.body}');
      // Process the response as needed
    } catch (error) {
      print('HTTP $operationType Mutation Error: $error');
      // Handle the error as needed
    }
  }
}
