// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/location_service.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgHeader,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final appState = AppState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        // LocationService expuesto directamente para que OsmMapWidget
        // lo consuma con Consumer<LocationService>
        ChangeNotifierProvider.value(value: appState.locationService),
      ],
      child: const RouteMatchApp(),
    ),
  );
}

class RouteMatchApp extends StatelessWidget {
  const RouteMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  static const _screens = [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Consumer<AppState>(builder: (_, state, __) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.bgHeader,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              _navItem(0, Icons.home_rounded,     Icons.home_outlined,     'Inicio'),
              _navItem(1, Icons.history_rounded,  Icons.history_rounded,   'Historial',
                  badge: state.todayOrders.isNotEmpty
                      ? '${state.todayOrders.length}'
                      : null),
              _navItem(2, Icons.settings_rounded, Icons.settings_outlined, 'Config'),
            ]),
          ),
        ),
      );
    });
  }

  Widget _navItem(int i, IconData active, IconData inactive, String label,
      {String? badge}) {
    final sel = _idx == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _idx = i),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(sel ? active : inactive,
                  color: sel ? AppColors.primary : AppColors.textMuted,
                  size: 22),
            ),
            if (badge != null)
              Positioned(
                right: -2, top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: sel ? AppColors.primary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight:
                      sel ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    );
  }
}
