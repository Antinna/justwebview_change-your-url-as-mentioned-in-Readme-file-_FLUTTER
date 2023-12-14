import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:isolate';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:we2gether/web_notification.dart';

class WebViewController extends GetxController {
  ///////////////
  ///
  ///
  ///
  // list of Ad URL filters to be used to block ads loading.
  final adUrlFilters = [
    ".*.doubleclick.net/.*",
    ".*.ads.pubmatic.com/.*",
    ".*.googlesyndication.com/.*",
    ".*.google-analytics.com/.*",
    ".*.adservice.google.*/.*",
    ".*.adbrite.com/.*",
    ".*.exponential.com/.*",
    ".*.quantserve.com/.*",
    ".*.scorecardresearch.com/.*",
    ".*.zedo.com/.*",
    ".*.adsafeprotected.com/.*",
    ".*.teads.tv/.*",
    ".*.outbrain.com/.*"
  ];

  final List<ContentBlocker> contentBlockers = [];
  var contentBlockerEnabled = true.obs;

  ///
  ///
  ///
  ///
  ///
  ////////////////////
  InAppWebViewController? webViewController;
  PullToRefreshController? refreshController;
  CookieManager cookieManager = CookieManager.instance();
  ContextMenu? contextMenu;
  String? url = "https://uptodatepopular.blogspot.com"; //todo late then unassign value
  var progress = 0.0.obs;
  var isLoading = false.obs;
  var initialUrl = "https://uptodatepopular.blogspot.com"; //todo unassign value
  DateTime? currentBackPressTime;
  RxnString? currentUrl;
  WebNotificationController? webNotificationController;
  final ReceivePort _port = ReceivePort();
  bool requestnotificationpermission = true;
  // var urlController = TextEditingController();
  @override
  void onInit() {
    // TODO: implement onInit
    // initialUrl = Get.arguments["url"] ?? "https://uptodatepopular.blogspot.com"; //TODO uncomment

    refreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.green,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
    //////////////////
    ///
    ///
    ///
    ///
    ///
    // for each Ad URL filter, add a Content Blocker to block its loading.
    for (final adUrlFilter in adUrlFilters) {
      contentBlockers.add(ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: adUrlFilter,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          )));
    }

    // apply the "display: none" style to some HTML elements
    contentBlockers.add(ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*",
        ),
        action: ContentBlockerAction(
            type: ContentBlockerActionType.CSS_DISPLAY_NONE,
            selector: ".banner, .banners, .ads, .ad, .advert")));

    ///
    ///
    ///
    ///
    ///
    ///
    //////////////////////
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (kDebugMode) {
        print("Download progress: $progress%");
      }
      if (status == DownloadTaskStatus.complete) {
        Get.snackbar("Downloaded", "Download $id completed!");
      }
    });
    FlutterDownloader.registerCallback(downloadCallback);

    super.onInit();
  }

  @override
  void dispose() {
    // dispose all those controllers also //TODO
    // TODO: implement dispose
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
      String id, int status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

/////////Please Modify Below code//////
  Future<void> downloadFile(String url, [String? filename]) async {
    var hasStoragePermission = await Permission.storage.isGranted;
    if (!hasStoragePermission) {
      final status = await Permission.storage.request();
      hasStoragePermission = status.isGranted;
    }
    if (hasStoragePermission) {
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          headers: {},
          // optional: header send with url (auth token etc)
          savedDir: (await getDownloadsDirectory())!.path,
          saveInPublicStorage: true,
          fileName: filename);
    }
  }

