import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user-model.dart';

/// Lets the signed-in user update name, email, phone, city, password
/// and profile image. The save action posts a multipart request to
/// `POST /api/profile` and returns the updated UserModel.
class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthController _auth = AuthController();
  final _picker = ImagePicker();

  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _email =
      TextEditingController(text: widget.user.email);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone);
  late final TextEditingController _city =
      TextEditingController(text: widget.user.city ?? '');
  final TextEditingController _password = TextEditingController();
  final TextEditingController _currentPassword = TextEditingController();

  File? _pickedImage;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _password.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 82,
      );
      if (x != null) setState(() => _pickedImage = File(x.path));
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.toString(), error: true);
    }
  }

  void _showImageSheet() {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primaryDark),
              title: Text(s.pickFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primaryDark),
              title: Text(s.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_pickedImage != null || widget.user.imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.rose),
                title: Text(s.removePhoto,
                    style: const TextStyle(color: AppColors.rose)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pickedImage = null);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (_password.text.isNotEmpty && _currentPassword.text.isEmpty) {
      AppToast.show(context, s.currentPasswordRequired, error: true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    final res = await _auth.updateProfile(
      current: widget.user,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
      password: _password.text.isEmpty ? null : _password.text,
      currentPassword:
          _currentPassword.text.isEmpty ? null : _currentPassword.text,
      imagePath: _pickedImage?.path,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      AppToast.show(context, s.profileUpdated);
      Navigator.pop(context, res.user);
    } else {
      AppToast.show(context, res.error ?? s.failed, error: true);
    }
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
            child: Column(
              children: [
                _appBar(s),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: [
                      _avatarPicker(),
                      const SizedBox(height: 18),
                      _section(s.account, [
                        _field(_name, s.fullName,
                            Icons.person_outline_rounded),
                        const SizedBox(height: 10),
                        _field(_email, s.email, Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 10),
                        _field(_phone, s.phone, Icons.phone_outlined,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 10),
                        _field(_city, s.city, Icons.location_city_rounded),
                      ]),
                      const SizedBox(height: 14),
                      _section(s.password, [
                        _field(_currentPassword, s.currentPassword,
                            Icons.lock_outline_rounded,
                            obscure: true),
                        const SizedBox(height: 10),
                        _field(_password, s.newPasswordHint,
                            Icons.password_rounded,
                            obscure: true),
                      ]),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: s.saveChanges,
                        icon: Icons.save_rounded,
                        loading: _saving,
                        onTap: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: [
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
          Text(s.editProfile,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _avatarPicker() {
    final url = widget.user.imageUrl;
    Widget avatar;
    if (_pickedImage != null) {
      avatar = ClipOval(
          child:
              Image.file(_pickedImage!, width: 96, height: 96, fit: BoxFit.cover));
    } else if (url != null && url.isNotEmpty) {
      avatar = ClipOval(
          child: Image.network(url,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  InitialAvatar(name: widget.user.name, size: 96)));
    } else {
      avatar = InitialAvatar(name: widget.user.name, size: 96);
    }

    return Center(
      child: GestureDetector(
        onTap: _showImageSheet,
        child: Stack(
          children: [
            avatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: AppShadows.primary(),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Container(
      decoration: AppDecor.field(),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primaryDark),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
