import 'dart:convert';
import 'package:http/http.dart';

class AlertRepository {
  static String _slackUrl;

  Future<void> send(
    String message,
    String description,
  ) async {
    String body = json.encode({
      'blocks': [
        {
          'type': 'section',
          'text': {
            'type': 'mrkdwn',
            'text': message,
          }
        },
        {
          'type': 'context',
          'elements': [
            {
              'type': 'plain_text',
              'text': description
            }
          ]
        }
      ],
    });

    Response response = await post(
      _slackUrl,
      headers: { 'content-type': 'application/json' },
      body: body,
    );

    if (response.statusCode != 200) {
      throw new Exception('アラートの送信に失敗しました: ${response.statusCode}');
    }
  }

  set slackUrl(String slackUrl) {
    _slackUrl = slackUrl;
  }
}