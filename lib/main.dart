// import 'dart:isolate';
// import 'dart:ui';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   InAppWebViewController? webViewController;
//   InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
//       crossPlatform: InAppWebViewOptions(
//         useShouldOverrideUrlLoading: true,
//         mediaPlaybackRequiresUserGesture: false,
//       ),
//       android: AndroidInAppWebViewOptions(
//         useHybridComposition: true,
//       ),
//       ios: IOSInAppWebViewOptions(
//         allowsInlineMediaPlayback: true,
//       ));

//   late PullToRefreshController? pullToRefreshController;
//   String url = "";
//   double progress = 0;
//   CookieManager cookieManager = CookieManager.instance();
//   ContextMenu? contextMenu;
//   DateTime? currentBackPressTime;
//   // WebNotificationController? webNotificationController;
//   final ReceivePort _port = ReceivePort();
//   bool requestnotificationpermission = true;
//   Future<bool> onWillPop() async {
//     DateTime now = DateTime.now();
//     if (await webViewController!.canGoBack()) {
//       webViewController!.goBack();
//       return Future.value(false);
//     } else {
//       if (currentBackPressTime == null ||
//           now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
//         currentBackPressTime = now;
//         // Get.snackbar("Exit", "Double tap to close app",
//         //     backgroundColor: Colors.white,
//         //     snackPosition: SnackPosition.BOTTOM);
//         return Future.value(false);
//       }
//       return Future.value(true);
//     }
//   }

//   @pragma('vm:entry-point')
//   static void downloadCallback(
//       String id, DownloadTaskStatus status, int progress) {
//     final SendPort? send =
//         IsolateNameServer.lookupPortByName('downloader_send_port');
//     send?.send([id, status, progress]);
//   }

// /////////Please Modify Below code//////
//   Future<void> downloadFile(String url, [String? filename]) async {
//     var hasStoragePermission = await Permission.storage.isGranted;
//     if (!hasStoragePermission) {
//       final status = await Permission.storage.request();
//       hasStoragePermission = status.isGranted;
//     }
//     if (hasStoragePermission) {
//       final taskId = await FlutterDownloader.enqueue(
//           url: url,
//           headers: {},
//           // optional: header send with url (auth token etc)
//           savedDir: (await getDownloadsDirectory())!.path,
//           saveInPublicStorage: true,
//           fileName: filename);
//     }
//   }
//   @override
//   void initState() {
//     super.initState();
//     pullToRefreshController = kIsWeb
//         ? null
//         : PullToRefreshController(
//             settings: PullToRefreshSettings(
//               color: Colors.green,
//             ),
//             onRefresh: () async {
//               if (defaultTargetPlatform == TargetPlatform.android) {
//                 webViewController?.reload();
//               } else if (defaultTargetPlatform == TargetPlatform.iOS) {
//                 webViewController?.loadUrl(
//                     urlRequest:
//                         URLRequest(url: await webViewController?.getUrl()));
//               }
//             },
//           );
//         IsolateNameServer.registerPortWithName(
//         _port.sendPort, 'downloader_send_port');
//     _port.listen((dynamic data) {
//       String id = data[0];
//       DownloadTaskStatus status = data[1];
//       int progress = data[2];
//       if (kDebugMode) {
//         print("Download progress: $progress%");
//       }
//       // if (status == DownloadTaskStatus.complete) {
//       //   Get.snackbar("Downloaded", "Download $id completed!");
//       // }
//     });
//     FlutterDownloader.registerCallback(downloadCallback);

//   }

