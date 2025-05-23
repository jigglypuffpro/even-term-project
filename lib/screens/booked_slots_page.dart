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
    return Scaffold(
      appBar: AppBar(title: Text('Your Bookings')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No bookings found.'));
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Parking ID: ${booking['parkingId']}'),
                  subtitle: Text(
                    'Slot: ${booking['slotId']}\nFrom: ${booking['startTime']}\nTo: ${booking['endTime']}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}