import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MapScreen(),
  ));
}

// --- Map Screen ---
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    fetchParkingSpotsFromFirebase();
  }

  void fetchParkingSpotsFromFirebase() async {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://smartapp-9b5f4-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      final ref = database.ref('parking_areas');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        Set<Marker> newMarkers = {};
        data.forEach((key, value) {
          if (value['available'] == true) {
            newMarkers.add(
              Marker(
                markerId: MarkerId(key),
                position: LatLng(value['lat'], value['lng']),
                infoWindow: InfoWindow(
                  title: value['name'],
                  snippet: 'Tap to book',
                  onTap: () {
                    _navigateToBookingPage(key, value['name'], value['lat'], value['lng']);
                  },
                ),
              ),
            );
          }
        });
        setState(() {
          _markers = newMarkers;
        });
      } else {
        print('❌ No data found at parking_areas');
      }
    } catch (e) {
      print('❗ Error fetching data: $e');
    }
  }

  void _navigateToBookingPage(String key, String name, double lat, double lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          keyId: key,
          name: name,
          latitude: lat,
          longitude: lng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Parking Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(25.6097, 85.1239), // Center on Patna
          zoom: 13,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        myLocationEnabled: true,
      ),
    );
  }
}

// --- Booking Page ---
class BookingPage extends StatelessWidget {
  final String keyId;
  final String name;
  final double latitude;
  final double longitude;

  BookingPage({
    required this.keyId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  void _bookSpot(BuildContext context) async {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://smartapp-9b5f4-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      final ref = database.ref('parking_areas/$keyId');
      await ref.update({"available": false});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parking spot booked!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Booking failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking: $name')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: $name', style: TextStyle(fontSize: 18)),
            Text('Latitude: $latitude'),
            Text('Longitude: $longitude'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _bookSpot(context),
              child: Text('Book this Spot'),
            ),
          ],
        ),
      ),
    );
  }
}
