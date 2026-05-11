import 'package:flutter/material.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';

/// Lightweight notifications screen that surfaces the trip / booking
/// events from the spec (F10):
///   - booking confirmation
///   - booking cancellation
///   - trip start
///   - minimum-passenger reached (driver)
///   - refund issued
///
/// In a future iteration this will be wired to a real /notifications
/// endpoint and FCM push messages. For now it displays a curated feed
/// derived from booking & trip statuses already available in the API.
class NotificationsScreen extends StatelessWidget {
  final UserModel user;
  const NotificationsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDriver = user.role == 'driver';
    final feed = _seed(s, isDriver);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _appBar(context),
                Expanded(
                  child: feed.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: s.noNotifications,
                            subtitle: s.noNotificationsBody,
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          itemCount: feed.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _card(feed[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_Notif> _seed(S s, bool isDriver) {
    if (isDriver) {
      return [
        _Notif(
          icon: Icons.groups_rounded,
          color: AppColors.primary,
          title: s.nMinReachedTitle,
          body: s.nMinReachedBody,
          time: s.justNow,
          unread: true,
        ),
        _Notif(
          icon: Icons.event_available_rounded,
          color: AppColors.emerald,
          title: s.nNewBookingTitle,
          body: s.nNewBookingBody,
          time: s.agoHours(2),
          unread: true,
        ),
        _Notif(
          icon: Icons.payments_rounded,
          color: AppColors.sky,
          title: s.nPaymentTitle,
          body: s.nPaymentBody,
          time: s.agoDays(1),
        ),
        _Notif(
          icon: Icons.verified_rounded,
          color: AppColors.primaryDark,
          title: s.nDocsTitle,
          body: s.nDocsBody,
          time: s.agoDays(3),
        ),
      ];
    }
    return [
      _Notif(
        icon: Icons.check_circle_rounded,
        color: AppColors.emerald,
        title: s.nBookingConfirmedTitle,
        body: s.nBookingConfirmedBody,
        time: s.justNow,
        unread: true,
      ),
      _Notif(
        icon: Icons.directions_car_filled_rounded,
        color: AppColors.primary,
        title: s.nTripStartingTitle,
        body: s.nTripStartingBody,
        time: s.agoMinutes(15),
        unread: true,
      ),
      _Notif(
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.sky,
        title: s.nRefundTitle,
        body: s.nRefundBody,
        time: s.agoDays(2),
      ),
      _Notif(
        icon: Icons.star_rounded,
        color: AppColors.amber,
        title: s.nRateTitle,
        body: s.nRateBody,
        time: s.agoDays(4),
      ),
    ];
  }

  Widget _appBar(BuildContext context) {
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
          Text(S.of(context).notifications,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
            onPressed: () =>
                AppToast.show(context, S.of(context).markedAllRead),
            icon: const Icon(Icons.done_all_rounded,
                color: AppColors.primaryDark, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _card(_Notif n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: n.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(n.icon, color: n.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ),
                    if (n.unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text(n.time,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notif {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool unread;
  _Notif({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });
}
