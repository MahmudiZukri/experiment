import 'package:experiment/google_map.dart';
import 'package:experiment/map_page.dart';
import 'package:experiment/mri_business.dart';
import 'package:experiment/osm_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebViewPage(treatmentId: '19'),
                  ),
                );
              },
              child: const Text('webview_flutter'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapPage(),
                  ),
                );
              },
              child: const Text('flutter_inappwebview'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OsmPage(),
                  ),
                );
              },
              child: const Text('osm'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GoggleMap(),
                  ),
                );
              },
              child: const Text('google map'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MriBusinessMap(),
                  ),
                );
              },
              child: const Text('mri business'),
            ),
          ],
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
        // Uri.parse('http://172.16.5.38:3004/portal/treatment'),
        Uri.parse(
            'https://emerging-wired-killdeer.ngrok-free.app/portal/treatment'),
      );

    final platformController = _controller.platform;

    // request location permission
    Permission.locationWhenInUse.request();

    if (platformController is AndroidWebViewController) {
      debugPrint('asdasd 123');
      platformController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          debugPrint('asdasd 123123');

          // request location permission
          final locationPermissionStatus =
              await Permission.locationWhenInUse.request();

          // return the response
          return GeolocationPermissionsResponse(
            allow: locationPermissionStatus == PermissionStatus.granted,
            retain: false,
          );
        },
      );
    }

    getLocation();
  }

  void getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permession are permanently denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse &&
          permission == LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);

    debugPrint(permission.toString());
    debugPrint(position.toString());
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
        appBar: AppBar(title: const Text("webview_flutter")),
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
