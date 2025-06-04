import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:smart_parking_app/services/payment_service.dart';

class BookingConfirmationPage extends StatefulWidget {
  final String slotId;
  final String place;
  final int durationMinutes;

  const BookingConfirmationPage({
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Confirm the booking here and store in Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Payment Successful! Booking Confirmed.")),
    );
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment Failed. Please try again.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double estimatedCost = widget.durationMinutes * 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        title: const Text('Booking Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            _buildDetailsCard(estimatedCost),
            const SizedBox(height: 24),
            _buildInputField(nameController, 'Your Name', Icons.person),
            const SizedBox(height: 16),
            _buildInputField(vehicleController, 'Vehicle Number', Icons.directions_car),
            const SizedBox(height: 16),
            _buildInputField(phoneController, 'Phone Number (Optional)', Icons.phone),
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
                  '', // Email (optional)
                  phoneController.text,
                );
                // Proceed with confirmation logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Booking Confirmed!")),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A), // Light purple
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(double cost) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1C4E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.confirmation_number, 'Slot ID', widget.slotId),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on, 'Place', widget.place),
          const SizedBox(height: 12),
          _infoRow(Icons.timer, 'Duration', '${widget.durationMinutes} minutes'),
          const SizedBox(height: 12),
          _infoRow(Icons.attach_money, 'Estimated Cost', '₹${cost.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7E57C2)),
        const SizedBox(width: 12),
        Expanded(child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      cursorColor: const Color(0xFF7E57C2),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3E5F5),
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF7E57C2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}