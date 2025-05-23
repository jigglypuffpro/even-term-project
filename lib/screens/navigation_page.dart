// navigation_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class NavigationPage extends StatefulWidget {
  final LatLng destination;
  final String destinationName;

  NavigationPage({
    required this.destination,
    required this.destinationName,
  });

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late GoogleMapController _mapController;
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _initMarkers();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❗ Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❗ Location permissions permanently denied')),
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❗ Location permission denied')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _updateMarkers();
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initMarkers() {
    // Add destination marker
    _markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: widget.destination,
        infoWindow: InfoWindow(
          title: widget.destinationName,
          snippet: 'Your parking spot',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  void _updateMarkers() {
    if (_userLocation != null) {
      // Add user location marker
      _markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: _userLocation!,
          infoWindow: InfoWindow(
            title: 'Your Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Update state to refresh the map
      setState(() {});

      // Fit map to include both markers
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _userLocation!.latitude < widget.destination.latitude
              ? _userLocation!.latitude
              : widget.destination.latitude,
          _userLocation!.longitude < widget.destination.longitude
              ? _userLocation!.longitude
              : widget.destination.longitude,
        ),
        northeast: LatLng(
          _userLocation!.latitude > widget.destination.latitude
              ? _userLocation!.latitude
              : widget.destination.latitude,
          _userLocation!.longitude > widget.destination.longitude
              ? _userLocation!.longitude
              : widget.destination.longitude,
        ),
      );

      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  Future<void> _launchGoogleMapsDirections() async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Your location is not available')),
      );
      return;
    }

    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${_userLocation!.latitude},${_userLocation!.longitude}'
            '&destination=${widget.destination.latitude},${widget.destination.longitude}'
            '&travelmode=driving'
            '&dir_action=navigate' // This forces turn-by-turn navigation
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Could not launch Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate to ${widget.destinationName}'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.destination,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
                if (_userLocation != null) {
                  _updateMarkers();
                }
              });
            },
            markers: _markers,
            polylines: _polylines,
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
                    Text('Loading location...'),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Distance info card
                if (_userLocation != null)
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, color: Colors.blue),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distance: ${(Geolocator.distanceBetween(
                                    _userLocation!.latitude,
                                    _userLocation!.longitude,
                                    widget.destination.latitude,
                                    widget.destination.longitude,
                                  ) / 1000).toStringAsFixed(2)} km',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Parking spot: ${widget.destinationName}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                // Navigation button
                ElevatedButton.icon(
                  onPressed: _launchGoogleMapsDirections,
                  icon: Icon(Icons.navigation),
                  label: Text('START NAVIGATION WITH GOOGLE MAPS'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _getUserLocation();
          if (_userLocation != null) {
            _mapController.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 15));
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}