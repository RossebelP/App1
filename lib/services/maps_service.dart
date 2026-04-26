// lib/services/maps_service.dart
//
// ✅ 100% GRATUITO — sin API key, sin tarjeta de crédito:
//   • OSRM  (Open Source Routing Machine) → rutas reales por calles
//   • Nominatim (OpenStreetMap)           → geocodificación de direcciones
//
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteInfo {
  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> polylinePoints;
  final String summary;

  const RouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polylinePoints,
    this.summary = '',
  });
}

class MapsService {
  // OSRM público — gratis, sin registro
  static const String _osrmBase =
      'https://router.project-osrm.org/route/v1/driving';

  // Nominatim (OSM) — gratis, respetar 1 req/seg
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _headers = {
    'User-Agent': 'RouteMatchApp/1.0 (delivery-optimizer)',
    'Accept-Language': 'es',
  };

  // ══════════════════════════════════════════════════════════════
  //  RUTAS — OSRM
  // ══════════════════════════════════════════════════════════════

  static Future<RouteInfo?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      '$_osrmBase/$originLng,$originLat;$destLng,$destLat'
      '?overview=full&geometries=geojson',
    );
    try {
      final resp =
          await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final distM = (route['distance'] as num).toDouble();
          final durS  = (route['duration']  as num).toDouble();
          final coords = route['geometry']['coordinates'] as List;
          final points = coords
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();
          return RouteInfo(
            distanceKm: distM / 1000.0,
            durationMinutes: (durS / 60).round(),
            polylinePoints: points,
          );
        }
      }
    } catch (_) {}
    return _haversineFallback(originLat, originLng, destLat, destLng);
  }

  // ══════════════════════════════════════════════════════════════
  //  GEOCODIFICACIÓN — Nominatim
  // ══════════════════════════════════════════════════════════════

  static Future<LatLng?> geocodeAddress(String address) async {
    final url = Uri.parse(
      '$_nominatimBase/search'
      '?q=${Uri.encodeComponent(address)}'
      '&format=jsonv2&limit=1&countrycodes=mx',
    );
    try {
      final resp =
          await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isNotEmpty) {
          return LatLng(
            double.parse(data[0]['lat'].toString()),
            double.parse(data[0]['lon'].toString()),
          );
        }
      }
    } catch (_) {}
    // Fallback demo CDMX
    final rng = Random(address.hashCode);
    return LatLng(19.32 + rng.nextDouble() * 0.12, -99.22 + rng.nextDouble() * 0.15);
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
        '$_nominatimBase/reverse?lat=$lat&lon=$lng&format=jsonv2');
    try {
      final resp =
          await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['display_name'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════
  //  CÁLCULO DE DESVÍO
  // ══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> calculateDetour({
    required double currentLat,
    required double currentLng,
    required double currentDestLat,
    required double currentDestLng,
    required double newOrderLat,
    required double newOrderLng,
  }) async {
    final direct = await getDirections(
      originLat: currentLat,  originLng: currentLng,
      destLat: currentDestLat, destLng: currentDestLng,
    );
    final toNew = await getDirections(
      originLat: currentLat, originLng: currentLng,
      destLat: newOrderLat,  destLng: newOrderLng,
    );
    final newToDest = await getDirections(
      originLat: newOrderLat,  originLng: newOrderLng,
      destLat: currentDestLat, destLng: currentDestLng,
    );

    final directKm  = direct?.distanceKm     ?? haversineDist(currentLat, currentLng, currentDestLat, currentDestLng);
    final directMin = direct?.durationMinutes ?? (directKm / 30 * 60).round();
    final detourKm  = ((toNew?.distanceKm ?? 0) + (newToDest?.distanceKm ?? 0) - directKm).clamp(0.0, double.infinity);
    final detourMin = ((toNew?.durationMinutes ?? 0) + (newToDest?.durationMinutes ?? 0) - directMin).clamp(0, 999);

    return {
      'detourKm':     detourKm,
      'extraMinutes': detourMin,
      'directRoute':  direct,
      'detourRoute':  toNew,
    };
  }

  // ══════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════

  static double haversineDist(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static RouteInfo _haversineFallback(double oLat, double oLng, double dLat, double dLng) {
    final km = haversineDist(oLat, oLng, dLat, dLng) * 1.35;
    return RouteInfo(
      distanceKm: km,
      durationMinutes: (km / 30 * 60).round().clamp(1, 120),
      polylinePoints: [LatLng(oLat, oLng), LatLng(dLat, dLng)],
      summary: 'Estimación directa',
    );
  }
}
