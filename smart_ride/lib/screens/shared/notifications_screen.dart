import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/notification_model.dart';
import '../../models/user-model.dart';
import '../../controllers/notification_controller.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel user;
  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late NotificationController _ctl;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    if (Get.isRegistered<NotificationController>()) {
      _ctl = Get.find<NotificationController>();
    } else {
      _ctl = Get.put(NotificationController(token: widget.user.token));
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<NotificationModel> get _displayed {
    if (_tab.index == 1) {
      return _ctl.notifications.where((n) => !n.isRead).toList();
    }
    return _ctl.notifications.toList();
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
                _tabBar(s),
                Expanded(
                  child: Obx(() {
                    if (_ctl.loading.value && _ctl.notifications.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final displayed = _displayed;
                    if (displayed.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: s.noNotifications,
                          subtitle: s.noNotificationsBody,
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _ctl.fetchNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: displayed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final notif = displayed[i];
                          return Dismissible(
                            key: ValueKey(notif.id),
                            direction: DismissDirection.endToStart,
                            background: _dismissBg(),
                            onDismissed: (_) {
                              HapticFeedback.lightImpact();
                              _ctl.deleteNotification(notif.id);
                            },
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                if (!notif.isRead) _ctl.markRead(notif.id);
                              },
                              child: _card(notif),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar(S s) {
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42, height: 42,
                  decoration: AppDecor.outline(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(s.notifications,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    if (_ctl.unreadCount.value > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.rose,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('${_ctl.unreadCount.value}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
              if (_ctl.notifications.isNotEmpty) ...[
                if (_ctl.unreadCount.value > 0)
                  IconButton(
                    tooltip: s.markedAllRead,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _ctl.markAllRead();
                      AppToast.show(context, s.markedAllRead);
                    },
                    icon: const Icon(Icons.done_all_rounded,
                        color: AppColors.primaryDark, size: 20),
                  ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _ctl.fetchNotifications,
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ],
            ],
          ),
        ));
  }

  Widget _tabBar(S s) {
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: s.allNotifs),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.unreadNotifs,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      if (_ctl.unreadCount.value > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: _tab.index == 1
                                ? Colors.white.withOpacity(0.3)
                                : AppColors.rose,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${_ctl.unreadCount.value}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _card(NotificationModel n) {
    final style = n.style;
    final color = Color(style.colorValue);
    final icon  = IconData(style.iconCodePoint, fontFamily: 'MaterialIcons');
    final timeStr = _relativeTime(n.createdAt);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !n.isRead ? color.withOpacity(0.28) : AppColors.border,
          width: !n.isRead ? 1.4 : 1,
        ),
        boxShadow: !n.isRead ? AppShadows.card() : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!n.isRead)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.rose,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(n.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: !n.isRead ? FontWeight.w800 : FontWeight.w600,
                        )),
                  ),
                  const SizedBox(width: 8),
                  _typeBadge(n.type),
                ]),
                const SizedBox(height: 4),
                Text(n.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text(timeStr,
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

  Widget _typeBadge(String type) {
    final label = _typeLabel(type);
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2)),
    );
  }

  Widget _dismissBg() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: AppColors.roseSoft,
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.rose, size: 24),
      );

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'booking_created':
      case 'booking_accepted':
      case 'booking_rejected':
      case 'booking_cancelled':
        return 'Booking';
      case 'trip_started':
      case 'trip_cancelled':
      case 'trip_completed':
        return 'Trip';
      case 'driver_rated':
        return 'Rating';
      default:
        return 'System';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'booking_created':
      case 'booking_accepted':
        return AppColors.emerald;
      case 'booking_rejected':
      case 'booking_cancelled':
      case 'trip_cancelled':
        return AppColors.rose;
      case 'trip_started':
      case 'trip_completed':
        return AppColors.primary;
      case 'driver_rated':
        return AppColors.amber;
      default:
        return AppColors.textMuted;
    }
  }
}
