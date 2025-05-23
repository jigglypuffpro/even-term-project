import 'package:get/get.dart';
import 'package:smart_parking_app/components/wrapper.dart';
import '/pages/LoginPage.dart';

class SplaceController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    pageHander();
  }

  void pageHander() async {
    Future.delayed(
      const Duration(seconds: 6),
      () {
        // Get.offAllNamed("/map-page");
        Get.offAll(Wrapper());
        update();
      },
    );
  }
}
