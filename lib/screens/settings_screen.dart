// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late UserSettings _localSettings;
  bool _saved = false;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<AppState>().settings;
      setState(() {
        _localSettings = UserSettings.fromJson(settings.toJson());
        _apiKeyController.text = _localSettings.googleMapsApiKey;
      });
    });

    _localSettings = UserSettings();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _localSettings.googleMapsApiKey = _apiKeyController.text.trim();
    final state = context.read<AppState>();
    state.settings.maxDetourMinutes = _localSettings.maxDetourMinutes;
    state.settings.maxDetourKm = _localSettings.maxDetourKm;
    state.settings.minEarnings = _localSettings.minEarnings;
    state.settings.monitorUberEats = _localSettings.monitorUberEats;
    state.settings.monitorRappi = _localSettings.monitorRappi;
    state.settings.monitorDidi = _localSettings.monitorDidi;
    state.settings.monitorOther = _localSettings.monitorOther;
    state.settings.googleMapsApiKey = _localSettings.googleMapsApiKey;
    await state.saveSettings();

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(),
                  const SizedBox(height: 20),
                  _buildAppsSection(),
                  const SizedBox(height: 20),
                  _buildApiSection(),
                  const SizedBox(height: 20),
                  _buildAccessibilitySection(),
                  const SizedBox(height: 28),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.bgHeader,
      title: const Text('Configuración'),
      actions: [
        if (_saved)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 5),
                const Text('Guardado',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Filtros de aceptación'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildSliderTile(
                icon: Icons.timer_rounded,
                iconColor: AppColors.warning,
                title: 'Máximo de minutos extra',
                subtitle: 'Desvío de tiempo aceptable',
                value: _localSettings.maxDetourMinutes.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                unit: 'min',
                onChanged: (v) =>
                    setState(() => _localSettings.maxDetourMinutes = v.round()),
              ),
              _buildDivider(),
              _buildSliderTile(
                icon: Icons.route_rounded,
                iconColor: AppColors.primary,
                title: 'Máximos kilómetros de desvío',
                subtitle: 'Distancia adicional aceptable',
                value: _localSettings.maxDetourKm,
                min: 0.5,
                max: 15,
                divisions: 29,
                unit: 'km',
                onChanged: (v) => setState(
                    () => _localSettings.maxDetourKm = (v * 2).round() / 2),
              ),
              _buildDivider(),
              _buildSliderTile(
                icon: Icons.attach_money_rounded,
                iconColor: AppColors.primary,
                title: 'Ganancia mínima aceptable',
                subtitle: 'Pesos mexicanos por pedido',
                value: _localSettings.minEarnings,
                min: 10,
                max: 300,
                divisions: 29,
                unit: '\$',
                prefix: true,
                onChanged: (v) =>
                    setState(() => _localSettings.minEarnings = (v / 10).round() * 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
    bool prefix = false,
  }) {
    final displayValue = prefix
        ? '\$${ value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)}'
        : '${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)} $unit';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        )),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  displayValue,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  prefix ? '\$${ min.toInt()}' : '${min.toStringAsFixed(min % 1 == 0 ? 0 : 1)} $unit',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  prefix ? '\$${ max.toInt()}' : '${max.toStringAsFixed(max % 1 == 0 ? 0 : 1)} $unit',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Apps a monitorear'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildAppSwitch(
                app: DeliveryApp.uberEats,
                value: _localSettings.monitorUberEats,
                onChanged: (v) =>
                    setState(() => _localSettings.monitorUberEats = v),
                subtitle: 'com.ubercab.eats',
              ),
              _buildDivider(),
              _buildAppSwitch(
                app: DeliveryApp.rappi,
                value: _localSettings.monitorRappi,
                onChanged: (v) =>
                    setState(() => _localSettings.monitorRappi = v),
                subtitle: 'com.grability.rappi',
              ),
              _buildDivider(),
              _buildAppSwitch(
                app: DeliveryApp.didi,
                value: _localSettings.monitorDidi,
                onChanged: (v) =>
                    setState(() => _localSettings.monitorDidi = v),
                subtitle: 'com.xiaojukeji.didi.customer',
              ),
              _buildDivider(),
              _buildAppSwitch(
                app: DeliveryApp.other,
                value: _localSettings.monitorOther,
                onChanged: (v) =>
                    setState(() => _localSettings.monitorOther = v),
                subtitle: 'Otras aplicaciones de delivery',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppSwitch({
    required DeliveryApp app,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppBadge(app: app, size: 38),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildApiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Integración de mapas'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                        child: Text('G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ))),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google Maps API Key',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      Text('Requerida para cálculo de rutas',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _apiKeyController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility_off_rounded,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () {},
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Obtén tu clave en console.cloud.google.com. Activa Directions API y Maps SDK.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Permisos del sistema'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildPermissionTile(
                icon: Icons.accessibility_new_rounded,
                iconColor: AppColors.primary,
                title: 'Accessibility Service',
                subtitle: 'Necesario para leer pedidos en pantalla',
                status: 'Activo',
                statusColor: AppColors.primary,
                onTap: () {},
              ),
              _buildDivider(),
              _buildPermissionTile(
                icon: Icons.notifications_rounded,
                iconColor: AppColors.warning,
                title: 'Notificaciones',
                subtitle: 'Para mostrar alertas de pedidos',
                status: 'Activo',
                statusColor: AppColors.primary,
                onTap: () {},
              ),
              _buildDivider(),
              _buildPermissionTile(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.danger,
                title: 'Ubicación',
                subtitle: 'Para calcular distancias en tiempo real',
                status: 'Activo',
                statusColor: AppColors.primary,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      )),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _saved
                ? [AppColors.primaryDim, AppColors.primaryDim]
                : [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: _saved ? 0.1 : 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _saved ? Icons.check_rounded : Icons.save_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _saved ? 'Configuración guardada' : 'Guardar configuración',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, thickness: 1, color: AppColors.border, indent: 16);
  }
}
