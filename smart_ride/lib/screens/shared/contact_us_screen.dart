import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../controllers/support_controller.dart';
import '../../models/user-model.dart';

/// Sends a message to the team via the Contact Us API.
class ContactUsScreen extends StatefulWidget {
  final UserModel user;
  const ContactUsScreen({super.key, required this.user});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final ContactController _ctl = ContactController();
  late final TextEditingController _email =
      TextEditingController(text: widget.user.email);
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = S.of(context);
    if (_email.text.trim().isEmpty ||
        _subject.text.trim().isEmpty ||
        _message.text.trim().isEmpty) {
      AppToast.show(context, s.contactValidation, error: true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    final res = await _ctl.send(
      token: widget.user.token,
      email: _email.text.trim(),
      subject: _subject.text.trim(),
      message: _message.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.success) {
      AppToast.show(context, s.messageSent);
      _subject.clear();
      _message.clear();
    } else {
      AppToast.show(context, res.message, error: true);
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
                      _hero(s),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppDecor.card(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _field(_email, s.email,
                                Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 10),
                            _field(_subject, s.subject,
                                Icons.title_rounded),
                            const SizedBox(height: 10),
                            _field(_message, s.message,
                                Icons.notes_rounded,
                                maxLines: 5),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: s.sendMessage,
                        icon: Icons.send_rounded,
                        loading: _sending,
                        onTap: _sending ? null : _send,
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
          Text(s.contactUs,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _hero(S s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.primary(),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.contactUs,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(s.contactUsSub,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: AppDecor.field(),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: maxLines > 1
              ? null
              : Icon(icon, size: 18, color: AppColors.primaryDark),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