/////////////////
  ///
  void handleClick(int item) async {
    switch (item) {
      case 0:
        await webNotificationController?.requestPermission();
        break;
      case 1:
        await webViewController?.evaluateJavascript(source: """
          var testNotification = new Notification('Notification Title', {body: 'Notification Body!', icon: 'https://picsum.photos/150?random=' + Date.now(), vibrate: [200, 100, 200]});
          testNotification.addEventListener('show', function(event) {
            console.log('show log');
          });
          testNotification.addEventListener('click', function(event) {
            console.log('click log');
          });
          testNotification.addEventListener('close', function(event) {
            console.log('close log');
          });
        """);
        break;
      case 2:
        await webViewController?.evaluateJavascript(source: """
          try {
            if (testNotification != null) {
              testNotification.close();
            }
          } catch {}
        """);
        break;
      case 3:
        WebNotificationPermissionDb.clear();
        await webNotificationController?.resetPermission();
        break;
       case 4:
        await webViewController?.loadUrl(
            urlRequest: URLRequest(
                url: WebUri("$url")));
        break;
      case 5:
        await webViewController?.loadUrl(
            urlRequest: URLRequest(
                url: WebUri(
                    "$url")));
        break;
    }
  }

  //////////////////////
  void addJavaScriptHandlers() {
    webViewController?.addJavaScriptHandler(
      handlerName: 'Notification.requestPermission',
      callback: (arguments) async {
        final permission = await onNotificationRequestPermission();
        return permission.name.toLowerCase();
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'Notification.show',
      callback: (arguments) {
        if (webViewController != null) {
          final notification =
              WebNotification.fromJson(arguments[0], webViewController!);
          onShowNotification(notification);
        }
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'Notification.close',
      callback: (arguments) {
        final notificationId = arguments[0];
        onCloseNotification(notificationId);
      },
    );
  }

  Future<WebNotificationPermission> onNotificationRequestPermission() async {
    final url = await webViewController?.getUrl();

    if (url != null) {
      final savedPermission =
          WebNotificationPermissionDb.getPermission(url.host);
      if (savedPermission != null) {
        return savedPermission;
      }
    }

    final permission = await showDialog<WebNotificationPermission>(
          context: Get.context!,
          builder: (context) {
            return AlertDialog(
              title: Text('${url?.host} wants to show notifications'),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop<WebNotificationPermission>(
                          context, WebNotificationPermission.DENIED);
                    },
                    child: const Text('Deny')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop<WebNotificationPermission>(
                          context, WebNotificationPermission.GRANTED);
                    },
                    child: const Text('Grant'))
              ],
            );
          },
        ) ??
        WebNotificationPermission.DENIED;

    if (url != null) {
      await WebNotificationPermissionDb.savePermission(url.host, permission);
    }

    return permission;
  }

  void onShowNotification(WebNotification notification) async {
    webNotificationController?.notifications[notification.id] = notification;

    var iconUrl =
        notification.icon != null ? Uri.tryParse(notification.icon!) : null;
    if (iconUrl != null && !iconUrl.hasScheme) {
      iconUrl = Uri.tryParse(
          (await webViewController?.getUrl()).toString() + iconUrl.toString());
    }

    final snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Action',
        onPressed: () async {
          await notification.dispatchClick();
        },
      ),
      content: Row(
        children: <Widget>[
          iconUrl != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Image.network(
                    iconUrl.toString(),
                    width: 50,
                  ),
                )
              : Container(),
          // add your preferred text content here
          Expanded(
              child: Text(
                  notification.title +
                      (notification.body != null
                          ? '\n${notification.body!}'
                          : ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    notification.snackBarController =
        ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
    notification.snackBarController?.closed.then((value) async {
      notification.snackBarController = null;
      await notification.close();
    });

    final vibrate = notification.vibrate;
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator && vibrate != null && vibrate.isNotEmpty) {
      if (vibrate.length % 2 != 0) {
        vibrate.add(0);
      }
      final intensities = <int>[];
      for (int i = 0; i < vibrate.length; i++) {
        if (i % 2 == 0 && vibrate[i] > 0) {
          intensities.add(255);
        } else {
          intensities.add(0);
        }
      }
      await Vibration.vibrate(pattern: vibrate, intensities: intensities);
    }
  }

  void onCloseNotification(int id) {
    final notification = webNotificationController?.notifications[id];
    if (notification != null) {
      final snackBarController = notification.snackBarController;
      if (snackBarController != null) {
        snackBarController.close();
      }
      webNotificationController?.notifications.remove(id);
    }
  }
}
