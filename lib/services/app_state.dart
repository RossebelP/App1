// lib/services/app_state.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import 'location_service.dart';
import 'maps_service.dart';

class AppState
    extends ChangeNotifier {
  UserSettings
      _settings =
      UserSettings();
  ActiveOrder?
      _activeOrder;
  List<DetectedOrder>
      _todayOrders =
      [];
  DetectedOrder?
      _pendingAlert;
  bool
      _accessibilityActive =
      false;

  // GPS en tiempo real
  final LocationService
      locationService =
      LocationService();

  UserSettings get settings =>
      _settings;
  ActiveOrder? get activeOrder =>
      _activeOrder;
  List<DetectedOrder> get todayOrders =>
      _todayOrders;
  DetectedOrder? get pendingAlert =>
      _pendingAlert;
  bool get accessibilityActive =>
      _accessibilityActive;

  // ── Estadísticas del día ─────────────────────────────────────────────────
  double get totalEarnings => _todayOrders.where((o) => o.decision == OrderDecision.accepted).fold(
      0.0,
      (sum, o) => sum + o.estimatedEarnings);

  double get kmSaved => _todayOrders.where((o) => o.decision == OrderDecision.ignored).fold(
      0.0,
      (sum, o) => sum + o.detourKm);

  int get ordersAccepted => _todayOrders
      .where((o) => o.decision == OrderDecision.accepted)
      .length;

  int get ordersIgnored => _todayOrders
      .where((o) => o.decision == OrderDecision.ignored)
      .length;

  // ── Inicialización ───────────────────────────────────────────────────────
  Future<void>
      loadSettings() async {
    final prefs =
        await SharedPreferences.getInstance();
    final json =
        prefs.getString('user_settings');
    if (json !=
        null) {
      _settings = UserSettings.fromJson(jsonDecode(json));
    }
    final ordersJson =
        prefs.getStringList('today_orders') ?? [];
    _todayOrders =
        ordersJson.map((j) => DetectedOrder.fromJson(jsonDecode(j))).toList();
    notifyListeners();

    // Arrancar GPS automáticamente
    locationService.addListener(_onLocationChanged);
    await locationService.startTracking();
  }

  void
      _onLocationChanged() {
    notifyListeners();
  }

  // ── Guardar configuración ────────────────────────────────────────────────
  Future<void>
      saveSettings() async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setString('user_settings',
        jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  void setAccessibilityActive(
      bool active) {
    _accessibilityActive =
        active;
    notifyListeners();
  }

  // ── Pedido activo (actualizado desde GPS) ────────────────────────────────
  void setActiveOrder(
      ActiveOrder? order) {
    _activeOrder =
        order;
    notifyListeners();
  }

  /// Simula un pedido activo para demo. En producción se setea desde
  /// el Accessibility Service cuando detecta que el repartidor ya tiene un pedido.
  void
      simulateActiveOrder() {
    // Usar posición GPS real si está disponible
    final gps =
        locationService.currentLatLng;
    _activeOrder =
        ActiveOrder(
      id: 'order_001',
      app: DeliveryApp.uberEats,
      address: 'Av. Insurgentes Sur 1457, Del Valle',
      neighborhood: 'Del Valle',
      distanceKm: 2.4,
      estimatedMinutes: 8,
      lat: gps?.latitude ?? 19.3738,
      lng: gps?.longitude ?? -99.1677,
    );
    _accessibilityActive =
        true;
    notifyListeners();
  }

  // ── Detectar y evaluar pedido nuevo ─────────────────────────────────────
  void triggerOrderAlert(
      DetectedOrder order) {
    _pendingAlert =
        order;
    _todayOrders.insert(0,
        order);
    _saveOrders();
    notifyListeners();
  }

  void
      dismissAlert() {
    _pendingAlert =
        null;
    notifyListeners();
  }

  void decideOrder(
      String orderId,
      OrderDecision decision) {
    final idx = _todayOrders.indexWhere((o) =>
        o.id ==
        orderId);
    if (idx !=
        -1) {
      _todayOrders[idx].decision = decision;
      _saveOrders();
    }
    if (_pendingAlert?.id ==
        orderId)
      _pendingAlert = null;
    notifyListeners();
  }

  /// Simula un pedido entrante con cálculo real OSRM desde posición GPS.
  Future<void>
      simulateIncomingOrder() async {
    final userPos =
        locationService.currentLatLng;
    final destLat =
        _activeOrder?.lat ?? 19.3738;
    final destLng =
        _activeOrder?.lng ?? -99.1677;

    // Punto de pedido nuevo aleatorio cercano
    final newLat =
        (userPos?.latitude ?? destLat) + 0.015;
    final newLng =
        (userPos?.longitude ?? destLng) - 0.008;

    // Calcular desvío real con OSRM
    double
        detourKm =
        1.8;
    int extraMins =
        6;
    try {
      final result = await MapsService.calculateDetour(
        currentLat: userPos?.latitude ?? destLat,
        currentLng: userPos?.longitude ?? destLng,
        currentDestLat: destLat,
        currentDestLng: destLng,
        newOrderLat: newLat,
        newOrderLng: newLng,
      );
      detourKm = (result['detourKm'] as double).clamp(0.3, 20.0);
      extraMins = (result['extraMinutes'] as int).clamp(1, 60);
    } catch (_) {}

    final order =
        DetectedOrder(
      id: 'det_${DateTime.now().millisecondsSinceEpoch}',
      app: DeliveryApp.rappi,
      rawAddress: 'Calle Millet 32, Nápoles, CDMX',
      neighborhood: 'Nápoles',
      detourKm: detourKm,
      extraMinutes: extraMins,
      estimatedEarnings: 78.0,
      lat: newLat,
      lng: newLng,
      detectedAt: DateTime.now(),
    );
    triggerOrderAlert(order);
  }

  Future<void>
      _saveOrders() async {
    final prefs =
        await SharedPreferences.getInstance();
    final today =
        DateTime.now();
    final filtered =
        _todayOrders.where((o) => o.detectedAt.year == today.year && o.detectedAt.month == today.month && o.detectedAt.day == today.day).toList();
    await prefs.setStringList(
      'today_orders',
      filtered.map((o) => jsonEncode(o.toJson())).toList(),
    );
  }

  void
      clearHistory() {
    _todayOrders.clear();
    _saveOrders();
    notifyListeners();
  }

  @override
  void
      dispose() {
    locationService.removeListener(_onLocationChanged);
    locationService.dispose();
    super.dispose();
  }
}
