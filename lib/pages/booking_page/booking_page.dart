import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/controller/ParkingController.dart';

class BookingPage extends StatelessWidget {
  final String slotId;
  final String slotName;

  BookingPage({required this.slotId, required this.slotName, Key? key}) : super(key: key);

  final ParkingController parkingController = Get.find<ParkingController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book Slot $slotName")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: parkingController.nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: parkingController.vehicleController,
              decoration: InputDecoration(labelText: "Vehicle Number"),
            ),
            SizedBox(height: 20),
            Obx(() => Slider(
                  value: parkingController.parkingTimeInMin.value,
                  min: 10,
                  max: 180,
                  divisions: 17,
                  label: "${parkingController.parkingTimeInMin.value.round()} min",
                  onChanged: (value) {
                    parkingController.parkingTimeInMin.value = value;
                    parkingController.updateAmount();
                  },
                )),
            Obx(() => Text("Amount: Rs ${parkingController.parkingAmount.value}")),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                String name = parkingController.nameController.text.trim();
                String vehicle = parkingController.vehicleController.text.trim();
                int hours = (parkingController.parkingTimeInMin.value / 60).ceil();

                if (name.isEmpty || vehicle.isEmpty) {
                  Get.snackbar("Error", "Please enter both name and vehicle number");
                  return;
                }

                parkingController.bookSlot(
                  slotId: slotId,
                  hours: hours,
                  name: name,
                  vehicleNumber: vehicle,
                );

                Get.back(); // Go back to previous screen after booking
                Get.snackbar("Success", "Slot $slotName booked successfully!");
              },
              child: Text("Confirm Slot"),
            ),
          ],
        ),
      ),
    );
  }
}
