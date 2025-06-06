import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:smart_parking_app/services/payment_service.dart';
import '../services/firebase_service.dart';

class BookingConfirmationPage extends StatefulWidget {
  final String keyId;
  final String slotId;
  final String place;
  final int durationMinutes;

  const BookingConfirmationPage({
    required this.keyId,
    required this.slotId,
    required this.place,
    required this.durationMinutes,
    super.key,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    paymentService.init(_handlePaymentSuccess, _handlePaymentError);
  }

  @override
  void dispose() {
    paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await FirebaseService.bookSlot(widget.keyId, widget.slotId, widget.durationMinutes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Payment Successful! Booking Confirmed.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Booking failed after payment. Please contact support.")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Payment Failed. Please try again.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = colorScheme.primary;
    final secondaryContainer = colorScheme.secondaryContainer;
    final surfaceColor = colorScheme.surface;

    final double estimatedCost = widget.durationMinutes * 1.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
        title: const Text('Booking Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            _buildDetailsCard(estimatedCost, surfaceColor, primaryColor),
            const SizedBox(height: 24),
            _buildInputField(nameController, 'Your Name', Icons.person, surfaceColor, primaryColor),
            const SizedBox(height: 16),
            _buildInputField(vehicleController, 'Vehicle Number', Icons.directions_car, surfaceColor, primaryColor),
            const SizedBox(height: 16),
            _buildInputField(phoneController, 'Phone Number (Optional)', Icons.phone, surfaceColor, primaryColor),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || vehicleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill in all required fields.")),
                  );
                  return;
                }
                paymentService.openCheckout(
                  estimatedCost,
                  nameController.text,
                  '',
                  phoneController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Pay and Confirm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(double cost, Color cardColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.confirmation_number, 'Slot ID', widget.slotId, iconColor),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on, 'Place', widget.place, iconColor),
          const SizedBox(height: 12),
          _infoRow(Icons.timer, 'Duration', '${widget.durationMinutes} minutes', iconColor),
          const SizedBox(height: 12),
          _infoRow(Icons.attach_money, 'Estimated Cost', '₹${cost.toStringAsFixed(2)}', iconColor),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, Color fillColor, Color iconColor) {
    return TextField(
      controller: controller,
      cursorColor: iconColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}