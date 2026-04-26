// lib/widgets/osm_map_widget.dart
// 100% GRATUITO — OpenStreetMap tiles, sin API key
import 'dart:ui' as ui;   // ← prefijo para ui.Path y evitar conflicto con flutter_map
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';

class OsmMapWidget extends StatefulWidget {
  final LatLng? destination;
  final LatLng? detourPoint;
  final List<LatLng> routePoints;
  final List<LatLng> detourPoints;
  final double height;
  final bool interactive;

  const OsmMapWidget({
    super.key,
    this.destination,
    this.detourPoint,
    this.routePoints = const [],
    this.detourPoints = const [],
    this.height = 220,
    this.interactive = true,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  final MapController _mapController = MapController();
  bool _centeredOnUser = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locService, _) {
        final userPos = locService.currentLatLng;
        final center  = userPos
            ?? widget.destination
            ?? const LatLng(19.4326, -99.1332);

        if (userPos != null && !_centeredOnUser) {
          _centeredOnUser = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try { _mapController.move(userPos, 15); } catch (_) {}
          });
        }

        return SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14.5,
                    interactionOptions: InteractionOptions(
                      flags: widget.interactive
                          ? InteractiveFlag.all
                          : InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    // ── Tiles OSM gratuitos ──────────────────────────────
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.routematch',
                    ),

                    // ── Ruta activa (verde) ──────────────────────────────
                    if (widget.routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: widget.routePoints,
                            strokeWidth: 4.5,
                            color: AppColors.primary,
                            borderStrokeWidth: 2,
                            borderColor: AppColors.primaryDim,
                          ),
                        ],
                      ),

                    // ── Desvío (naranja punteado) ────────────────────────
                    if (widget.detourPoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: widget.detourPoints,
                            strokeWidth: 3.5,
                            color: AppColors.warning,
                            strokeCap: StrokeCap.round,
                            isDotted: true,
                          ),
                        ],
                      ),

                    // ── Marcadores ───────────────────────────────────────
                    MarkerLayer(
                      markers: [
                        if (userPos != null)
                          Marker(
                            point: userPos,
                            width: 52,
                            height: 52,
                            child: _UserMarker(
                              heading: locService.current?.headingDeg ?? 0,
                            ),
                          ),
                        if (widget.destination != null)
                          Marker(
                            point: widget.destination!,
                            width: 40,
                            height: 50,
                            alignment: Alignment.bottomCenter,
                            child: const _DestinationMarker(
                                color: AppColors.primary),
                          ),
                        if (widget.detourPoint != null)
                          Marker(
                            point: widget.detourPoint!,
                            width: 40,
                            height: 50,
                            alignment: Alignment.bottomCenter,
                            child: const _DestinationMarker(
                                color: AppColors.warning),
                          ),
                      ],
                    ),
                  ],
                ),

                // ── Chip velocidad GPS ───────────────────────────────────
                if (locService.isTracking && locService.current != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _SpeedChip(locService.current!),
                  ),

                // ── Botón centrar en usuario ─────────────────────────────
                if (widget.interactive && userPos != null)
                  Positioned(
                    bottom: 28,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _mapController.move(userPos, 15),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.bgHeader
                              .withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                    ),
                  ),

                // ── Sin GPS ──────────────────────────────────────────────
                if (!locService.isTracking)
                  Positioned(
                    bottom: 28,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bgHeader
                            .withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off_rounded,
                              size: 12, color: AppColors.warning),
                          SizedBox(width: 5),
                          Text('GPS desactivado',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                // ── Atribución OSM (obligatoria por licencia) ────────────
                Positioned(
                  bottom: 4,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('© OpenStreetMap contributors',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Marcador usuario animado ──────────────────────────────────────────────────
class _UserMarker extends StatefulWidget {
  final double heading;
  const _UserMarker({required this.heading});

  @override
  State<_UserMarker> createState() => _UserMarkerState();
}

class _UserMarkerState extends State<_UserMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de precisión pulsante
          Container(
            width: 48 * _scale.value,
            height: 48 * _scale.value,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.4),
                  width: 1),
            ),
          ),
          // Punto central
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x664A90E2),
                    blurRadius: 8,
                    spreadRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pin de destino ────────────────────────────────────────────────────────────
class _DestinationMarker extends StatelessWidget {
  final Color color;
  const _DestinationMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.5), blurRadius: 8)
            ],
          ),
          child: const Icon(Icons.place_rounded,
              color: Colors.white, size: 14),
        ),
        // Cola del pin — usa ui.Path para evitar conflicto con flutter_map
        CustomPaint(
          size: const Size(10, 8),
          painter: _PinTail(color),
        ),
      ],
    );
  }
}

class _PinTail extends CustomPainter {
  final Color color;
  const _PinTail(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // ui.Path explícito — flutter_map también tiene Path<LatLng>
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Chip de velocidad ─────────────────────────────────────────────────────────
class _SpeedChip extends StatelessWidget {
  final LocationState loc;
  const _SpeedChip(this.loc);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgHeader.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.speedKmh.toStringAsFixed(0),
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w900),
          ),
          const Text('km/h',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}
