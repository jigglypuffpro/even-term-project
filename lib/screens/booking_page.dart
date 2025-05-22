import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firebase_service.dart';
import 'navigation_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSlots();
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
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Please select a slot')),
      );
      return;
    }

    try {
      await FirebaseService.bookSlot(widget.keyId, _selectedSlot!, _selectedDurationMinutes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Slot booked for $_selectedDurationMinutes minutes!')),
      );
      _loadSlots(); // Refresh after booking
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
            child: Text(
              slot['id'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
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