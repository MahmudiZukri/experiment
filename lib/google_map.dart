import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class GoggleMap extends StatefulWidget {
  const GoggleMap({super.key});

  @override
  State<GoggleMap> createState() => _GoggleMapState();
}

class _GoggleMapState extends State<GoggleMap> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  int loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    // InAppWebViewController.setWebContentsDebuggingEnabled(true);
    getLocation();
  }

  void getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);

    debugPrint(
        "Location: ${position.latitude}, ${position.longitude} ||| asdasd");
  }

  Uri? _extractFallbackUrl(String intentUrl) {
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
      appBar: AppBar(title: const Text("WebView with Location")),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: Uri.parse('https://www.google.com/maps'),
            ),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
                geolocationEnabled: true,
              ),
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
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;

              if (uri.scheme == 'intent') {
                final fallbackUri = _extractFallbackUrl(uri.toString());
                if (fallbackUri != null && await canLaunchUrl(fallbackUri)) {
                  await launchUrl(fallbackUri,
                      mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.CANCEL;
              }

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
            onLoadError: (controller, url, code, message) {
              debugPrint("WebView load error: $code $message");
            },
            onLoadHttpError: (controller, url, statusCode, description) {
              debugPrint("HTTP error: $statusCode $description");
            },
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
