import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AccountPage extends StatefulWidget {
  final String name;
  final String email;

  const AccountPage({required this.name, required this.email, Key? key})
      : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late String _name;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = widget.name.trim();
    _nameController.text = _name;
    if (_name.isEmpty || _name.toLowerCase() == 'no name') {
      _isEditing = true;
    }
  }

  Future<void> _saveName() async {
    String newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      setState(() {
        _name = newName;
        _isEditing = false;
      });
      await FirebaseService.updateUserName(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EFFF), // light purple
      appBar: AppBar(
        backgroundColor: Color(0xFF9B59B6),
        title: Text('My Account'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome Back 💜',
                style: TextStyle(fontSize: 18, color: Colors.black54)),
            SizedBox(height: 16),
            Text('ACCOUNT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 32),
            Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            if (_isEditing)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_name, style: TextStyle(fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF9B59B6),
                    ),
                    child: Text('Edit'),
                  )
                ],
              ),
            SizedBox(height: 16),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9B59B6),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Save', style: TextStyle(fontSize: 16)),
                ),
              ),
            SizedBox(height: 32),
            Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(widget.email, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}