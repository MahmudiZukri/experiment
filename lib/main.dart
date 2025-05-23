import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FirstPage(),
    );
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewPage(treatmentId: '19'),
              ),
            );
          },
          child: const Text('Open WebView'),
        ),
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String treatmentId;
  const WebViewPage({super.key, required this.treatmentId});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..setNavigationDelegate(
      //   NavigationDelegate(
      //     onPageFinished: (String url) {
      //       _controller.runJavaScript(
      //           'window.receiveFromFlutter("${widget.treatmentId}");');
      //     },
      //   ),
      // )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          debugPrint("Received from WebView: ${message.message}");
          if (message.message == "goBack") {
            if (await _controller.canGoBack()) {
              debugPrint('asdasd 777');
              _controller.goBack();
            } else {
              if (mounted) Navigator.pop(context);
            }
          } else {
            // Handle other messages, e.g., note submission
            debugPrint("Message: ${message.message} asdasd");
          }
        },
      )
      ..loadRequest(
        Uri.parse('http://172.16.5.38:3004/portal/treatment'),
      );
  }

  Future<bool> _handleBackPressed() async {
    // This will call JS window.goBackInApp() from Flutter
    await _controller.runJavaScriptReturningResult('window.goBackInApp()');

    debugPrint('asdasd 5555');
    return false; // Prevent Flutter from popping until JS says so
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        debugPrint('asdasd');
        if (didPop == false) {
          debugPrint('asdasd 444');
          _handleBackPressed();
        }
      },
      child: Scaffold(
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
