// lib/screens/order_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class OrderAnalysisScreen extends StatefulWidget {
  final DetectedOrder order;

  const OrderAnalysisScreen({super.key, required this.order});

  @override
  State<OrderAnalysisScreen> createState() => _OrderAnalysisScreenState();
}

class _OrderAnalysisScreenState extends State<OrderAnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _meterCtrl;
  late List<Animation<double>> _fadeAnims;
  late Animation<double> _meterAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _meterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnims = List.generate(
      6,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(i * 0.12, (i * 0.12) + 0.4, curve: Curves.easeOut),
        ),
      ),
    );

    _meterAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _meterCtrl, curve: Curves.easeOutCubic),
    );

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _meterCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _meterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;
    final order = widget.order;

    final isGood = order.meetsFilters(
      maxMinutes: settings.maxDetourMinutes,
      maxKm: settings.maxDetourKm,
      minEarnings: settings.minEarnings,
      enabledApps: settings.enabledApps,
    );

    final kmRatio = (order.detourKm / settings.maxDetourKm).clamp(0.0, 1.0);
    final minRatio =
        (order.extraMinutes / settings.maxDetourMinutes).clamp(0.0, 1.0);
    final earnRatio =
        (order.estimatedEarnings / (settings.minEarnings * 2)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(order, isGood),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fadeWidget(0, _buildSourceCard(order)),
                  const SizedBox(height: 12),
                  _fadeWidget(1, _buildVerdictBanner(isGood, order, settings)),
                  const SizedBox(height: 20),
                  _fadeWidget(2, _buildSectionLabel('ANÁLISIS DE DESVÍO')),
                  const SizedBox(height: 10),
                  _fadeWidget(
                      2, _buildMeter('Desvío en km', order.detourKm,
                          settings.maxDetourKm, 'km', kmRatio)),
                  const SizedBox(height: 8),
                  _fadeWidget(
                      3, _buildMeter('Tiempo extra', order.extraMinutes.toDouble(),
                          settings.maxDetourMinutes.toDouble(), 'min', minRatio)),
                  const SizedBox(height: 8),
                  _fadeWidget(
                      3, _buildMeter('Ganancia estimada',
                          order.estimatedEarnings, settings.minEarnings * 2,
                          '\$', earnRatio, invert: true)),
                  const SizedBox(height: 20),
                  _fadeWidget(4, _buildSectionLabel('DETALLES DEL PEDIDO')),
                  const SizedBox(height: 10),
                  _fadeWidget(4, _buildDetailsGrid(order)),
                  const SizedBox(height: 20),
                  _fadeWidget(5, _buildSectionLabel('MAPA DE DESVÍO')),
                  const SizedBox(height: 10),
                  _fadeWidget(5, _buildDetourMap(order)),
                  const SizedBox(height: 28),
                  if (order.decision == OrderDecision.pending)
                    _fadeWidget(5, _buildActionButtons(context, state, order)),
                  if (order.decision != OrderDecision.pending)
                    _fadeWidget(5, _buildDecisionResult(order)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fadeWidget(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_fadeAnims[index]),
        child: child,
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(DetectedOrder order, bool isGood) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.bgHeader,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isGood
                  ? [const Color(0xFF0d2e1f), AppColors.bgHeader]
                  : [const Color(0xFF2e0d1a), AppColors.bgHeader],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 16, 16, 0),
              child: Row(
                children: [
                  AppBadge(app: order.app, size: 44),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Análisis de pedido',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        order.app.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        order.neighborhood,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ConvenienceBadge(convenient: isGood),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard(DetectedOrder order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dirección detectada automáticamente',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(
                  order.rawAddress,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryDim.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.accessibility_new_rounded,
                    size: 11, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Auto',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictBanner(
      bool isGood, DetectedOrder order, UserSettings settings) {
    final color = isGood ? AppColors.primary : AppColors.danger;
    final bgColor = isGood ? AppColors.primaryDim : AppColors.dangerDim;
    final icon = isGood
        ? Icons.thumb_up_alt_rounded
        : Icons.thumb_down_alt_rounded;

    final reasons = <String>[];
    if (order.detourKm > settings.maxDetourKm) {
      reasons.add('desvío de ${order.detourKm.toStringAsFixed(1)} km supera el límite');
    }
    if (order.extraMinutes > settings.maxDetourMinutes) {
      reasons.add('${order.extraMinutes} min extra supera tu máximo');
    }
    if (order.estimatedEarnings < settings.minEarnings) {
      reasons.add(
          '\$${order.estimatedEarnings.toStringAsFixed(0)} no alcanza tu mínimo');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGood ? '✓ Este pedido conviene' : '✗ Este pedido no conviene',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isGood
                      ? 'Cumple todos tus filtros configurados'
                      : reasons.isNotEmpty
                          ? reasons.join(', ')
                          : 'No cumple con tus preferencias',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildMeter(String label, double value, double max, String unit,
      double ratio, {bool invert = false}) {
    final isGood = invert ? ratio > 0.5 : ratio < 0.75;
    final barColor = invert
        ? (ratio > 0.5 ? AppColors.primary : AppColors.danger)
        : (ratio < 0.75 ? AppColors.primary : AppColors.danger);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: unit == '\$'
                          ? '\$${value.toStringAsFixed(0)}'
                          : '${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!invert)
                      TextSpan(
                        text: unit == '\$'
                            ? ' / \$${max.toStringAsFixed(0)}'
                            : ' / ${max % 1 == 0 ? max.toInt() : max.toStringAsFixed(1)} $unit',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _meterAnim,
            builder: (_, __) {
              return Stack(
                children: [
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (invert ? ratio : ratio) * _meterAnim.value,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: barColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
                size: 12,
                color: barColor,
              ),
              const SizedBox(width: 4),
              Text(
                invert
                    ? (isGood
                        ? 'Supera tu mínimo de ganancia'
                        : 'Por debajo de tu mínimo')
                    : (isGood
                        ? 'Dentro de tu límite'
                        : 'Supera tu límite configurado'),
                style: TextStyle(
                  color: barColor.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(DetectedOrder order) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _detailTile(Icons.route_rounded, 'Desvío',
            '${order.detourKm.toStringAsFixed(1)} km', AppColors.textPrimary),
        _detailTile(Icons.timer_rounded, 'Tiempo extra',
            '${order.extraMinutes} minutos', AppColors.textPrimary),
        _detailTile(Icons.attach_money_rounded, 'Ganancia estimada',
            '\$${order.estimatedEarnings.toStringAsFixed(0)} MXN',
            AppColors.primary),
        _detailTile(Icons.schedule_rounded, 'Detectado',
            _formatTime(order.detectedAt), AppColors.textPrimary),
        _detailTile(Icons.smartphone_rounded, 'App',
            order.app.displayName, order.app.color),
        _detailTile(Icons.place_rounded, 'Colonia',
            order.neighborhood, AppColors.textPrimary),
      ],
    );
  }

  Widget _detailTile(IconData icon, String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDetourMap(DetectedOrder order) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0d1a30), Color(0xFF071520)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(size: Size.infinite, painter: _DetourMapPainter()),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgHeader.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _legendDot(AppColors.primary),
                    const SizedBox(width: 5),
                    const Text('Ruta actual',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 10)),
                    const SizedBox(width: 10),
                    _legendDot(AppColors.warning),
                    const SizedBox(width: 5),
                    const Text('Desvío',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildActionButtons(
      BuildContext context, AppState state, DetectedOrder order) {
    return Row(
      children: [
        DecisionButton(
          label: 'Ignorar',
          icon: Icons.close_rounded,
          color: AppColors.danger,
          outlined: true,
          onTap: () {
            state.decideOrder(order.id, OrderDecision.ignored);
            Navigator.pop(context);
          },
        ),
        const SizedBox(width: 12),
        DecisionButton(
          label: 'Aceptar',
          icon: Icons.check_rounded,
          color: AppColors.primary,
          onTap: () {
            state.decideOrder(order.id, OrderDecision.accepted);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildDecisionResult(DetectedOrder order) {
    final accepted = order.decision == OrderDecision.accepted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accepted ? AppColors.primaryDim.withValues(alpha: 0.4) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accepted
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            accepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: accepted ? AppColors.primary : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            accepted ? 'Pedido aceptado' : 'Pedido ignorado',
            style: TextStyle(
              color: accepted ? AppColors.primary : AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DetourMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Active route
    final routePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width * 0.12, size.height * 0.5);
    final end = Offset(size.width * 0.72, size.height * 0.5);
    canvas.drawLine(start, end, routePaint);

    // Detour route (dashed)
    final detourPaint = Paint()
      ..color = AppColors.warning.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final detourMid = Offset(size.width * 0.55, size.height * 0.25);
    final detourEnd = Offset(size.width * 0.85, size.height * 0.38);
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..quadraticBezierTo(
          detourMid.dx, detourMid.dy, detourEnd.dx, detourEnd.dy);
    canvas.drawPath(path, detourPaint);

    // Dots
    _drawDot(canvas, start, AppColors.primary, 7);
    _drawDot(canvas, end, AppColors.textPrimary, 6);
    _drawDot(canvas, detourEnd, AppColors.warning, 7);
  }

  void _drawDot(Canvas canvas, Offset pos, Color color, double r) {
    canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        pos,
        r + 3,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
