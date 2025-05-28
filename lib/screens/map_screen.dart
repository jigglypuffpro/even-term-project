import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_parking_app/screens/booked_slots_page.dart';
import '../services/firebase_service.dart';
import 'booking_page.dart';
import 'booked_slots_page.dart'; // Create this page
import 'package:geolocator/geolocator.dart';
import 'account_page.dart';
import 'settings_page.dart';
import 'about_page.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    fetchParkingSpots();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void fetchParkingSpots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await FirebaseService.getParkingAreas();

      Set<Marker> newMarkers = {};
      double? nearestDistance;
      LatLng? nearestSpot;

      data.forEach((key, value) {
        if (value != null && value['lat'] != null && value['lng'] != null) {
          try {
            double lat = double.parse(value['lat'].toString());
            double lng = double.parse(value['lng'].toString());
            String name = value['name'] ?? 'Parking Area';

            LatLng spotPosition = LatLng(lat, lng);
            double? distance;

            if (_userLocation != null) {
              distance = Geolocator.distanceBetween(
                _userLocation!.latitude,
                _userLocation!.longitude,
                lat,
                lng,
              );

              if (nearestDistance == null || distance < nearestDistance!) {
                nearestDistance = distance;
                nearestSpot = spotPosition;
              }
            }

            newMarkers.add(
              Marker(
                markerId: MarkerId(key),
                position: spotPosition,
                infoWindow: InfoWindow(
                  title: name,
                  snippet: distance != null
                      ? 'Tap to book (\${(distance / 1000).toStringAsFixed(2)} km away)'
                      : 'Tap to book',
                ),
                onTap: () {
                  _navigateToBookingPage(key, name, lat, lng);
                },
              ),
            );
            print('Added marker for: $name at $lat, $lng');
          } catch (e) {
            print('Error processing parking area \$key: \$e');
          }
        }
      });

      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });

      if (nearestSpot != null && _mapController != null) {
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(nearestSpot!, 15));
      }
    } catch (e) {
      print('❗ Error fetching parking spots: \$e');
      setState(() {
        _isLoading = false;
      });
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
    ).then((_) {
      fetchParkingSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Parking Map'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: Text('Welcome!', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Account'),
              onTap: () async {
                final user = await FirebaseService.getCurrentUser();
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountPage(
                        name: user.displayName ?? 'No Name',
                        email: user.email ?? 'No Email',
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.book_online),
              title: Text('Booked Slots'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookedSlotsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign Out'),
              onTap: () async {
                await FirebaseService.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? LatLng(25.6097, 85.1239),
              zoom: 13,
            ),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: true,
            zoomControlsEnabled: true,
          ),
          if (_isLoading)
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading parking spots...'),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _getUserLocation();
          if (_userLocation != null) {
            _mapController.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 15));
            fetchParkingSpots();
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}