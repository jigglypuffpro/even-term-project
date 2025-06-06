import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class BookedSlotsPage extends StatefulWidget {
  @override
  _BookedSlotsPageState createState() => _BookedSlotsPageState();
}

class _BookedSlotsPageState extends State<BookedSlotsPage> {
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = FirebaseService.getUserBookings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
        title: const Text(
          'Your Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No bookings found.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.local_parking, 'Parking ID', booking['parkingId'], primaryColor, textColor),
                      const SizedBox(height: 8),
                      _infoRow(Icons.confirmation_number, 'Slot ID', booking['slotId'], primaryColor, textColor),
                      const SizedBox(height: 8),
                      _infoRow(Icons.schedule, 'Start Time', booking['startTime'], primaryColor, textColor),
                      const SizedBox(height: 8),
                      _infoRow(Icons.timer_off, 'End Time', booking['endTime'], primaryColor, textColor),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 15, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}