import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:we2gether/web_notification.dart';
import 'package:we2gether/webview_controller.dart';

import '../main.dart';

class WebViewScreen extends GetView<WebViewController> {
  // TODO on exit show logout Screen to remove shared pref data //in old this is done
  const WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
//to refresh use controller.webViewController!.reload();
    // Future goback() async {
    //   if (await controller.webViewController!.canGoBack()) {
    //     controller.webViewController!.goBack();
    //   }
    // }

    Future<bool> onWillPop() async {
      DateTime now = DateTime.now();
      if (await controller.webViewController!.canGoBack()) {
        controller.webViewController!.goBack();
        return Future.value(false);
      } else {
        if (controller.currentBackPressTime == null ||
            now.difference(controller.currentBackPressTime!) >
                const Duration(seconds: 2)) {
          controller.currentBackPressTime = now;
          Get.snackbar("Exit", "Double tap to close app",
              backgroundColor: Colors.white,
              snackPosition: SnackPosition.BOTTOM);
          return Future.value(false);
        }
        return Future.value(true);
      }
    }

    return Scaffold(
        body: WillPopScope(
      onWillPop: () => onWillPop(),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: Stack(
              children: [
                InAppWebView(
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform:
                        InAppWebViewOptions(useOnDownloadStart: true),
                  ),
                  // initialSettings:InAppWebViewSettings(),
                  pullToRefreshController: controller.refreshController,
                  onLoadStop: (onLoadStopcontroller, url) {
                    controller.isLoading.value = false;
                    controller.refreshController?.endRefreshing();
                  },
                  onProgressChanged: (onProgressChangedcontroller, progress) {
                    if (progress == 100) {
                      controller.refreshController?.endRefreshing();
                    }
                    controller.progress.value = progress / 100;
                  },
                  onLoadStart: (loadcontroller, url) {
                    controller.isLoading.value = true;
                    controller.currentUrl?.value = url.toString();
                  },
                  shouldOverrideUrlLoading: (shouldOverrideUrlLoadingcontroller,
                      navigationAction) async {
                    var uri = navigationAction.request.url!;

                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about"
                    ].contains(uri.scheme)) {
                      if (await canLaunchUrl(uri)) {
                        // Launch the App
                        await launchUrl(
                          uri,
                        );
                        // and cancel the request
                        return NavigationActionPolicy.CANCEL;
                      }
                    }
                    /////////////////

                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.iOS) {
                      final shouldPerformDownload =
                          navigationAction.shouldPerformDownload ?? false;
                      final url = navigationAction.request.url;
                      if (shouldPerformDownload && url != null) {
                        await controller.downloadFile(url.toString());
                        return NavigationActionPolicy.DOWNLOAD;
                      }
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onDownloadStart: (controller, url) async {
                    final taskId = await FlutterDownloader.enqueue(
                      url: url.toString(),
                      savedDir: (await getExternalStorageDirectory())!.path,
                      showNotification:
                          true, // show download progress in status bar (for Android)
                      openFileFromNotification:
                          true, // click on notification to open downloaded file (for Android)
                    );
                  },
//                   onReceivedServerTrustAuthRequest: (controller, challenge) async {
//   return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
// },
                  onDownloadStartRequest: (onDownloadStartRequestcontroller,
                      downloadStartRequest) async {
                    await controller.downloadFile(
                        downloadStartRequest.url.toString(),
                        downloadStartRequest.suggestedFilename);
                  },
                  initialUserScripts: UnmodifiableListView(userScripts),
                  onWebViewCreated: (webviewController) {
                    controller.webViewController = webviewController;
                    controller.webNotificationController =
                        WebNotificationController(webviewController);
                  },
                  initialSettings: InAppWebViewSettings(
                    disableDefaultErrorPage: true,
                    iframeAllow: "camera; microphone",
                    iframeAllowFullscreen: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    contentBlockers: controller.contentBlockerEnabled.value
                        ? controller.contentBlockers
                        : [],
                  ),
                  onReceivedHttpError: (onReceivedHttpErrorcontroller, request,
                      errorResponse) async {
                    // Handle HTTP errors here
                    controller.isLoading.value = false;
                    controller.refreshController?.endRefreshing();
                    var isForMainFrame = request.isForMainFrame ?? false;
                    if (!isForMainFrame) {
                      return;
                    }

                    final snackBar = SnackBar(
                      content: Text(
                          'HTTP error for URL: ${request.url} with Status: ${errorResponse.statusCode} ${errorResponse.reasonPhrase ?? ''}'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  onReceivedError:
                      (onReceivedErrorcontroller, request, error) async {
                    controller.isLoading.value = false;
                    controller.refreshController?.endRefreshing();
                    // Handle web page loading errors here
                    var isForMainFrame = request.isForMainFrame ?? false;
                    if (!isForMainFrame ||
                        (!kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.iOS &&
                            error.type == WebResourceErrorType.CANCELLED)) {
                      return;
                    }

                    var errorUrl =
                        request.url; //error page is designed use that
                    onReceivedErrorcontroller.loadData(data: """ 
      <!DOCTYPE html>
      
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error: No Internet Connection</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            color: #343a40;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
        }
        h1 {
            color: #dc3545;
        }
        p {
            color: #6c757d;
        }
        .icon {
            font-size: 4em;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🚫</div>
        <h1>Error: No Internet Connection</h1>
        <p>Sorry, it seems that you are not connected to the internet. Please check your connection and try again.</p>
    </div>
</body>
</html>
          """, baseUrl: errorUrl, historyUrl: errorUrl);
                  },

                  onPermissionRequest:
                      (onPermissionRequestcontroller, request) async {
                    final resources = <PermissionResourceType>[];
                    if (request.resources
                        .contains(PermissionResourceType.CAMERA)) {
                      final cameraStatus = await Permission.camera.request();
                      if (!cameraStatus.isDenied) {
                        resources.add(PermissionResourceType.CAMERA);
                      }
                    }
                    if (request.resources
                        .contains(PermissionResourceType.MICROPHONE)) {
                      final microphoneStatus =
                          await Permission.microphone.request();
                      if (!microphoneStatus.isDenied) {
                        resources.add(PermissionResourceType.MICROPHONE);
                      }
                    }
                    // only for iOS and macOS
                    if (request.resources.contains(
                        PermissionResourceType.CAMERA_AND_MICROPHONE)) {
                      final cameraStatus = await Permission.camera.request();
                      final microphoneStatus =
                          await Permission.microphone.request();
                      if (!cameraStatus.isDenied &&
                          !microphoneStatus.isDenied) {
                        resources
                            .add(PermissionResourceType.CAMERA_AND_MICROPHONE);
                      }
                    }

                    return PermissionResponse(
                        resources: resources,
                        action: resources.isEmpty
                            ? PermissionResponseAction.DENY
                            : PermissionResponseAction.GRANT);
                  },

                  initialUrlRequest:
                      URLRequest(url: WebUri(controller.initialUrl.toString())),
                ),
                Visibility(
                  visible: controller.isLoading.value,
                  child: controller.progress.value < 1.0
                      ? SizedBox(
                          width: double.infinity,
                          height: 6.0,
                          child: LinearProgressIndicator(
                              value: controller.progress.value))
                      : Container(),
                ) //use Custum Loading Animation
              ],
            ))
          ],
        ),
      ),
    ));
  }
}
