import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firebase_service.dart';
import 'navigation_page.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'booking_confirmation_page.dart';

const Color kPrimaryColor = Color(0xFF6A1B9A); // Deep purple
const Color kAccentColor = Color(0xFF9C27B0);  // Lighter purple
const Color kBackgroundColor = Color(0xFFF3E5F5); // Light lavender background
const Color kSlotAvailableColor = Color(0xFF81C784); // Green
const Color kSlotUnavailableColor = Color(0xFFE57373); // Red
const Color kSlotSelectedColor = kPrimaryColor;

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
    _localExpiryCheckTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) _checkForExpiredBookings();
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
        } catch (_) {}
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
        if (value.containsKey('available')) isAvailable = value['available'] == true;
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
          } catch (_) {}
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
    final ref = FirebaseDatabase.instance.ref('parking_areas/${widget.keyId}/slots/$slotId');
    await ref.update({"available": true, "bookedUntil": null});
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
      setState(() => _isLoading = false);
    }
  }

  void _bookSlot(BuildContext context) async {
    final selectedSlot = _selectedSlot;
    if (selectedSlot == null) return;
    try {
      await FirebaseService.bookSlot(widget.keyId, selectedSlot, _selectedDurationMinutes);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationPage(
            slotId: selectedSlot,
            place: widget.name,
            durationMinutes: _selectedDurationMinutes,
          ),
        ),
      );
    } catch (_) {}
  }

  Widget _buildSlotGrid() {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_slots.isEmpty) return Center(child: Text('No slots available'));

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
        String? timeRemaining;
        if (!isAvailable && slot.containsKey('bookedUntil')) {
          try {
            final bookedUntil = DateTime.parse(slot['bookedUntil'].toString());
            final now = DateTime.now();
            if (bookedUntil.isAfter(now)) {
              final diff = bookedUntil.difference(now);
              timeRemaining = diff.inHours > 0
                  ? '${diff.inHours}h ${diff.inMinutes % 60}m'
                  : '${diff.inMinutes}m';
            }
          } catch (_) {}
        }

        return GestureDetector(
          onTap: isAvailable ? () => setState(() => _selectedSlot = slot['id']) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isAvailable
                  ? (isSelected ? kSlotSelectedColor : kSlotAvailableColor)
                  : kSlotUnavailableColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot['id'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (timeRemaining != null)
                  Text(timeRemaining, style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
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
        ),
        body: RefreshIndicator(
          onRefresh: () async => _loadSlots(),
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
                  Center(child: Text('$_selectedDurationMinutes minutes', style: TextStyle(fontSize: 16))),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _bookSlot(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A148C), // Dark purple
                          foregroundColor: Colors.white, // Light text
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: Icon(Icons.book_online),
                        label: Text('Book Slot', style: TextStyle(fontSize: 16)),
                      ),

                      ElevatedButton.icon(
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
                          backgroundColor: Color(0xFF4A148C), // Dark purple
                          foregroundColor: Colors.white, // Light text
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: Icon(Icons.navigation),
                        label: Text('Navigate to Spot', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
