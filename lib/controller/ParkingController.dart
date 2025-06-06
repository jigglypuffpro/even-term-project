import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ParkingSlotModel {
  bool booked;
  bool isParked;
  String slotName;
  int parkingHours;
  String? name;
  String? vehicleNumber;

  ParkingSlotModel({
    this.booked = false,
    this.isParked = false,
    required this.slotName,
    this.parkingHours = 0,
    this.name,
    this.vehicleNumber,
  });
}

class ParkingController extends GetxController {
  // Using Map for slots for easier access by ID
  final slots = <String, Rx<ParkingSlotModel>>{
    "1": ParkingSlotModel(slotName: "A-1").obs,
    "2": ParkingSlotModel(slotName: "A-2").obs,
    "3": ParkingSlotModel(slotName: "A-3").obs,
    "4": ParkingSlotModel(slotName: "A-4").obs,
    // Add more slots if needed
  };

  // Controllers for booking page input fields
  final nameController = TextEditingController();
  final vehicleController = TextEditingController();

  var parkingTimeInMin = 10.0.obs;
  var parkingAmount = 30.obs;

  void updateAmount() {
    parkingAmount.value = (parkingTimeInMin.value * 3).toInt();
  }

  // Booking method with named parameters
  void bookSlot({
    required String slotId,
    required int hours,
    required String name,
    required String vehicleNumber,
  }) {
    final slot = slots[slotId];
    if (slot == null) return;

    slot.update((s) {
      if (s != null) {
        s.booked = true;
        s.isParked = true;
        s.parkingHours = hours;
        s.name = name;
        s.vehicleNumber = vehicleNumber;
      }
    });

    // Clear inputs after booking
    nameController.clear();
    vehicleController.clear();
    parkingTimeInMin.value = 10;
    updateAmount();
  }

  @override
  void onClose() {
    nameController.dispose();
    vehicleController.dispose();
    super.onClose();
  }
}