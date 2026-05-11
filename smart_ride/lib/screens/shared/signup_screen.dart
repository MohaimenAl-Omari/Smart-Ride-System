import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user-model.dart';
import '../passenger/passenger_home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthController authController = AuthController();

  String selectedRole = "passenger";

  File? licenseFile;
  File? nonConvictionFile;
  File? medicalFile;

  bool isLoading = false;
  bool obscurePassword = true;

  final Map<String, bool> _focused = {
    'name': false,
    'email': false,
    'phone': false,
    'password': false,
  };

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        if (type == 'license') licenseFile = file;
        if (type == 'nonConviction') nonConvictionFile = file;
        if (type == 'medical') medicalFile = file;
      });
    }
  }

  void signup() async {
    final s = S.of(context);
    if ([nameController, emailController, phoneController, passwordController]
        .any((c) => c.text.trim().isEmpty)) {
      AppToast.show(context, s.fillAllFields, error: true);
      return;
    }

    if (selectedRole == 'driver') {
      if (licenseFile == null ||
          nonConvictionFile == null ||
          medicalFile == null) {
        AppToast.show(context, s.driverDocsRequired, error: true);
        return;
      }
    }

    HapticFeedback.lightImpact();
    setState(() => isLoading = true);

    final AuthResult result = await authController.register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      password: passwordController.text.trim(),
      role: selectedRole,
    );

    if (!result.success || result.user == null) {
      setState(() => isLoading = false);
      AppToast.show(context, result.error ?? s.signupFailed, error: true);
      return;
    }

    final UserModel user = result.user!;

    if (selectedRole == 'driver') {
      final uploaded = await authController.uploadCertificates(
        userId: user.id!,
        license: licenseFile!,
        nonConviction: nonConvictionFile!,
        medical: medicalFile!,
      );

      if (!uploaded) {
        setState(() => isLoading = false);
        AppToast.show(context, s.signupFailedDocs, error: true);
        return;
      }

      setState(() => isLoading = false);
      _showDriverPendingDialog();
      return;
    }

    setState(() => isLoading = false);
    Navigator.pushAndRemoveUntil(
      context,
      _fadeRoute(PassengerHome(user: user)),
      (route) => false,
    );
  }

  void _showDriverPendingDialog() {
    final s = S.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.hourglass_top_rounded,
              color: AppColors.primaryDark, size: 28),
        ),
        title: Text(
          s.applicationSubmitted,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          s.applicationSubmittedBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 160,
              child: PrimaryButton(
                label: s.ok,
                height: 44,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required String focusKey,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    final isFocused = _focused[focusKey] ?? false;
    return Focus(
      onFocusChange: (v) => setState(() => _focused[focusKey] = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: AppDecor.field(focused: isFocused),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 14.5),
            prefixIcon: Icon(icon,
                color: isFocused ? AppColors.primary : AppColors.textMuted,
                size: 20),
            suffixIcon: suffix,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox(String title, String type, File? currentFile) {
    final s = S.of(context);
    final bool isPicked = currentFile != null;
    return GestureDetector(
      onTap: () => _pickFile(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPicked
              ? AppColors.primarySoft
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPicked ? AppColors.primary : AppColors.border,
            width: isPicked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPicked ? AppColors.primary : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPicked
                    ? Icons.check_rounded
                    : Icons.upload_file_rounded,
                color: isPicked ? Colors.white : AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPicked
                        ? currentFile.path.split('/').last
                        : s.docHint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPicked)
              GestureDetector(
                onTap: () => setState(() {
                  if (type == 'license') licenseFile = null;
                  if (type == 'nonConviction') nonConvictionFile = null;
                  if (type == 'medical') medicalFile = null;
                }),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildHeading(),
                          const SizedBox(height: 24),
                          _buildField(
                            controller: nameController,
                            hint: s.fullName,
                            focusKey: 'name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: emailController,
                            hint: s.email,
                            focusKey: 'email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: phoneController,
                            hint: s.phone,
                            focusKey: 'phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: passwordController,
                            hint: s.password,
                            focusKey: 'password',
                            icon: Icons.lock_outline_rounded,
                            obscure: obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildRoleSelector(),
                          if (selectedRole == "driver") ...[
                            const SizedBox(height: 22),
                            _buildDriverDocsSection(),
                          ],
                          const SizedBox(height: 18),
                          _buildTermsNote(),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: s.createAccount,
                            loading: isLoading,
                            onTap: signup,
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
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

  Widget _buildDriverDocsSection() {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined,
                    size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.driverVerification,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.driverDocsHelp,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          _buildUploadBox(s.drivingLicense, "license", licenseFile),
          const SizedBox(height: 10),
          _buildUploadBox(
              s.nonConviction, "nonConviction", nonConvictionFile),
          const SizedBox(height: 10),
          _buildUploadBox(s.medicalCert, "medical", medicalFile),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.iWantToJoinAs,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildRoleCard(
              role: "passenger",
              label: s.passenger,
              caption: s.passengerCaption,
              icon: Icons.airline_seat_recline_normal_rounded,
            ),
            const SizedBox(width: 10),
            _buildRoleCard(
              role: "driver",
              label: s.driver,
              caption: s.driverCaption,
              icon: Icons.drive_eta_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String label,
    required String caption,
    required IconData icon,
  }) {
    final bool isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color:
                isSelected ? AppColors.primarySoft : AppColors.surface,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow:
                isSelected ? AppShadows.primary() : AppShadows.card(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    size: 18),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(caption,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: AppDecor.outline(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          S.of(context).createAccount,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }

  Widget _buildHeading() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.joinSmartRide,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.joinSub,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        S.of(context).termsNote,
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12, height: 1.5),
      ),
    );
  }
}
