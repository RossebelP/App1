// lib/models/order_model.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';

enum DeliveryApp { uberEats, rappi, didi, other }
enum OrderDecision { accepted, ignored, pending }

extension DeliveryAppExt on DeliveryApp {
  String get displayName {
    switch (this) {
      case DeliveryApp.uberEats: return 'Uber Eats';
      case DeliveryApp.rappi: return 'Rappi';
      case DeliveryApp.didi: return 'DiDi Food';
      case DeliveryApp.other: return 'Otra app';
    }
  }

  String get packageName {
    switch (this) {
      case DeliveryApp.uberEats: return 'com.ubercab.eats';
      case DeliveryApp.rappi: return 'com.grability.rappi';
      case DeliveryApp.didi: return 'com.xiaojukeji.didi.customer';
      case DeliveryApp.other: return '';
    }
  }

  Color get color {
    switch (this) {
      case DeliveryApp.uberEats: return AppColors.uberEats;
      case DeliveryApp.rappi: return AppColors.rappi;
      case DeliveryApp.didi: return AppColors.didi;
      case DeliveryApp.other: return AppColors.textSecondary;
    }
  }

  String get emoji {
    switch (this) {
      case DeliveryApp.uberEats: return '🛵';
      case DeliveryApp.rappi: return '🎒';
      case DeliveryApp.didi: return '🍊';
      case DeliveryApp.other: return '📦';
    }
  }
}

class ActiveOrder {
  final String id;
  final DeliveryApp app;
  final String address;
  final String neighborhood;
  final double distanceKm;
  final int estimatedMinutes;
  final double lat;
  final double lng;

  ActiveOrder({
    required this.id,
    required this.app,
    required this.address,
    required this.neighborhood,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.lat,
    required this.lng,
  });
}

class DetectedOrder {
  final String id;
  final DeliveryApp app;
  final String rawAddress;
  final String neighborhood;
  final double detourKm;
  final int extraMinutes;
  final double estimatedEarnings;
  final double lat;
  final double lng;
  final DateTime detectedAt;
  OrderDecision decision;

  DetectedOrder({
    required this.id,
    required this.app,
    required this.rawAddress,
    required this.neighborhood,
    required this.detourKm,
    required this.extraMinutes,
    required this.estimatedEarnings,
    required this.lat,
    required this.lng,
    required this.detectedAt,
    this.decision = OrderDecision.pending,
  });

  bool meetsFilters({
    required int maxMinutes,
    required double maxKm,
    required double minEarnings,
    required List<DeliveryApp> enabledApps,
  }) {
    return enabledApps.contains(app) &&
        extraMinutes <= maxMinutes &&
        detourKm <= maxKm &&
        estimatedEarnings >= minEarnings;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'app': app.index,
    'rawAddress': rawAddress,
    'neighborhood': neighborhood,
    'detourKm': detourKm,
    'extraMinutes': extraMinutes,
    'estimatedEarnings': estimatedEarnings,
    'lat': lat,
    'lng': lng,
    'detectedAt': detectedAt.toIso8601String(),
    'decision': decision.index,
  };

  factory DetectedOrder.fromJson(Map<String, dynamic> json) => DetectedOrder(
    id: json['id'],
    app: DeliveryApp.values[json['app']],
    rawAddress: json['rawAddress'],
    neighborhood: json['neighborhood'],
    detourKm: json['detourKm'],
    extraMinutes: json['extraMinutes'],
    estimatedEarnings: json['estimatedEarnings'],
    lat: json['lat'],
    lng: json['lng'],
    detectedAt: DateTime.parse(json['detectedAt']),
    decision: OrderDecision.values[json['decision']],
  );
}

class UserSettings {
  int maxDetourMinutes;
  double maxDetourKm;
  double minEarnings;
  bool monitorUberEats;
  bool monitorRappi;
  bool monitorDidi;
  bool monitorOther;
  String googleMapsApiKey;

  UserSettings({
    this.maxDetourMinutes = 10,
    this.maxDetourKm = 3.0,
    this.minEarnings = 50.0,
    this.monitorUberEats = true,
    this.monitorRappi = true,
    this.monitorDidi = true,
    this.monitorOther = false,
    this.googleMapsApiKey = '',
  });

  List<DeliveryApp> get enabledApps {
    final apps = <DeliveryApp>[];
    if (monitorUberEats) apps.add(DeliveryApp.uberEats);
    if (monitorRappi) apps.add(DeliveryApp.rappi);
    if (monitorDidi) apps.add(DeliveryApp.didi);
    if (monitorOther) apps.add(DeliveryApp.other);
    return apps;
  }

  Map<String, dynamic> toJson() => {
    'maxDetourMinutes': maxDetourMinutes,
    'maxDetourKm': maxDetourKm,
    'minEarnings': minEarnings,
    'monitorUberEats': monitorUberEats,
    'monitorRappi': monitorRappi,
    'monitorDidi': monitorDidi,
    'monitorOther': monitorOther,
    'googleMapsApiKey': googleMapsApiKey,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    maxDetourMinutes: json['maxDetourMinutes'] ?? 10,
    maxDetourKm: (json['maxDetourKm'] ?? 3.0).toDouble(),
    minEarnings: (json['minEarnings'] ?? 50.0).toDouble(),
    monitorUberEats: json['monitorUberEats'] ?? true,
    monitorRappi: json['monitorRappi'] ?? true,
    monitorDidi: json['monitorDidi'] ?? true,
    monitorOther: json['monitorOther'] ?? false,
    googleMapsApiKey: json['googleMapsApiKey'] ?? '',
  );
}
