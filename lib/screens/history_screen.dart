// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import 'order_analysis_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final orders = state.todayOrders;
      final accepted =
          orders.where((o) => o.decision == OrderDecision.accepted).toList();
      final ignored =
          orders.where((o) => o.decision == OrderDecision.ignored).toList();
      final pending =
          orders.where((o) => o.decision == OrderDecision.pending).toList();

      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, state),
            SliverToBoxAdapter(child: _buildSummaryCard(state)),
            SliverToBoxAdapter(child: _buildAppBreakdown(orders)),
            if (orders.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else ...[
              if (pending.isNotEmpty) ...[
                const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Pendientes')),
                _buildOrderGroup(context, pending, state),
              ],
              if (accepted.isNotEmpty) ...[
                const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Aceptados')),
                _buildOrderGroup(context, accepted, state),
              ],
              if (ignored.isNotEmpty) ...[
                const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Ignorados')),
                _buildOrderGroup(context, ignored, state),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      );
    });
  }

  SliverAppBar _buildAppBar(BuildContext context, AppState state) {
    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.bgHeader,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial del día'),
          Text(
            '${now.day} de ${months[now.month - 1]}, ${now.year}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        if (state.todayOrders.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted),
            onPressed: () => _showClearDialog(context, state),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(AppState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0d2e1f), Color(0xFF0d1a30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'RESUMEN DEL DÍA',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryBigStat(
                '\$${state.totalEarnings.toStringAsFixed(0)}',
                'Total ganado',
                AppColors.primary,
              ),
              const SizedBox(width: 16),
              _summaryBigStat(
                '${state.ordersAccepted}',
                'Aceptados',
                AppColors.primaryLight,
              ),
              const SizedBox(width: 16),
              _summaryBigStat(
                '${state.ordersIgnored}',
                'Ignorados',
                AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              _summaryBigStat(
                '${state.kmSaved.toStringAsFixed(1)} km',
                'Km ahorrados',
                AppColors.warning,
              ),
            ],
          ),
          if (state.todayOrders.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildProgressBar(state),
          ],
        ],
      ),
    );
  }

  Widget _summaryBigStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AppState state) {
    final total = state.todayOrders.length;
    if (total == 0) return const SizedBox.shrink();

    final acceptedRatio = state.ordersAccepted / total;
    final ignoredRatio = state.ordersIgnored / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tasa de aceptación',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              if (acceptedRatio > 0)
                Flexible(
                  flex: (acceptedRatio * 100).round(),
                  child: Container(
                    height: 8,
                    color: AppColors.primary,
                  ),
                ),
              if (ignoredRatio > 0)
                Flexible(
                  flex: (ignoredRatio * 100).round(),
                  child: Container(
                    height: 8,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
              if (state.todayOrders
                      .where((o) => o.decision == OrderDecision.pending)
                      .isNotEmpty)
                Flexible(
                  flex: ((1 - acceptedRatio - ignoredRatio) * 100).round(),
                  child: Container(
                    height: 8,
                    color: AppColors.warning.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _progressLegend(AppColors.primary, 'Aceptados'),
            const SizedBox(width: 12),
            _progressLegend(AppColors.textMuted.withValues(alpha: 0.6), 'Ignorados'),
            const SizedBox(width: 12),
            _progressLegend(AppColors.warning.withValues(alpha: 0.6), 'Pendientes'),
          ],
        ),
      ],
    );
  }

  Widget _progressLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            )),
      ],
    );
  }

  Widget _buildAppBreakdown(List<DetectedOrder> orders) {
    if (orders.isEmpty) return const SizedBox.shrink();

    final Map<DeliveryApp, int> counts = {};
    for (final o in orders) {
      counts[o.app] = (counts[o.app] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: DeliveryApp.values
            .where((a) => counts.containsKey(a))
            .map((app) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(app.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          '${counts[app]}',
                          style: TextStyle(
                            color: app.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          app.displayName.split(' ').first,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
          SizedBox(height: 14),
          Text('Sin historial hoy',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
          SizedBox(height: 6),
          Text(
            'Los pedidos analizados aparecerán aquí con sus detalles completos',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  SliverList _buildOrderGroup(
      BuildContext context, List<DetectedOrder> orders, AppState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildHistoryTile(context, orders[index], state),
        childCount: orders.length,
      ),
    );
  }

  Widget _buildHistoryTile(
      BuildContext context, DetectedOrder order, AppState state) {
    final isAccepted = order.decision == OrderDecision.accepted;
    final isPending = order.decision == OrderDecision.pending;

    Color statusColor = AppColors.textMuted;
    IconData statusIcon = Icons.remove_circle_outline_rounded;
    String statusText = 'Ignorado';

    if (isPending) {
      statusColor = AppColors.warning;
      statusIcon = Icons.pending_rounded;
      statusText = 'Pendiente';
    } else if (isAccepted) {
      statusColor = AppColors.primary;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Aceptado';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderAnalysisScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAccepted
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AppBadge(app: order.app, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.app.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.neighborhood,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.rawAddress,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _histStat(Icons.route_rounded,
                            '+${order.detourKm.toStringAsFixed(1)} km'),
                        const SizedBox(width: 12),
                        _histStat(Icons.timer_rounded,
                            '+${order.extraMinutes} min'),
                        const SizedBox(width: 12),
                        _histStat(
                            Icons.attach_money_rounded,
                            '\$${order.estimatedEarnings.toStringAsFixed(0)}',
                            color: isAccepted
                                ? AppColors.primary
                                : AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(order.detectedAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _histStat(IconData icon, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color ?? AppColors.textMuted),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(
              color: color ?? AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  void _showClearDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Borrar historial',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            '¿Estás seguro de que quieres borrar todo el historial del día?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              state.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Borrar',
                style: TextStyle(color: AppColors.danger)),
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
