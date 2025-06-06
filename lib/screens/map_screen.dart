import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_parking_app/screens/booked_slots_page.dart';
import '../services/firebase_service.dart';
import 'booking_page.dart';
import 'booked_slots_page.dart';
import 'package:geolocator/geolocator.dart';
import 'account_page.dart';
import 'settings_page.dart';
import 'about_page.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late GoogleMapController _mapController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Set<Marker> _markers = {};
  LatLng? _userLocation;
  bool _isLoading = true;
  bool _isCardVisible = false;

  // For showing selected marker info
  String? _selectedName;
  String? _selectedDistance;
  String? _selectedKey;
  double? _selectedLat;
  double? _selectedLng;

  // Theme colors
  static const Color kPrimaryColor = Color(0xFF6A1B9A);
  static const Color kAccentColor = Color(0xFF27B0B0);
  static const Color kBackgroundColor = Color(0xFFF3E5F5);
  static const Color kCardColor = Colors.white;
  static const Color kSuccessColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _getUserLocation();
    fetchParkingSpots();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
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
      _showErrorSnackBar('Unable to get your location');
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: kPrimaryColor),
            SizedBox(width: 8),
            Text('Location Services Disabled'),
          ],
        ),
        content: Text('Please enable location services to find nearby parking spots.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.red),
            SizedBox(width: 8),
            Text('Location Permission Required'),
          ],
        ),
        content: Text('Location permission is permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
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
      String? nearestKey, nearestName;
      double? nearestLat, nearestLng;
      String? nearestDistanceStr;

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
                nearestKey = key;
                nearestName = name;
                nearestLat = lat;
                nearestLng = lng;
                nearestDistanceStr = '${(distance / 1000).toStringAsFixed(2)} km away';
              }
            }

            newMarkers.add(
              Marker(
                markerId: MarkerId(key),
                position: spotPosition,
                infoWindow: InfoWindow(
                  title: name,
                  snippet: distance != null
                      ? 'Tap to book (${(distance / 1000).toStringAsFixed(2)} km away)'
                      : 'Tap to book',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  nearestKey == key ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueViolet,
                ),
                onTap: () {
                  setState(() {
                    _selectedName = name;
                    _selectedDistance = distance != null
                        ? '${(distance / 1000).toStringAsFixed(2)} km away'
                        : null;
                    _selectedKey = key;
                    _selectedLat = lat;
                    _selectedLng = lng;
                    _isCardVisible = true;
                  });
                  _animationController.forward();
                },
              ),
            );
          } catch (e) {
            print('Error processing parking area $key: $e');
          }
        }
      });

      setState(() {
        _markers = newMarkers;
        _isLoading = false;
        if (nearestKey != null) {
          _selectedKey = nearestKey;
          _selectedName = nearestName;
          _selectedLat = nearestLat;
          _selectedLng = nearestLng;
          _selectedDistance = nearestDistanceStr;
          _isCardVisible = true;
          _animationController.forward();
        }
      });

      if (nearestSpot != null) {
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(nearestSpot!, 15));
      }
    } catch (e) {
      print('❗ Error fetching parking spots: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load parking spots');
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

  Widget _buildModernDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryColor, kAccentColor],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimaryColor, kAccentColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.local_parking, size: 40, color: kPrimaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Smart Parking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Find & Book Parking',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.account_circle, 'Account', () async {
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
            }),
            _buildDrawerItem(Icons.book_online, 'Booked Slots', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookedSlotsPage()),
              );
            }),
            _buildDrawerItem(Icons.settings, 'Settings', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            }),
            _buildDrawerItem(Icons.info, 'About', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            }),
            Divider(color: Colors.white30, height: 32),
            _buildDrawerItem(Icons.logout, 'Sign Out', () async {
              await FirebaseService.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red[300] : Colors.white,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red[300] : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Finding parking spots...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.local_parking,
                                      color: kPrimaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedName!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: kAccentColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _selectedDistance!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isCardVisible = false;
                            });
                            _animationController.reverse();
                          },
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            shape: CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _navigateToBookingPage(
                            _selectedKey!,
                            _selectedName!,
                            _selectedLat!,
                            _selectedLng!,
                          );
                        },
                        icon: Icon(Icons.book_online, size: 20),
                        label: Text(
                          'Book Parking Slot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smart Parking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookedSlotsPage()),
              );
            },
            icon: Icon(Icons.book_online),
            tooltip: 'My Bookings',
          ),
        ],
      ),
      drawer: _buildModernDrawer(),
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
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            style: '''
            [
              {
                "featureType": "poi",
                "elementType": "labels",
                "stylers": [{"visibility": "off"}]
              }
            ]
            ''',
          ),
          if (_isLoading) _buildLoadingOverlay(),
          if (_isCardVisible && _selectedName != null && _selectedDistance != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildInfoCard(),
            ),
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "refresh",
                  onPressed: () => fetchParkingSpots(),
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryColor,
                  mini: true,
                  child: Icon(Icons.refresh),
                ),
                SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "location",
                  onPressed: () async {
                    await _getUserLocation();
                    if (_userLocation != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(_userLocation!, 15),
                      );
                      fetchParkingSpots();
                    }
                  },
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}