import 'package:flutter/material.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';

/// Full Privacy Policy screen with sectioned layout, bilingual support,
/// and a contact CTA at the bottom.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final sections = [
      _Section(
        icon: Icons.privacy_tip_rounded,
        color: AppColors.primary,
        title: s.privacyIntroTitle,
        body: s.privacyIntroBody,
      ),
      _Section(
        icon: Icons.manage_search_rounded,
        color: AppColors.sky,
        title: s.privacyCollectTitle,
        body: s.privacyCollectBody,
      ),
      _Section(
        icon: Icons.tune_rounded,
        color: AppColors.emerald,
        title: s.privacyUseTitle,
        body: s.privacyUseBody,
      ),
      _Section(
        icon: Icons.share_rounded,
        color: AppColors.amber,
        title: s.privacySharingTitle,
        body: s.privacySharingBody,
      ),
      _Section(
        icon: Icons.hourglass_bottom_rounded,
        color: AppColors.primaryDark,
        title: s.privacyRetentionTitle,
        body: s.privacyRetentionBody,
      ),
      _Section(
        icon: Icons.gavel_rounded,
        color: AppColors.rose,
        title: s.privacyRightsTitle,
        body: s.privacyRightsBody,
      ),
      _Section(
        icon: Icons.lock_rounded,
        color: AppColors.primary,
        title: s.privacySecurityTitle,
        body: s.privacySecurityBody,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _appBar(context, s),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    children: [
                      _hero(s),
                      const SizedBox(height: 20),
                      ...sections.map((sec) => _sectionCard(sec)),
                      const SizedBox(height: 20),
                      _contactCard(context, s),
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

  Widget _appBar(BuildContext context, S s) {
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
          Text(s.privacyPolicy,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.primary(),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.privacyPolicy,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(s.privacyLastUpdated,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(_Section sec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecor.card(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sec.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(sec.icon, color: sec.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sec.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(sec.body,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(BuildContext context, S s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_rounded,
              color: AppColors.primaryDark, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.privacyContactUs,
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text('privacy@smartride.jo',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.primaryDark),
        ],
      ),
    );
  }
}

class _Section {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Section(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});
}
