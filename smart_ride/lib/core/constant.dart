import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'localization.dart';

const String baseUrl = "http://127.0.0.1:8000/api";
class AppColors {
  // Surfaces
  static const Color background = Color(0xFFF6F8FB);   // page background
  static const Color surface = Color(0xFFFFFFFF);      // cards, sheets
  static const Color surfaceAlt = Color(0xFFF1F5F9);   // input fields
  static const Color surfaceMuted = Color(0xFFE2E8F0); // dividers, chips

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Brand
  static const Color primary = Color(0xFF0EA5A4);     // teal
  static const Color primaryDark = Color(0xFF0F766E); // deep teal
  static const Color primarySoft = Color(0xFFCCFBF1); // very light teal
  static const Color accent = Color(0xFF0F172A);      // navy
  static const Color accentSoft = Color(0xFF1E293B);

  // Status palette
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldSoft = Color(0xFFD1FAE5);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color rose = Color(0xFFEF4444);
  static const Color roseSoft = Color(0xFFFEE2E2);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color skySoft = Color(0xFFE0F2FE);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);   // navy 900
  static const Color textSecondary = Color(0xFF475569); // slate 600
  static const Color textMuted = Color(0xFF94A3B8);     // slate 400
  static const Color textOnPrimary = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0EA5A4), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0EA5A4), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static List<BoxShadow> primary() => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
  static List<BoxShadow> card() => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> floating() => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.10),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

ThemeData buildSmartRideTheme() {
  const baseFont = 'Roboto';
  return ThemeData.light(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
      error: AppColors.rose,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: baseFont,
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        fontFamily: baseFont,
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        fontFamily: baseFont,
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      bodyMedium: TextStyle(
        fontFamily: baseFont,
        color: AppColors.textSecondary,
        fontSize: 13.5,
      ),
    ),
  );
}

class AppDecor {
  static BoxDecoration card({Color? bg, double radius = 18}) => BoxDecoration(
        color: bg ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card(),
      );

  static BoxDecoration field({bool focused = false, double radius = 14}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: AppColors.surfaceAlt,
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 1.6 : 1,
        ),
      );

  static BoxDecoration gradient({double radius = 14}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: AppColors.primaryGradient,
        boxShadow: AppShadows.primary(),
      );

  static BoxDecoration outline({double radius = 14}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      );
}

class AppToast {
  static void show(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13.5, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: error ? AppColors.rose : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Soft brand glow used behind hero sections.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -60,
            child: _glow(260, AppColors.primary.withOpacity(0.10)),
          ),
          Positioned(
            top: 120,
            left: -80,
            child: _glow(220, AppColors.sky.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

/// Reusable status chip used across passenger / driver / admin views.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool dense;
  const StatusBadge({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final p = _palette(status);
    final label = S.of(context).statusLabel(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: p.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: p.fg,
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusPalette _palette(String s) {
    switch (s) {
      case 'pending':
        return _StatusPalette(
            AppColors.amberSoft, const Color(0xFFB45309));
      case 'accepted':
        return _StatusPalette(
            AppColors.emeraldSoft, AppColors.primaryDark);
      case 'rejected':
        return _StatusPalette(
            AppColors.roseSoft, const Color(0xFFB91C1C));
      case 'cancelled':
        return _StatusPalette(
            AppColors.surfaceMuted, AppColors.textSecondary);
      case 'completed':
        return _StatusPalette(
            AppColors.skySoft, const Color(0xFF0369A1));
      case 'scheduled':
        return _StatusPalette(
            AppColors.primarySoft, AppColors.primaryDark);
      case 'in_progress':
        return _StatusPalette(
            AppColors.emeraldSoft, AppColors.primaryDark);
      case 'checked_in':
        return _StatusPalette(
            AppColors.emeraldSoft, AppColors.primaryDark);
      case 'no_show':
        return _StatusPalette(
            AppColors.roseSoft, const Color(0xFFB91C1C));
      case 'refunded':
        return _StatusPalette(
            AppColors.skySoft, const Color(0xFF0369A1));
      default:
        return _StatusPalette(
            AppColors.surfaceMuted, AppColors.textSecondary);
    }
  }
}

class _StatusPalette {
  final Color bg;
  final Color fg;
  _StatusPalette(this.bg, this.fg);
}

/// A primary CTA used across the whole app.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool fullWidth;
  final double height;
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.loading = false,
    this.fullWidth = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && !loading ? 0.55 : 1,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: fullWidth ? double.infinity : null,
          height: height,
          padding: fullWidth
              ? null
              : const EdgeInsets.symmetric(horizontal: 22),
          decoration: AppDecor.gradient(),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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

/// A secondary/outlined CTA.
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final double height;
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.45)),
          color: c.withOpacity(0.08),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: c, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page section heading – consistent everywhere.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Empty / placeholder card.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: AppDecor.card(),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill icon + value used inside cards.
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const InfoPill({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: c,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Small circular avatar built from the user's first letter.
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialAvatar({super.key, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final letter =
        (name.isEmpty ? '?' : name.trim()[0]).toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: AppShadows.primary(),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Emergency SOS Button
// A floating red button shown on both passenger and driver home screens.
// Tapping it opens a modal with direct-dial buttons for Jordan emergency lines.
// ─────────────────────────────────────────────────────────────────────────────

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  static const _numbers = [
    _EmergencyLine('911', 'General Emergency', Icons.emergency_rounded),
    _EmergencyLine('991', 'Police', Icons.local_police_rounded),
    _EmergencyLine('199', 'Fire Department', Icons.local_fire_department_rounded),
    _EmergencyLine('193', 'Ambulance / Civil Defense', Icons.local_hospital_rounded),
  ];

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EmergencySheet(numbers: _numbers),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.rose,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.rose.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sos_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('SOS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _EmergencyLine {
  final String number;
  final String label;
  final IconData icon;
  const _EmergencyLine(this.number, this.label, this.icon);
}

class _EmergencySheet extends StatelessWidget {
  final List<_EmergencyLine> numbers;
  const _EmergencySheet({required this.numbers});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        AppToast.show(context,
            'Could not launch dialer. Call $number manually.',
            error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.rose.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emergency_rounded,
                      color: AppColors.rose, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Numbers',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text('Tap a number to call immediately',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Number rows
          for (final line in numbers)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GestureDetector(
                onTap: () => _call(context, line.number),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.roseSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.rose.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.rose.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(line.icon,
                            color: AppColors.rose, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.label,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 1),
                            Text(line.number,
                                style: const TextStyle(
                                    color: AppColors.rose,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_rounded,
                                color: Colors.white, size: 15),
                            SizedBox(width: 5),
                            Text('Call',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(
              'Calls are made directly from your phone. '
              'Stay calm and provide your location clearly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 11.5,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
