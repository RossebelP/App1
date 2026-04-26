// lib/services/location_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'maps_service.dart';

class LocationState {
  final LatLng position;
  final double speedKmh;
  final double headingDeg;
  final double accuracyM;
  final DateTime timestamp;
  final String? addressLabel;

  const LocationState({
    required this.position,
    required this.speedKmh,
    required this.headingDeg,
    required this.accuracyM,
    required this.timestamp,
    this.addressLabel,
  });

  LocationState copyWith({String? addressLabel}) => LocationState(
        position: position,
        speedKmh: speedKmh,
        headingDeg: headingDeg,
        accuracyM: accuracyM,
        timestamp: timestamp,
        addressLabel: addressLabel ?? this.addressLabel,
      );
}

class LocationService extends ChangeNotifier {
  LocationState? _current;
  StreamSubscription<Position>? _sub;
  bool _isTracking = false;
  String? _errorMessage;

  LocationState? get current       => _current;
  bool           get isTracking    => _isTracking;
  String?        get errorMessage  => _errorMessage;
  LatLng?        get currentLatLng => _current?.position;

  Future<bool> startTracking() async {
    _errorMessage = null;

    if (!await Geolocator.isLocationServiceEnabled()) {
      _errorMessage = 'Activa el GPS del dispositivo';
      notifyListeners();
      return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _errorMessage = 'Permiso de ubicación denegado';
      notifyListeners();
      return false;
    }

    // getCurrentPosition usa desiredAccuracy (no locationSettings)
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateFromPosition(pos);
    } catch (_) {}

    // getPositionStream sí acepta LocationSettings
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      _updateFromPosition,
      onError: (e) {
        _errorMessage = 'Error GPS: $e';
        notifyListeners();
      },
    );

    _isTracking = true;
    notifyListeners();
    return true;
  }

  void stopTracking() {
    _sub?.cancel();
    _sub = null;
    _isTracking = false;
    notifyListeners();
  }

  void _updateFromPosition(Position pos) {
    _current = LocationState(
      position:   LatLng(pos.latitude, pos.longitude),
      speedKmh:   (pos.speed * 3.6).clamp(0.0, 200.0),
      headingDeg: pos.heading,
      accuracyM:  pos.accuracy,
      timestamp:  DateTime.now(),
    );
    notifyListeners();
    _fetchLabel(pos.latitude, pos.longitude);
  }

  Future<void> _fetchLabel(double lat, double lng) async {
    final label = await MapsService.reverseGeocode(lat, lng);
    if (label != null && _current != null) {
      _current = _current!.copyWith(
        addressLabel: label.split(',').take(3).map((s) => s.trim()).join(', '),
      );
      notifyListeners();
    }
  }

  static Future<LatLng?> getOnce() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
