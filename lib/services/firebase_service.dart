import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    // dont change
    databaseURL: 'https://smartapp-9b5f4-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Authentication Methods

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Error signing in with email and password: $e');
      throw e;
    }
  }

  /// Sign up with email and password
  static Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Error signing up with email and password: $e');
      throw e;
    }
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If sign in was canceled by user
      if (googleUser == null) {
        return null;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      throw e;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is signed in
  static bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
//dont change
  // Realtime Database Methods

  /// Get all parking areas raw
  static Future<Map<String, dynamic>> getParkingAreas() async {
    final ref = _db.ref('parking_areas');
    final snapshot = await ref.get();

    print('Fetching parking areas...');

    if (snapshot.exists) {
      Map<String, dynamic> result = Map<String, dynamic>.from(snapshot.value as Map);
      print('Found ${result.length} parking areas');
      return result;
    } else {
      print('No parking areas found');
      return {};
    }
  }

  /// Get available slots only, and auto-free if expired
  static Future<List<Map<String, dynamic>>> getAvailableSlots(
      String parkingId) async {
    final ref = _db.ref('parking_areas/$parkingId/slots');
    final snapshot = await ref.get();

    List<Map<String, dynamic>> slots = [];
    if (snapshot.exists) {
      Map<String, dynamic> data = Map<String, dynamic>.from(
          snapshot.value as Map);

      // Debug print to see the raw data
      print('Raw slots data: $data');

      data.forEach((key, value) {
        bool isAvailable = true;

        // Check if value is a Map (some data structures might have direct boolean values)
        if (value is Map) {
          // Try to get the 'available' field directly from the data
          if (value.containsKey('available')) {
            isAvailable = value['available'] == true;
          }

          // Also check for booking expiration if bookedUntil exists
          if (value['bookedUntil'] != null) {
            try {
              DateTime bookedUntil = DateTime.parse(value['bookedUntil']);
              if (DateTime.now().isBefore(bookedUntil)) {
                isAvailable = false;
              } else {
                // Free stale slot
                ref.child(key).update({"bookedUntil": null});
              }
            } catch (e) {
              print('Error parsing bookedUntil date for slot $key: $e');
            }
          }
        } else if (value is bool) {
          // Some data structures might store availability directly as a boolean
          isAvailable = value;
        }

        slots.add({'id': key, 'available': isAvailable});
      });
    }

    // Print the processed slots for debugging
    print('Processed ${slots.length} slots');
    slots.forEach((slot) {
      print('Slot: ${slot['id']}, Available: ${slot['available']}');
    });

    return slots;
  }

  /// Book specific slot with duration in minutes
  static Future<void> bookSlot(String parkingId, String slotId,
      int durationMinutes) async {
    final ref = _db.ref('parking_areas/$parkingId/slots/$slotId');

    DateTime bookedUntil = DateTime.now().add(
        Duration(minutes: durationMinutes));

    // First check the current structure of the slot
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final value = snapshot.value;

      // If it's a direct boolean value
      if (value is bool) {
        // Create a new structure with both available and bookedUntil
        await ref.set({
          "available": false,
          "bookedUntil": bookedUntil.toUtc().toIso8601String(),
        });
      }
      // If it's already a map structure
      else if (value is Map) {
        // Just update the existing fields
        await ref.update({
          "available": false,
          "bookedUntil": bookedUntil.toUtc().toIso8601String(),
        });
      }
    } else {
      // If the slot doesn't exist yet, create it
      await ref.set({
        "available": false,
        "bookedUntil": bookedUntil.toUtc().toIso8601String(),
      });
    }
  }

  /// Save user data to the database
  static Future<void> saveUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _db.ref('users/$uid').set(userData);
    } catch (e) {
      print('Error saving user data: $e');
      throw e;
    }
  }

  /// Get user data from the database
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid').get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      throw e;
    }
  }
}