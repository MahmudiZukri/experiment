import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp(
    treatmentId: '19',
  ));
}

class MyApp extends StatefulWidget {
  final String treatmentId; // data you want to pass

  const MyApp({super.key, required this.treatmentId});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://172.16.5.38:3004/portal/treatment"))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("Message from WebView: ${message.message}");
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          // Once the page is loaded, send data
          _controller.runJavaScript(
            'window.receiveFromFlutter("${widget.treatmentId}");',
          );
        },
      ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Treatment WebView')),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
