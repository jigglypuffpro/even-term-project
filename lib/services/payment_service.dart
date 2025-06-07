import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

class PaymentService {
  late Razorpay _razorpay;

  void init(Function onSuccess, Function onError) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (e) => onSuccess(e));
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (e) => onError(e));
  }

  void openCheckout(double amountInRupees, String name, String email, String phone) {
    var options = {
      'key': 'rzp_test_Kg5HPEEUCLBZpy', // Replace with your Razorpay API key
      'amount': (amountInRupees * 100).toInt(), // Amount in paise
      'name': name,
      'description': 'Slot Booking Payment',
      'prefill': {
        'contact': phone,
        'email': email,
      },
    };

    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}