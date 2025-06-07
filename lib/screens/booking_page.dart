import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firebase_service.dart';
import 'navigation_page.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'booking_confirmation_page.dart';



class BookingPage extends StatefulWidget {
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

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  Color get kPrimaryColor => Theme.of(context).colorScheme.primary;
  Color get kAccentColor => Theme.of(context).colorScheme.secondary;
  Color get kBackgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get kSlotAvailableColor => Colors.green[300] ?? Colors.green;
  Color get kSlotUnavailableColor => Colors.red[300] ?? Colors.red;
  Color get kSlotSelectedColor => kPrimaryColor;
  String? _selectedSlot;
  int _selectedDurationMinutes = 30;
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  StreamSubscription? _slotsSubscription;
  Timer? _localExpiryCheckTimer;
  Timer? _timeUpdateTimer;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
    _localExpiryCheckTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) _checkForExpiredBookings();
    });
    // Add timer to update time display every minute
    _timeUpdateTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _setupRealtimeListener() {
    _loadSlots();
    _slotsSubscription = FirebaseService
        .listenToSlotsChanges(widget.keyId)
        .listen((DatabaseEvent event) {
      if (mounted && event.snapshot.exists) {
        _processSlotData(event.snapshot);
      }
    });
  }

  void _checkForExpiredBookings() {
    bool needsUpdate = false;
    final now = DateTime.now();
    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (slot.containsKey('bookedUntil') && slot['bookedUntil'] != null && !slot['available']) {
        try {
          DateTime bookedUntil = DateTime.parse(slot['bookedUntil'].toString());
          if (now.isAfter(bookedUntil)) {
            _slots[i]['available'] = true;
            needsUpdate = true;
          }
        } catch (e) {
          print('Error parsing bookedUntil: $e');
        }
      }
    }
    if (needsUpdate && mounted) setState(() {});
  }

  void _processSlotData(DataSnapshot snapshot) {
    if (!snapshot.exists) return;
    Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
    List<Map<String, dynamic>> newSlots = [];

    data.forEach((key, value) {
      bool isAvailable = true;
      String? bookedUntil;

      if (value is Map) {
        if (value.containsKey('available')) {
          isAvailable = value['available'] == true;
        }
        if (value.containsKey('bookedUntil') && value['bookedUntil'] != null) {
          bookedUntil = value['bookedUntil'].toString();
          try {
            DateTime bookedUntilDate = DateTime.parse(bookedUntil);
            if (DateTime.now().isAfter(bookedUntilDate)) {
              isAvailable = true;
              _freeExpiredSlot(key);
            } else {
              isAvailable = false;
            }
          } catch (e) {
            print('Error parsing bookedUntil date: $e');
          }
        }
      } else if (value is bool) {
        isAvailable = value;
      }

      newSlots.add({
        'id': key,
        'available': isAvailable,
        if (bookedUntil != null) 'bookedUntil': bookedUntil
      });
    });

    if (mounted) {
      setState(() {
        _slots = newSlots;
        _isLoading = false;
        if (_selectedSlot != null) {
          bool isStillAvailable = _slots.any((slot) => slot['id'] == _selectedSlot && slot['available'] == true);
          if (!isStillAvailable) _selectedSlot = null;
        }
      });
    }
  }

  Future<void> _freeExpiredSlot(String slotId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('parking_areas/${widget.keyId}/slots/$slotId');
      await ref.update({"available": true, "bookedUntil": null});
    } catch (e) {
      print('Error freeing expired slot: $e');
    }
  }

  void _loadSlots() async {
    setState(() => _isLoading = true);
    try {
      final slots = await FirebaseService.getAvailableSlots(widget.keyId);
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading slots: $e');
      setState(() => _isLoading = false);
    }
  }

  void _bookSlot(BuildContext context) async {
    final selectedSlot = _selectedSlot;
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a parking slot first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(
          keyId: widget.keyId,
          slotId: selectedSlot,
          place: widget.name,
          durationMinutes: _selectedDurationMinutes,
        ),
      ),
    );
  }

  String _getTimeRemainingText(Map<String, dynamic> slot) {
    if (slot['available'] == true) {
      return 'Available';
    }

    if (slot.containsKey('bookedUntil') && slot['bookedUntil'] != null) {
      try {
        final bookedUntil = DateTime.parse(slot['bookedUntil'].toString());
        final now = DateTime.now();

        if (bookedUntil.isAfter(now)) {
          final diff = bookedUntil.difference(now);

          if (diff.inDays > 0) {
            return '${diff.inDays}d ${diff.inHours % 24}h';
          } else if (diff.inHours > 0) {
            return '${diff.inHours}h ${diff.inMinutes % 60}m';
          } else if (diff.inMinutes > 0) {
            return '${diff.inMinutes}m';
          } else {
            return '<1m';
          }
        } else {
          return 'Expired';
        }
      } catch (e) {
        print('Error parsing time: $e');
        return 'Occupied';
      }
    }

    return 'Occupied';
  }

  Widget _buildSlotGrid() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
        ),
      );
    }

    if (_slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(Icons.local_parking_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No slots available',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _slots.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final isSelected = _selectedSlot == slot['id'];
        final isAvailable = slot['available'] == true;
        final timeText = _getTimeRemainingText(slot);

        return GestureDetector(
          onTap: isAvailable ? () => setState(() => _selectedSlot = slot['id']) : null,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAvailable
                    ? (isSelected
                    ? [kSlotSelectedColor, kSlotSelectedColor.withOpacity(0.8)]
                    : [kSlotAvailableColor, kSlotAvailableColor.withOpacity(0.8)])
                    : [kSlotUnavailableColor, kSlotUnavailableColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: isSelected ? 3 : 1
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: isSelected ? 8 : 4,
                  offset: Offset(0, isSelected ? 4 : 2),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAvailable ? Icons.local_parking : Icons.block,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(height: 3),
                  Text(
                    slot['id'],
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      timeText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _slotsSubscription?.cancel();
    _localExpiryCheckTimer?.cancel();
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Booking: ${widget.name}'),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () async => _loadSlots(),
          color: kPrimaryColor,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_parking, color: kPrimaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Select Parking Slot',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildSlotGrid(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: kPrimaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Select Duration',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Theme(
                            data: Theme.of(context).copyWith(
                              sliderTheme: SliderThemeData(
                                activeTrackColor: kPrimaryColor,
                                inactiveTrackColor: kPrimaryColor.withOpacity(0.3),
                                thumbColor: kAccentColor,
                                overlayColor: kAccentColor.withOpacity(0.2),
                              ),
                            ),
                            child: Slider(
                              value: _selectedDurationMinutes.toDouble(),
                              min: 15,
                              max: 120,
                              divisions: 7,
                              label: '$_selectedDurationMinutes mins',
                              onChanged: (value) => setState(() => _selectedDurationMinutes = value.toInt()),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_selectedDurationMinutes minutes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _bookSlot(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.book_online),
                            label: Text('Book Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NavigationPage(
                                    destination: LatLng(widget.latitude, widget.longitude),
                                    destinationName: widget.name,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.navigation),
                            label: Text('Navigate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}