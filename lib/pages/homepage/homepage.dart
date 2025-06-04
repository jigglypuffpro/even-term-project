import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/components/floot_selector.dart';
import '/components/parking_slot.dart';
import '/controller/ParkingController.dart';
import '../../config/colors.dart';
import '../booking_page/booking_page.dart';

class HomePage extends StatelessWidget {
  final ParkingController parkingController = Get.find<ParkingController>();

  Widget buildSlotCard(String slotId) {
    final slotModel = parkingController.slots[slotId]!.value;
    final isBooked = slotModel.booked;

    return GestureDetector(
      onTap: () {
        if (!isBooked) {
          // Navigate to booking page with slotId and slotName
          Get.to(() => BookingPage(slotId: slotId, slotName: slotModel.slotName));
        } else {
          Get.snackbar(
            "Unavailable",
            "Slot ${slotModel.slotName} is already booked.",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isBooked ? Colors.red : Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slotModel.slotName,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              isBooked ? "Booked" : "Available",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Parking Slots"),
      ),
      body: Obx(() {
        return GridView.count(
          crossAxisCount: 2,
          children: parkingController.slots.keys.map((slotId) {
            return buildSlotCard(slotId);
          }).toList(),
        );
      }),
    );
  }
}