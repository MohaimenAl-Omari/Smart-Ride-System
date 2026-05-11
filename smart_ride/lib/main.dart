import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constant.dart';
import 'core/session.dart';
import 'core/localization.dart';
import 'models/user-model.dart';
import 'screens/shared/login_screen.dart';
import 'screens/passenger/passenger_home.dart';
import 'screens/driver/driver_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LangController.instance.load();
  runApp(const SmartRideApp());
}

class SmartRideApp extends StatelessWidget {
  const SmartRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever the language changes so the entire
    // tree picks up the new locale (and RTL flips automatically).
    return ValueListenableBuilder<String>(
      valueListenable: LangController.instance.code,
      builder: (context, code, _) {
        return LangScope(
          code: code,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Smart Ride',
            themeMode: ThemeMode.light,
            theme: buildSmartRideTheme(),
            locale: Locale(code),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: const _SessionGate(),
          ),
        );
      },
    );
  }
}

/// Root gate that decides which screen the app should open with based on
/// whether there's a stored user session in [SessionService].
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  Future<UserModel?>? _future;

  @override
  void initState() {
    super.initState();
    _future = SessionService.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        switch (user.role) {
          case 'driver':
            return DriverHome(user: user);
          case 'admin':
            // Admin dashboard is web-only — fall back to login.
            return const LoginScreen();
          default:
            return PassengerHome(user: user);
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: AppColors.primaryGradient,
                      boxShadow: AppShadows.primary(),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    s.appName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
