// lib/services/native_bridge.dart
import 'package:flutter/services.dart';
import 'dart:async';

typedef OrderDetectedCallback = void Function(Map<String, dynamic> orderData);

class NativeBridge {
  static const _methodChannel = MethodChannel('com.routematch/accessibility');
  static const _eventChannel = EventChannel('com.routematch/orders');

  static StreamSubscription? _orderSubscription;
  static OrderDetectedCallback? _onOrderDetected;

  /// Check if Accessibility Service is enabled
  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _methodChannel.invokeMethod('isAccessibilityEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open Android Accessibility Settings
  static Future<void> openAccessibilitySettings() async {
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  /// Open Notification Settings
  static Future<void> openNotificationSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  /// Start listening for orders detected by the Accessibility Service
  static void startListening(OrderDetectedCallback callback) {
    _onOrderDetected = callback;
    _orderSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen((event) {
      if (event is Map && _onOrderDetected != null) {
        _onOrderDetected!(Map<String, dynamic>.from(event));
      }
    }, onError: (error) {
      // Handle errors gracefully
    });
  }

  /// Stop listening for orders
  static void stopListening() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _onOrderDetected = null;
  }

  /// Map package name to DeliveryApp enum index
  static int packageToAppIndex(String packageName) {
    switch (packageName) {
      case 'com.ubercab.eats': return 0;      // DeliveryApp.uberEats
      case 'com.grability.rappi': return 1;    // DeliveryApp.rappi
      case 'com.xiaojukeji.didi.customer': return 2; // DeliveryApp.didi
      default: return 3;                        // DeliveryApp.other
    }
  }
}
