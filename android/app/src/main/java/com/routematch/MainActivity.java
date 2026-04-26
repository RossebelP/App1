// android/app/src/main/java/com/routematch/MainActivity.java
package com.routematch;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.provider.Settings;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String METHOD_CHANNEL = "com.routematch/accessibility";
    private static final String EVENT_CHANNEL = "com.routematch/orders";

    private EventChannel.EventSink orderEventSink;
    private BroadcastReceiver orderReceiver;
    private BroadcastReceiver statusReceiver;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Method channel: Flutter → Android
        new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            METHOD_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "isAccessibilityEnabled":
                    result.success(isAccessibilityServiceEnabled());
                    break;
                case "openAccessibilitySettings":
                    startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
                    result.success(null);
                    break;
                case "openNotificationSettings":
                    startActivity(new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, getPackageName()));
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
            }
        });

        // Event channel: Android → Flutter (streaming order events)
        new EventChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            EVENT_CHANNEL
        ).setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                orderEventSink = events;
                registerReceivers();
            }

            @Override
            public void onCancel(Object arguments) {
                orderEventSink = null;
                unregisterReceivers();
            }
        });
    }

    private void registerReceivers() {
        // Order detected receiver
        orderReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (orderEventSink == null) return;
                String address = intent.getStringExtra(
                    RouteMatchAccessibilityService.EXTRA_ADDRESS);
                String appPackage = intent.getStringExtra(
                    RouteMatchAccessibilityService.EXTRA_APP_PACKAGE);
                String rawText = intent.getStringExtra(
                    RouteMatchAccessibilityService.EXTRA_RAW_TEXT);

                java.util.Map<String, String> data = new java.util.HashMap<>();
                data.put("address", address != null ? address : "");
                data.put("appPackage", appPackage != null ? appPackage : "");
                data.put("rawText", rawText != null ? rawText : "");
                data.put("timestamp", String.valueOf(System.currentTimeMillis()));

                orderEventSink.success(data);
            }
        };

        // Service status receiver
        statusReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                // Handle status updates if needed
            }
        };

        IntentFilter orderFilter = new IntentFilter(
            RouteMatchAccessibilityService.ACTION_ORDER_DETECTED);
        IntentFilter statusFilter = new IntentFilter("com.routematch.SERVICE_STATUS");

        registerReceiver(orderReceiver, orderFilter);
        registerReceiver(statusReceiver, statusFilter);
    }

    private void unregisterReceivers() {
        if (orderReceiver != null) {
            try { unregisterReceiver(orderReceiver); } catch (Exception ignored) {}
        }
        if (statusReceiver != null) {
            try { unregisterReceiver(statusReceiver); } catch (Exception ignored) {}
        }
    }

    private boolean isAccessibilityServiceEnabled() {
        String serviceName = getPackageName() + "/" +
            RouteMatchAccessibilityService.class.getCanonicalName();
        try {
            int enabled = Settings.Secure.getInt(
                getContentResolver(),
                Settings.Secure.ACCESSIBILITY_ENABLED, 0);
            if (enabled == 1) {
                String settingValue = Settings.Secure.getString(
                    getContentResolver(),
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
                if (settingValue != null) {
                    return settingValue.contains(serviceName);
                }
            }
        } catch (Settings.SettingNotFoundException e) {
            return false;
        }
        return false;
    }

    @Override
    protected void onDestroy() {
        unregisterReceivers();
        super.onDestroy();
    }
}
