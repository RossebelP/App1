// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/osm_map_widget.dart';
import 'order_analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _alertCtrl;
  late Animation<Offset> _alertSlide;
  late Animation<double> _alertFade;

  @override
  void initState() {
    super.initState();
    _alertCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _alertSlide = Tween<Offset>(
            begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _alertCtrl, curve: Curves.easeOutBack));
    _alertFade =
        Tween<double>(begin: 0, end: 1).animate(_alertCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadSettings();
      Future.delayed(
          const Duration(milliseconds: 800), () {
        if (mounted) state.simulateActiveOrder();
      });
    });
  }

  @override
  void dispose() {
    _alertCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      state.pendingAlert != null
          ? _alertCtrl.forward()
          : _alertCtrl.reverse();

      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Stack(children: [
          CustomScrollView(slivers: [
            _appBar(state),
            SliverToBoxAdapter(child: _accessBanner(state)),
            SliverToBoxAdapter(child: _activeOrderCard(state)),
            SliverToBoxAdapter(child: _osmMap(state)),
            SliverToBoxAdapter(child: _gpsBar(context, state)),
            SliverToBoxAdapter(child: _dayStats(state)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Alertas de hoy',
                trailing: Text('${state.todayOrders.length} detectados',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ),
            ),
            _orderList(state),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ]),
          if (state.pendingAlert != null) _alertOverlay(context, state),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: state.simulateIncomingOrder,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.notifications_active_rounded,
              color: Colors.white),
          label: const Text('Simular pedido',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
    });
  }

  // ── AppBar ───────────────────────────────────────────────────────────────
  SliverAppBar _appBar(AppState state) => SliverAppBar(
    pinned: true,
    backgroundColor: AppColors.bgHeader,
    title: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
            child: Text('R',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18))),
      ),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RouteMatch',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        Text('Optimizador de rutas',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w400)),
      ]),
    ]),
    actions: [
      Stack(children: [
        IconButton(
            icon: const Icon(Icons.notifications_rounded,
                color: AppColors.textSecondary),
            onPressed: () {}),
        if (state.pendingAlert != null)
          Positioned(
              right: 10, top: 10,
              child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle))),
      ]),
    ],
  );

  // ── Banner Accessibility ─────────────────────────────────────────────────
  Widget _accessBanner(AppState state) {
    final active = state.accessibilityActive;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primaryDim.withValues(alpha: 0.6)
            : AppColors.dangerDim.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        GlowDot(color: active ? AppColors.primary : AppColors.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            active
                ? 'Accessibility Service activo — Uber Eats, Rappi y DiDi'
                : 'Accessibility Service inactivo — toca Activar',
            style: TextStyle(
                color: active ? AppColors.primary : AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
        if (!active)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero),
            child: const Text('Activar',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  // ── Tarjeta pedido activo ────────────────────────────────────────────────
  Widget _activeOrderCard(AppState state) {
    final o = state.activeOrder;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0d2e1f), Color(0xFF0d1a30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: o == null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.route_rounded,
                        color: AppColors.textMuted, size: 24)),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sin pedido activo',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Abre tu app de delivery para comenzar',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ]),
              ]))
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  AppBadge(app: o.app, size: 36),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pedido en curso',
                        style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    Text(o.app.displayName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4))),
                    child: const Text('EN RUTA',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(o.address,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _oStat(Icons.route_rounded, '${o.distanceKm} km',
                      'Distancia'),
                  const SizedBox(width: 10),
                  _oStat(Icons.timer_rounded, '${o.estimatedMinutes} min',
                      'ETA'),
                  const SizedBox(width: 10),
                  _oStat(Icons.place_rounded, o.neighborhood, 'Colonia'),
                ]),
              ])),
    );
  }

  Widget _oStat(IconData icon, String v, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(lbl,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 4),
        Text(v,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  // ── Mapa OSM ─────────────────────────────────────────────────────────────
  Widget _osmMap(AppState state) {
    final o = state.activeOrder;
    final alert = state.pendingAlert;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: OsmMapWidget(
        destination:
            o != null ? LatLng(o.lat, o.lng) : null,
        detourPoint:
            alert != null ? LatLng(alert.lat, alert.lng) : null,
        height: 230,
        interactive: true,
      ),
    );
  }

  // ── Barra GPS ────────────────────────────────────────────────────────────
  Widget _gpsBar(BuildContext ctx, AppState state) {
    return Consumer<LocationService>(builder: (_, loc, __) {
      final cur = loc.current;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          GlowDot(
              color:
                  loc.isTracking ? AppColors.primary : AppColors.textMuted,
              size: 7),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.isTracking && cur != null
                  ? (cur.addressLabel ??
                      '${cur.position.latitude.toStringAsFixed(5)}, '
                      '${cur.position.longitude.toStringAsFixed(5)}')
                  : loc.errorMessage ?? 'GPS inactivo — toca Activar',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (cur != null) ...[
            const SizedBox(width: 8),
            _gStat(Icons.speed_rounded,
                '${cur.speedKmh.toStringAsFixed(0)} km/h', AppColors.primary),
            const SizedBox(width: 8),
            _gStat(Icons.gps_fixed_rounded,
                '±${cur.accuracyM.toStringAsFixed(0)}m', AppColors.textMuted),
          ],
          if (!loc.isTracking)
            TextButton(
              onPressed: state.locationService.startTracking,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  minimumSize: Size.zero),
              child: const Text('Activar GPS',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
      );
    });
  }

  Widget _gStat(IconData icon, String v, Color c) => Row(children: [
    Icon(icon, size: 11, color: c),
    const SizedBox(width: 3),
    Text(v,
        style: TextStyle(
            color: c, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);

  // ── Stats del día ────────────────────────────────────────────────────────
  Widget _dayStats(AppState state) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      Expanded(
          child: StatCard(
              label: 'GANADO HOY',
              value: '\$${state.totalEarnings.toStringAsFixed(0)}',
              icon: Icons.attach_money_rounded,
              valueColor: AppColors.primary,
              iconColor: AppColors.primary)),
      const SizedBox(width: 10),
      Expanded(
          child: StatCard(
              label: 'PEDIDOS',
              value: '${state.ordersAccepted}/${state.todayOrders.length}',
              unit: 'tomados',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.textMuted)),
      const SizedBox(width: 10),
      Expanded(
          child: StatCard(
              label: 'KM EVITADOS',
              value: state.kmSaved.toStringAsFixed(1),
              unit: 'km',
              icon: Icons.block_rounded,
              iconColor: AppColors.warning,
              valueColor: AppColors.warning)),
    ]),
  );

  // ── Lista de pedidos ─────────────────────────────────────────────────────
  Widget _orderList(AppState state) {
    if (state.todayOrders.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border)),
          child: const Column(children: [
            Icon(Icons.inbox_rounded, size: 40, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Sin alertas aún',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('Los pedidos detectados aparecerán aquí',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _tile(ctx, state.todayOrders[i], state),
        childCount: state.todayOrders.length,
      ),
    );
  }

  Widget _tile(BuildContext ctx, DetectedOrder o, AppState state) {
    final isGood    = o.decision == OrderDecision.accepted;
    final isPending = o.decision == OrderDecision.pending;
    return GestureDetector(
      onTap: () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => OrderAnalysisScreen(order: o))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          AppBadge(app: o.app, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text(o.app.displayName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('• ${o.neighborhood}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 3),
              Text(o.rawAddress,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                _mStat(Icons.route_rounded,
                    '+${o.detourKm.toStringAsFixed(1)} km'),
                const SizedBox(width: 10),
                _mStat(Icons.timer_rounded, '+${o.extraMinutes} min'),
                const SizedBox(width: 10),
                _mStat(Icons.attach_money_rounded,
                    '\$${o.estimatedEarnings.toStringAsFixed(0)}',
                    c: AppColors.primary),
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isPending)
              ConvenienceBadge(convenient: true)
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isGood
                          ? AppColors.primaryDim
                          : AppColors.bgCardAlt)
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isGood ? 'Tomado' : 'Ignorado',
                  style: TextStyle(
                      color: isGood
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 6),
            Text(_fmt(o.detectedAt),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  Widget _mStat(IconData icon, String v, {Color? c}) => Row(children: [
    Icon(icon, size: 11, color: c ?? AppColors.textMuted),
    const SizedBox(width: 3),
    Text(v,
        style: TextStyle(
            color: c ?? AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500)),
  ]);

  // ── Alerta flotante animada ──────────────────────────────────────────────
  Widget _alertOverlay(BuildContext context, AppState state) {
    final o = state.pendingAlert!;
    final isGood = o.meetsFilters(
      maxMinutes: state.settings.maxDetourMinutes,
      maxKm: state.settings.maxDetourKm,
      minEarnings: state.settings.minEarnings,
      enabledApps: state.settings.enabledApps,
    );
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SlideTransition(
        position: _alertSlide,
        child: FadeTransition(
          opacity: _alertFade,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OrderAnalysisScreen(order: o))),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgHeader,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isGood
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : AppColors.danger.withValues(alpha: 0.7),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: (isGood ? AppColors.primary : AppColors.danger)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    AppBadge(app: o.app, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('¡Nuevo pedido detectado!',
                            style: TextStyle(
                                color: isGood
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(o.neighborhood,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(children: [
                          _chip('+${o.detourKm.toStringAsFixed(1)} km'),
                          const SizedBox(width: 6),
                          _chip('+${o.extraMinutes} min'),
                          const SizedBox(width: 6),
                          _chip(
                              '\$${o.estimatedEarnings.toStringAsFixed(0)}',
                              earn: true),
                        ]),
                      ]),
                    ),
                    Column(children: [
                      ConvenienceBadge(convenient: isGood),
                      const SizedBox(height: 6),
                      GestureDetector(
                          onTap: state.dismissAlert,
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textMuted)),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, {bool earn = false}) {
    final c = earn ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(t,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
