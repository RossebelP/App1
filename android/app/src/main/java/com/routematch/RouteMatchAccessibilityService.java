// android/app/src/main/java/com/routematch/RouteMatchAccessibilityService.java
package com.routematch;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.Intent;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RouteMatchAccessibilityService extends AccessibilityService {

    private static final String TAG = "RouteMatchA11y";

    // Package names of monitored apps
    private static final String[] MONITORED_PACKAGES = {
        "com.ubercab.eats",
        "com.grability.rappi",
        "com.xiaojukeji.didi.customer"
    };

    // Regex patterns for address detection (Spanish/Mexican addresses)
    private static final Pattern[] ADDRESS_PATTERNS = {
        // Calle + number
        Pattern.compile("(?i)(calle|av\\.?|avenida|blvd\\.?|boulevard|calzada|paseo)\\s+[\\w\\s]+\\d+"),
        // Street number + colonia
        Pattern.compile("(?i)[\\w\\s]+\\d+,\\s+[\\w\\s]+(?:,\\s*[A-Z]{2,})?"),
        // Colonia/Col. + name
        Pattern.compile("(?i)(?:col\\.?|colonia)\\s+[\\w\\s]+"),
    };

    // Broadcast action key
    public static final String ACTION_ORDER_DETECTED =
        "com.routematch.ORDER_DETECTED";
    public static final String EXTRA_ADDRESS = "address";
    public static final String EXTRA_APP_PACKAGE = "app_package";
    public static final String EXTRA_RAW_TEXT = "raw_text";

    private String lastDetectedAddress = "";
    private long lastDetectedTime = 0;
    private static final long DETECTION_COOLDOWN_MS = 3000;

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        AccessibilityServiceInfo info = new AccessibilityServiceInfo();
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            | AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            | AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED;
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC;
        info.flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            | AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS;
        info.notificationTimeout = 100;
        info.packageNames = MONITORED_PACKAGES;
        setServiceInfo(info);

        Log.d(TAG, "RouteMatch Accessibility Service connected");

        // Notify Flutter that service is active
        broadcastServiceStatus(true);
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;

        String packageName = "";
        if (event.getPackageName() != null) {
            packageName = event.getPackageName().toString();
        }

        if (!isMonitoredApp(packageName)) return;

        // Cooldown to avoid duplicate detections
        long now = System.currentTimeMillis();
        if (now - lastDetectedTime < DETECTION_COOLDOWN_MS) return;

        // Extract all text from the current window
        AccessibilityNodeInfo rootNode = getRootInActiveWindow();
        if (rootNode == null) return;

        List<String> allText = new ArrayList<>();
        extractTextFromNode(rootNode, allText);
        rootNode.recycle();

        String fullText = String.join(" ", allText);

        // Check if this looks like a new order screen
        if (isOrderScreen(fullText, packageName)) {
            String address = extractAddress(fullText, packageName);
            if (address != null && !address.equals(lastDetectedAddress)) {
                lastDetectedAddress = address;
                lastDetectedTime = now;
                Log.d(TAG, "Detected new order: " + address + " from " + packageName);
                broadcastOrderDetected(address, packageName, fullText);
            }
        }
    }

    private void extractTextFromNode(AccessibilityNodeInfo node, List<String> texts) {
        if (node == null) return;
        if (node.getText() != null) {
            String text = node.getText().toString().trim();
            if (!text.isEmpty()) {
                texts.add(text);
            }
        }
        if (node.getContentDescription() != null) {
            String desc = node.getContentDescription().toString().trim();
            if (!desc.isEmpty()) {
                texts.add(desc);
            }
        }
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) {
                extractTextFromNode(child, texts);
                child.recycle();
            }
        }
    }

    private boolean isOrderScreen(String text, String packageName) {
        String lowerText = text.toLowerCase();

        // Keywords that indicate a new order notification
        String[] orderKeywords = {
            "nuevo pedido", "new order", "nueva orden",
            "pickup", "recoger en", "recoge en",
            "entregar en", "deliver to", "drop off",
            "¿aceptas?", "accept trip", "aceptar viaje",
            "ganancia", "earnings", "tarifa"
        };

        for (String keyword : orderKeywords) {
            if (lowerText.contains(keyword)) {
                return true;
            }
        }

        // App-specific checks
        switch (packageName) {
            case "com.ubercab.eats":
                return lowerText.contains("deliver") || lowerText.contains("pickup");
            case "com.grability.rappi":
                return lowerText.contains("pedido") && lowerText.contains("recoger");
            case "com.xiaojukeji.didi.customer":
                return lowerText.contains("orden") || lowerText.contains("entrega");
        }
        return false;
    }

    private String extractAddress(String text, String packageName) {
        // Try each regex pattern
        for (Pattern pattern : ADDRESS_PATTERNS) {
            Matcher matcher = pattern.matcher(text);
            if (matcher.find()) {
                String match = matcher.group().trim();
                if (match.length() > 5) {
                    return cleanAddress(match);
                }
            }
        }

        // Fallback: look for lines with numbers that look like addresses
        String[] lines = text.split("[\\n,]");
        for (String line : lines) {
            line = line.trim();
            if (line.matches(".*\\d+.*") && line.length() > 8 && line.length() < 100) {
                if (looksLikeAddress(line)) {
                    return cleanAddress(line);
                }
            }
        }
        return null;
    }

    private boolean looksLikeAddress(String text) {
        String lower = text.toLowerCase();
        String[] addressIndicators = {
            "calle", "av.", "avenida", "blvd", "col.", "colonia",
            "int.", "local", "piso", "depto", "departamento",
            "#", "no.", "num."
        };
        for (String indicator : addressIndicators) {
            if (lower.contains(indicator)) return true;
        }
        // Has a street number pattern
        return text.matches(".*[A-Za-z]\\s+\\d{1,5}.*");
    }

    private String cleanAddress(String address) {
        return address
            .replaceAll("\\s+", " ")
            .replaceAll("[^\\w\\s.,#-]", "")
            .trim();
    }

    private boolean isMonitoredApp(String packageName) {
        for (String pkg : MONITORED_PACKAGES) {
            if (pkg.equals(packageName)) return true;
        }
        return false;
    }

    private void broadcastOrderDetected(String address, String appPackage, String rawText) {
        Intent intent = new Intent(ACTION_ORDER_DETECTED);
        intent.putExtra(EXTRA_ADDRESS, address);
        intent.putExtra(EXTRA_APP_PACKAGE, appPackage);
        intent.putExtra(EXTRA_RAW_TEXT, rawText.substring(0, Math.min(rawText.length(), 500)));
        sendBroadcast(intent);
    }

    private void broadcastServiceStatus(boolean active) {
        Intent intent = new Intent("com.routematch.SERVICE_STATUS");
        intent.putExtra("active", active);
        sendBroadcast(intent);
    }

    @Override
    public void onInterrupt() {
        Log.d(TAG, "RouteMatch Accessibility Service interrupted");
        broadcastServiceStatus(false);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        broadcastServiceStatus(false);
    }
}
