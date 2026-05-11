import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';
import '../../controllers/auth_controller.dart';
import '../driver/driver_history_screen.dart';
import '../passenger/passenger_history_screen.dart';
import 'contact_us_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';


class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authCtl = AuthController();
  bool _busy = false;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<UserModel?>(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: _user)),
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  void _openContact() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContactUsScreen(user: _user)),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _user.role == 'driver'
            ? DriverHistoryScreen(user: _user)
            : PassengerHistoryScreen(user: _user),
      ),
    );
  }

  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    await _authCtl.logout(widget.user.token);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final u = _user;
    final isDriver = u.role == 'driver';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _appBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: [
                      _heroCard(u, isDriver),
                      const SizedBox(height: 14),
                      _section(s.account, [
                        _row(Icons.mail_outline_rounded, s.email, u.email),
                        _row(Icons.phone_outlined, s.phone, u.phone),
                        if (u.city != null && u.city!.isNotEmpty)
                          _row(Icons.location_city_rounded, s.city, u.city!),
                        _row(Icons.badge_outlined, s.role,
                            u.role == 'driver' ? s.driver : s.passenger),
                        _actionRow(Icons.edit_rounded, s.editProfile,
                            _openEdit),
                        _actionRow(Icons.history_rounded, s.tripHistory,
                            _openHistory),
                      ]),
                      if (isDriver) ...[
                        const SizedBox(height: 12),
                        _driverDocsCard(u),
                      ],
                      const SizedBox(height: 12),
                      _languageCard(),
                      const SizedBox(height: 12),
                      _section(s.preferences, [
                        _toggleRow(Icons.notifications_active_rounded,
                            s.pushNotifications, true),


                      ]),
                      const SizedBox(height: 12),
                      _section(s.support, [
                        _actionRow(Icons.support_agent_rounded, s.contactUs,
                            _openContact),
                        _linkRow(Icons.help_outline_rounded, s.helpCenter),
                        _linkRow(Icons.policy_outlined, s.termsPrivacy),
                        _linkRow(Icons.info_outline_rounded,
                            s.aboutSmartRide),
                      ]),
                      const SizedBox(height: 18),
                      SecondaryButton(
                        label: _busy ? s.signingOut : s.logOut,
                        icon: Icons.logout_rounded,
                        color: AppColors.rose,
                        onTap: _busy ? null : _logout,
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          '${s.appName} · v1.0',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _languageCard() {
    final s = S.of(context);
    final current = LangController.instance.code.value;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded,
                      color: AppColors.primaryDark, size: 16),
                ),
                const SizedBox(width: 10),
                Text(s.language,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _langOption(
                  code: 'en',
                  label: 'English',
                  flag: '🇬🇧',
                  selected: current == 'en',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _langOption(
                  code: 'ar',
                  label: 'العربية',
                  flag: '🇯🇴',
                  selected: current == 'ar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langOption({
    required String code,
    required String label,
    required String flag,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await LangController.instance.setLanguage(code);
        if (mounted) setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
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
          Text(S.of(context).profile,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _heroCard(UserModel u, bool isDriver) {
    final s = S.of(context);
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: (u.imageUrl != null && u.imageUrl!.isNotEmpty)
                ? Image.network(
                    u.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDriver
                                ? Icons.drive_eta_rounded
                                : Icons.airline_seat_recline_normal_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDriver ? s.driver : s.passenger,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4),
                          ),
                          if (isDriver) ...[
                            const SizedBox(width: 6),
                            Icon(
                              u.isActive
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isDriver && u.ratingsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${u.ratingAverage.toStringAsFixed(1)} · ${s.reviewsCount(u.ratingsCount)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(IconData icon, String label, bool initial) {
    return _ToggleRow(icon: icon, label: label, initial: initial);
  }

  /// A row that opens a sub-screen (Edit profile, Contact us…)
  Widget _actionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(IconData icon, String label) {
    return InkWell(
      onTap: () => AppToast.show(context, S.of(context).comingSoon(label)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _driverDocsCard(UserModel u) {
    final s = S.of(context);
    final approved = u.isActive;
    final state = approved ? s.approved : s.pending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: approved
                      ? AppColors.emeraldSoft
                      : AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  approved
                      ? Icons.verified_rounded
                      : Icons.hourglass_top_rounded,
                  color: approved
                      ? AppColors.emerald
                      : const Color(0xFFB45309),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approved ? s.verifiedDriver : s.docsInReview,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      approved ? s.docsApprovedBody : s.docsPendingBody,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _docPill(s.docLicense, state, approved)),
              const SizedBox(width: 8),
              Expanded(
                  child: _docPill(s.docNonConv, state, approved)),
              const SizedBox(width: 8),
              Expanded(
                  child: _docPill(s.docMedical, state, approved)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _docPill(String label, String state, bool approved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: approved ? AppColors.emeraldSoft : AppColors.amberSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(state,
              style: TextStyle(
                  color:
                      approved ? AppColors.emerald : const Color(0xFFB45309),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool initial;
  const _ToggleRow(
      {required this.icon, required this.label, required this.initial});

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool _v;
  @override
  void initState() {
    super.initState();
    _v = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(widget.icon, color: AppColors.textSecondary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Switch.adaptive(
            value: _v,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _v = v),
          ),
        ],
      ),
    );
  }
}
