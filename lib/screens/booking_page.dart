// Advanced solution using Firebase Realtime streams


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firebase_service.dart';
import 'navigation_page.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'booking_confirmation_page.dart'; // Add this line

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
  String? _selectedSlot;
  int _selectedDurationMinutes = 30;
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  StreamSubscription? _slotsSubscription;
  Timer? _localExpiryCheckTimer;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();

    // Set up a timer to check local expiry every 15 seconds
    // This is a backup in case Firebase events are delayed
    _localExpiryCheckTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) {
        _checkForExpiredBookings();
      }
    });
  }

  void _setupRealtimeListener() {
    // First load slots once
    _loadSlots();

    // Then set up the real-time listener
    _slotsSubscription = FirebaseService
        .listenToSlotsChanges(widget.keyId)
        .listen((DatabaseEvent event) {
      if (mounted && event.snapshot.exists) {
        try {
          print('Received realtime update for slots');
          _processSlotData(event.snapshot);
        } catch (e) {
          print('Error processing realtime slot update: $e');
        }
      }
    }, onError: (error) {
      print('Error in slots stream: $error');
    });
  }

  void _checkForExpiredBookings() {
    bool needsUpdate = false;
    final now = DateTime.now();

    // Check if any booked slots have expired and mark them as available locally
    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (slot.containsKey('bookedUntil') &&
          slot['bookedUntil'] != null &&
          !slot['available']) {
        try {
          DateTime bookedUntil = DateTime.parse(slot['bookedUntil'].toString());
          if (now.isAfter(bookedUntil)) {
            _slots[i]['available'] = true;
            needsUpdate = true;
            print('Local expiry check: Slot ${slot['id']} has expired');
          }
        } catch (e) {
          print('Error parsing date during local expiry check: $e');
        }
      }
    }

    if (needsUpdate && mounted) {
      setState(() {}); // Update UI with newly available slots
    }
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
              // Locally mark as available if expired
              isAvailable = true;
              // In real-time implementation, this should trigger an update to Firebase
              // to free the slot in the database
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

        // Check if selected slot is still available
        if (_selectedSlot != null) {
          bool isStillAvailable = _slots.any((slot) =>
          slot['id'] == _selectedSlot && slot['available'] == true);

          if (!isStillAvailable) {
            _selectedSlot = null;
          }
        }
      });
    }
  }

  Future<void> _freeExpiredSlot(String slotId) async {
    try {
      final ref = FirebaseDatabase.instance
          .ref('parking_areas/${widget.keyId}/slots/$slotId');

      await ref.update({
        "available": true,
        "bookedUntil": null
      });
      print('Freed expired slot: $slotId');
    } catch (e) {
      print('Error freeing expired slot: $e');
    }
  }

  void _loadSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final slots = await FirebaseService.getAvailableSlots(widget.keyId);
      setState(() {
        _slots = slots;
        _isLoading = false;
      });

      // Debug print to see what slots are loaded
      print('Loaded ${_slots.length} slots');
      _slots.forEach((slot) {
        print('Slot ID: ${slot['id']}, Available: ${slot['available']}');
      });
    } catch (e) {
      print('Error loading slots: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Failed to load slots: $e')),
      );
    }
  }

  void _bookSlot(BuildContext context) async {
    final selectedSlot = _selectedSlot; // Create local copy
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Please select a slot')),
      );
      return;
    }

    try {
      await FirebaseService.bookSlot(
        widget.keyId,
        selectedSlot, // Use local variable instead of _selectedSlot!
        _selectedDurationMinutes,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationPage(
            slotId: selectedSlot, // Use local variable here too
            place: widget.name,
            durationMinutes: _selectedDurationMinutes,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Booking failed: $e')),
      );
    }
  }
  Widget _buildSlotGrid() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No slots available for this parking area',
            style: TextStyle(fontSize: 16),
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
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final isSelected = _selectedSlot == slot['id'];
        final isAvailable = slot['available'];

        // Calculate time remaining if slot is booked
        String? timeRemaining;
        if (!isAvailable && slot.containsKey('bookedUntil')) {
          try {
            final bookedUntil = DateTime.parse(slot['bookedUntil'].toString());
            final now = DateTime.now();
            if (bookedUntil.isAfter(now)) {
              final diff = bookedUntil.difference(now);
              if (diff.inHours > 0) {
                timeRemaining = '${diff.inHours}h ${diff.inMinutes % 60}m';
              } else {
                timeRemaining = '${diff.inMinutes}m';
              }
            }
          } catch (e) {
            print('Error calculating time remaining: $e');
          }
        }

        return GestureDetector(
          onTap: isAvailable
              ? () {
            setState(() {
              _selectedSlot = slot['id'];
            });
          }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isAvailable
                  ? (isSelected ? Colors.blue : Colors.green)
                  : Colors.red.shade300,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot['id'],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (timeRemaining != null)
                  Text(
                    timeRemaining,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up resources when the page is disposed
    _slotsSubscription?.cancel();
    _localExpiryCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking: ${widget.name}')),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadSlots();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Slot:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _buildSlotGrid(),
                SizedBox(height: 24),
                Text('Select Duration (Minutes):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Slider(
                  value: _selectedDurationMinutes.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  label: '$_selectedDurationMinutes mins',
                  onChanged: (value) {
                    setState(() {
                      _selectedDurationMinutes = value.toInt();
                    });
                  },
                ),
                Center(
                  child: Text(
                    '$_selectedDurationMinutes minutes',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _bookSlot(context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Book Slot', style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
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
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Navigate to Spot', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}