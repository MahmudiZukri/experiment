import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  int loadingPercentage = 0;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  @override
  void initState() {
    super.initState();
    // _requestAndLogPermissions();
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

  Future<void> _requestAndLogPermissions() async {
    final status = await Permission.location.request();
    if (!mounted) return;

    if (status.isGranted) {
      print('Location permission granted');
    } else if (status.isPermanentlyDenied) {
      print('Location permission permanently denied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Location permission is permanently denied. Please enable it in app settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    } else {
      print('Location permission denied');
    }
  }

  Uri? _extractFallbackUrl(String intentUrl) {
    // Extract fallback url from intent:// URL
    const fallbackKey = 'S.browser_fallback_url=';
    final startIndex = intentUrl.indexOf(fallbackKey);
    if (startIndex == -1) return null;

    final substring = intentUrl.substring(startIndex + fallbackKey.length);
    final endIndex = substring.indexOf(';');
    if (endIndex == -1) return null;

    final encodedUrl = substring.substring(0, endIndex);
    final decodedUrl = Uri.decodeComponent(encodedUrl);
    return Uri.tryParse(decodedUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Treatment WebView")),
      body: Stack(
        children: [
          InAppWebView(
            // gestureRecognizers: gestureRecognizers,
            initialUrlRequest: URLRequest(
              // url: Uri.parse('https://google.com/maps'),
              url: Uri.parse(
                  'https://emerging-wired-killdeer.ngrok-free.app/portal/treatment/treatment-detail/tracking'),
            ),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
              ),
              android: AndroidInAppWebViewOptions(
                  useHybridComposition: true,
                  geolocationEnabled: true,
                  useWideViewPort: true),
              ios: IOSInAppWebViewOptions(
                allowsInlineMediaPlayback: true,
              ),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            androidOnGeolocationPermissionsShowPrompt:
                (controller, origin) async {
              return GeolocationPermissionShowPromptResponse(
                origin: origin,
                allow: true,
                retain: true,
              );
            },
            androidOnPermissionRequest: (controller, origin, resources) async {
              return PermissionRequestResponse(
                resources: resources,
                action: PermissionRequestResponseAction.GRANT,
              );
            },
            onLoadError: (controller, url, code, message) {
              debugPrint('onLoadError: $url, $code, $message');
            },
            onLoadHttpError: (controller, url, statusCode, description) {
              debugPrint('onLoadHttpError: $url, $statusCode, $description');
            },

            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;

              debugPrint('Navigating to: $uri');

              if (uri.scheme == 'intent') {
                final intentUrl = uri.toString();

                // 1. Try fallback URL
                final fallbackUri = _extractFallbackUrl(intentUrl);
                if (fallbackUri != null && await canLaunchUrl(fallbackUri)) {
                  await launchUrl(fallbackUri,
                      mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }

                // 2. Try launching the intent URI itself
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }

                // 3. Cancel loading if nothing works
                return NavigationActionPolicy.CANCEL;
              }

              // Handle other non-http(s) schemes by launching externally if possible
              if (!['http', 'https', 'file', 'about', 'data']
                  .contains(uri.scheme)) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }
              }

              return NavigationActionPolicy.ALLOW;
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                loadingPercentage = progress;
                isLoading = progress < 100;
              });
            },
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
