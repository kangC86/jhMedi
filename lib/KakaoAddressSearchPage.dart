import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KakaoAddressSearchPage extends StatefulWidget {
  const KakaoAddressSearchPage({super.key});

  @override
  State<KakaoAddressSearchPage> createState() => _KakaoAddressSearchPageState();
}

class _KakaoAddressSearchPageState extends State<KakaoAddressSearchPage> {
  late final WebViewController _webViewController;

  // HTML 코드 (카카오 주소 API)
  final String _html = '''
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>주소 검색</title>
      <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
    </head>
    <body>
      <script>
        new daum.Postcode({
          oncomplete: function(data) {
            let fullAddr = data.address;
            if (window.AddressReceiver) {
              AddressReceiver.postMessage(fullAddr);
            }
          }
        }).open();
      </script>
    </body>
  </html>
  ''';

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AddressReceiver',
        onMessageReceived: (message) {
          Navigator.pop(context, message.message); // Flutter로 주소 전달
        },
      )
      ..loadHtmlString(_html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주소 검색')),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