//   @override
//   void dispose() {
//     super.dispose();
//     IsolateNameServer.removePortNameMapping('downloader_send_port');
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: WillPopScope(
//           onWillPop: () {
//             return Future.value(true);
//           },
//           child: SafeArea(
//               child: Stack(
//             children: [
//               InAppWebView(
//                 initialUrlRequest:
//                     URLRequest(url: Uri.parse("https://we2gether.in")),
//                 initialOptions: options,
//                 pullToRefreshController: pullToRefreshController,
//                 onWebViewCreated: (controller) {
//                   webViewController = controller;
//                 },
//                 onLoadStart: (controller, url) {
//                   setState(() {
//                     this.url = url.toString();
//                     // urlController.text = this.url;
//                   });
//                 },
//                 androidOnPermissionRequest:
//                     (controller, origin, resources) async {
//                   return PermissionRequestResponse(
//                       resources: resources,
//                       action: PermissionRequestResponseAction.GRANT);
//                 },
//                 shouldOverrideUrlLoading: (controller, navigationAction) async {
//                   var uri = navigationAction.request.url!;

//                   if (![
//                     "http",
//                     "https",
//                     "file",
//                     "chrome",
//                     "data",
//                     "javascript",
//                     "about"
//                   ].contains(uri.scheme)) {
//                     // if (await canLaunch(url)) {
//                     //   // Launch the App
//                     //   await launch(
//                     //     url,
//                     //   );
//                     //   // and cancel the request
//                     //   return NavigationActionPolicy.CANCEL;
//                     // }
//                   }

//                   // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
//                   //   final shouldPerformDownload =
//                   //       navigationAction.request.shouldPerformDownload ?? false;
//                   //   final url = navigationAction.request.url;
//                   //   if (shouldPerformDownload && url != null) {
//                   //     await downloadFile(url.toString());
//                   //     return NavigationActionPolicy.DOWNLOAD;
//                   //   }
//                   // }

//                   return NavigationActionPolicy.ALLOW;
//                 },
//                 onLoadStop: (controller, url) async {
//                   pullToRefreshController?.endRefreshing();
//                   setState(() {
//                     this.url = url.toString();
//                     // urlController.text = this.url;
//                   });
//                 },
//                 onLoadError: (controller, url, code, message) {
//                   pullToRefreshController?.endRefreshing();
//                 },
//                 onProgressChanged: (controller, progress) {
//                   if (progress == 100) {
//                     pullToRefreshController?.endRefreshing();
//                   }
//                   setState(() {
//                     this.progress = progress / 100;
//                     // urlController.text = this.url;
//                   });
//                 },
//                 onUpdateVisitedHistory: (controller, url, androidIsReload) {
//                   setState(() {
//                     this.url = url.toString();
//                     // urlController.text = this.url;
//                   });
//                 },
//               ),
//               progress < 1.0
//                   ? LinearProgressIndicator(value: progress)
//                   : Container(),
//             ],
//           ))),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we2gether/web_notification.dart';
import 'package:we2gether/webview_binding.dart';
import 'package:we2gether/webview_screen.dart';

////////////////////////////////////////////////////////////////////////////////////

late SharedPreferences sharedPreferences;

class MyHttpoverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, String host, int port) => true;
  }
}

final userScripts = <UserScript>[];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  await Permission.microphone.request();

  sharedPreferences = await SharedPreferences.getInstance();
  HttpOverrides.global = MyHttpoverrides();

  if (Platform.isAndroid || Platform.isIOS) {
    await FlutterDownloader.initialize(
        debug: false, //todo faalse
        // optional: set to false to disable printing logs to console (default: true)
        ignoreSsl:
            false // option: set to false to disable working with http links (default: false)
        );
    await Permission.storage.request();

    final jsNotificationApiUserScript = UserScript(
        source: await rootBundle.loadString('assets/web_notification.js'),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START);
    userScripts.add(jsNotificationApiUserScript);

    await WebNotificationPermissionDb.loadSavedPermissions();

    final json = jsonEncode(WebNotificationPermissionDb.getPermissions());
    userScripts.add(UserScript(source: """
    (function(window) {
      var notificationPermissionDb = $json;
      if (notificationPermissionDb[window.location.host] === 'granted') {
        Notification._permission = 'granted';
      }
    })(window);
    """, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START));
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // theme: ThemeData(fontFamily: "PassionsConflict"),
      debugShowCheckedModeBanner: false,
      // initialRoute: AppPages.initial,
      // getPages: AppPages.routes,
      // initialBinding: StorageBinding()
      // BindingsBuilder(() {
      //
      //   // like this!
      //   Get.put(StorageUtils(), permanent: true);
      // }),
      theme: ThemeData(primarySwatch: Colors.green),
      home: WebViewScreen(),
      initialBinding: WebViewBinding(),
    );
  }
}
