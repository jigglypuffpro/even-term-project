import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  List<Step> _navigationSteps = [];
  int _currentStepIndex = 0;
  bool _isLoadingRoute = false;

  // Add your Google Maps API key here
  final String _googleApiKey = "AIzaSyAbXOxNF2jhly39LBZtIqbzIW2d0-ldT-4";

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _updateLocation(LatLng(position.latitude, position.longitude));

      // Get initial route
      _getDirections(LatLng(position.latitude, position.longitude));

      // Start location streaming for real-time updates
      _positionStream = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high, distanceFilter: 10))
          .listen((Position position) {
        _updateLocation(LatLng(position.latitude, position.longitude));

        // Check if we need to update the step
        _checkCurrentStep();
      });
    } catch (e) {
      print('Error starting location updates: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Failed to get location: $e')),
      );
    }
  }

  void _updateLocation(LatLng newPosition) {
    setState(() {
      _currentPosition = newPosition;
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;

    _markers = {
      Marker(
        markerId: MarkerId('current'),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'Your Location'),
      ),
      Marker(
        markerId: MarkerId('destination'),
        position: widget.destination,
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
    };
  }

  Future<void> _getDirections(LatLng origin) async {
    if (origin == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}'
              '&destination=${widget.destination.latitude},${widget.destination.longitude}'
              '&mode=driving'
              '&key=$_googleApiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Extract polyline points
          List<LatLng> polylineCoordinates = [];

          if (data['routes'].isNotEmpty && data['routes'][0]['overview_polyline'] != null) {
            String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
            PolylinePoints polylinePoints = PolylinePoints();
            List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);

            polylineCoordinates = decodedPoints
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
          }

          // Create polyline
          setState(() {
            _polylines = {
              Polyline(
                polylineId: PolylineId('route'),
                color: Colors.blue,
                width: 5,
                points: polylineCoordinates,
              ),
            };
          });

          // Extract navigation steps
          if (data['routes'].isNotEmpty &&
              data['routes'][0]['legs'].isNotEmpty &&
              data['routes'][0]['legs'][0]['steps'] != null) {

            setState(() {
              _navigationSteps = List<Step>.from(
                data['routes'][0]['legs'][0]['steps'].map(
                      (step) => Step(
                    instruction: step['html_instructions'],
                    distance: step['distance']['text'],
                    duration: step['duration']['text'],
                    startLocation: LatLng(
                      step['start_location']['lat'],
                      step['start_location']['lng'],
                    ),
                    endLocation: LatLng(
                      step['end_location']['lat'],
                      step['end_location']['lng'],
                    ),
                  ),
                ),
              );
              _currentStepIndex = 0;
            });
          }

          // Fit the route on the map
          if (polylineCoordinates.isNotEmpty) {
            LatLngBounds bounds = _boundsFromLatLngList(polylineCoordinates);
            _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          }
        } else {

          print('Directions API returned error: ${data['status']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❗ Failed to get directions: ${data['status']}')),
          );
        }
      } else {
        print('Failed to get directions with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❗ Failed to get directions')),
        );
      }
    } catch (e) {
      print('Error fetching directions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Error fetching directions: $e')),
      );
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  // Calculate bounds for a list of LatLng coordinates
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;

    for (final latLng in list) {
      if (minLat == null || latLng.latitude < minLat) minLat = latLng.latitude;
      if (maxLat == null || latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (minLng == null || latLng.longitude < minLng) minLng = latLng.longitude;
      if (maxLng == null || latLng.longitude > maxLng) maxLng = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _checkCurrentStep() {
    if (_currentPosition == null || _navigationSteps.isEmpty) return;

    // Find the closest step based on user position
    double minDistance = double.infinity;
    int closestStepIndex = _currentStepIndex;

    // Only check from current step forward to avoid going back
    for (int i = _currentStepIndex; i < _navigationSteps.length; i++) {
      final step = _navigationSteps[i];
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        step.startLocation.latitude,
        step.startLocation.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestStepIndex = i;
      }
    }

    // If we've moved to a new step
    if (closestStepIndex != _currentStepIndex) {
      setState(() {
        _currentStepIndex = closestStepIndex;
      });
    }
  }

  String _stripHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, ' ');
  }

  void _recenterMap() {
    if (_currentPosition != null) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 17));
    }
  }

  void _refreshRoute() {
    if (_currentPosition != null) {
      _getDirections(_currentPosition!);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate to ${widget.destinationName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshRoute,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Loading indicator
          if (_isLoadingRoute)
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
                    Text('Loading route...'),
                  ],
                ),
              ),
            ),

          // Turn-by-turn instruction panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Current step instructions
                  if (_navigationSteps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions, color: Colors.blue, size: 30),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _stripHtmlTags(_navigationSteps[_currentStepIndex].instruction),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${_navigationSteps[_currentStepIndex].distance} · ${_navigationSteps[_currentStepIndex].duration}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),

                          // Next step preview if available
                          if (_currentStepIndex < _navigationSteps.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_downward, color: Colors.grey),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Then ${_stripHtmlTags(_navigationSteps[_currentStepIndex + 1].instruction)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Destination arrival message
                          if (_currentStepIndex == _navigationSteps.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text(
                                    'Arriving at ${widget.destinationName}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Loading directions...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _recenterMap,
            heroTag: 'recenter',
            child: Icon(Icons.my_location),
            mini: true,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _refreshRoute,
            heroTag: 'refresh',
            child: Icon(Icons.refresh),
            mini: true,
          ),
        ],
      ),
    );
  }
}

// Class to store step information
class Step {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;

  Step({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });
}