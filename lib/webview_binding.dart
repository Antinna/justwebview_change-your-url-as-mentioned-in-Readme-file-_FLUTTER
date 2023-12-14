import 'package:get/get.dart';
import 'package:we2gether/webview_controller.dart';




class WebViewBinding extends Bindings {
  @override
  void dependencies() {
    // auth provider
    Get.lazyPut(() => WebViewController(), );
  }
}