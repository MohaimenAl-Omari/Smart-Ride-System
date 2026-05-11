import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_screen.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user-model.dart';
import '../passenger/passenger_home.dart';
import '../driver/driver_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthController authController = AuthController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool _emailFocused = false;
  bool _passFocused = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    final s = S.of(context);
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      AppToast.show(context, s.pleaseEnterCredentials, error: true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => isLoading = true);
    final AuthResult result = await authController.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => isLoading = false);
    if (result.success) {
      _routeForRole(result.user!);
    } else {
      AppToast.show(context, result.error ?? s.invalidCredentials,
          error: true);
    }
  }

  void _routeForRole(UserModel user) {
    Widget home;
    switch (user.role) {
      case 'driver':
        home = DriverHome(user: user);
        break;
      case 'admin':
        AppToast.show(context, S.of(context).adminWebOnly, error: true);
        return;
      default:
        home = PassengerHome(user: user);
    }
    Navigator.pushAndRemoveUntil(
      context,
      _fadeRoute(home),
      (_) => false,
    );
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHero(),
                      const SizedBox(height: 32),
                      _buildHeading(),
                      const SizedBox(height: 28),
                      _buildEmailField(),
                      const SizedBox(height: 14),
                      _buildPasswordField(),
                      const SizedBox(height: 8),
                      _buildForgot(),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: S.of(context).signIn,
                        loading: isLoading,
                        onTap: login,
                      ),
                      const SizedBox(height: 18),
                      _buildDivider(),
                      const SizedBox(height: 18),
                      _buildSignupLink(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final s = S.of(context);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AppColors.primaryGradient,
            boxShadow: AppShadows.primary(),
          ),
          child: const Icon(Icons.directions_car_filled_rounded,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.appName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.appTagline,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeading() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.welcomeBack,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.welcomeSub,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Focus(
      onFocusChange: (v) => setState(() => _emailFocused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: AppDecor.field(focused: _emailFocused),
        child: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: S.of(context).email,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 14.5),
            prefixIcon: Icon(Icons.mail_outline_rounded,
                color: _emailFocused
                    ? AppColors.primary
                    : AppColors.textMuted,
                size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Focus(
      onFocusChange: (v) => setState(() => _passFocused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: AppDecor.field(focused: _passFocused),
        child: TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: S.of(context).password,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 14.5),
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: _passFocused
                    ? AppColors.primary
                    : AppColors.textMuted,
                size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildForgot() {
    final s = S.of(context);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: () => AppToast.show(context, s.resetSoon),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Text(
          s.forgotPassword,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(S.of(context).or,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12.5)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }

  Widget _buildSignupLink() {
    final s = S.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, _fadeRoute(const SignupScreen())),
      child: Container(
        height: 52,
        decoration: AppDecor.outline(),
        child: Center(
          child: RichText(
            text: TextSpan(
              text: s.newHere,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
              children: [
                TextSpan(
                  text: s.createAccount,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
