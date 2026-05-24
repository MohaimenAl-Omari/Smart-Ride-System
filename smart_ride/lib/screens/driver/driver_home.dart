import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';
import '../../models/trip_model.dart';
import '../../models/booking_model.dart';
import '../../controllers/trip_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../shared/login_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/notifications_screen.dart';
import 'create_trip_screen.dart';
import 'trip_passengers_screen.dart';

class DriverHome extends StatefulWidget {
  final UserModel user;
  const DriverHome({super.key, required this.user});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome>
    with TickerProviderStateMixin {
  final TripController _tripCtl = TripController();
  final BookingController _bookingCtl = BookingController();
  final AuthController _authCtl = AuthController();
  late final NotificationController _notifCtl;

  int _tab = 0;

  bool _loadingTrips = false;
  bool _loadingBookings = false;
  bool _busy = false;

  List<TripModel> _trips = [];
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    // Start notification polling immediately so the badge stays live.
    _notifCtl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(token: widget.user.token));
    _refreshTrips();
    _refreshBookings();
  }

  Future<void> _refreshTrips() async {
    setState(() => _loadingTrips = true);
    final list = await _tripCtl.driverTrips(widget.user.token);
    if (!mounted) return;
    setState(() {
      _trips = list;
      _loadingTrips = false;
    });
  }

  Future<void> _refreshBookings() async {
    setState(() => _loadingBookings = true);
    final list = await _bookingCtl.driverBookings(widget.user.token);
    if (!mounted) return;
    setState(() {
      _bookings = list;
      _loadingBookings = false;
    });
  }

  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    await _authCtl.logout(widget.user.token);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _accept(BookingModel b) async {
    final s = S.of(context);
    setState(() => _busy = true);
    final ok = await _bookingCtl.accept(widget.user.token, b.id);
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(context, ok ? s.bookingAccepted : s.acceptFail, error: !ok);
    if (ok) {
      _refreshBookings();
      _refreshTrips();
    }
  }

  Future<void> _reject(BookingModel b) async {
    final s = S.of(context);
    setState(() => _busy = true);
    final ok = await _bookingCtl.reject(widget.user.token, b.id);
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(context, ok ? s.bookingRejected : s.failed, error: !ok);
    if (ok) _refreshBookings();
  }

  Future<void> _start(TripModel t) async {
    final s = S.of(context);
    final ok = await _tripCtl.start(widget.user.token, t.id);
    if (!mounted) return;
    AppToast.show(context, ok ? s.tripStarted : s.tripStartFailed, error: !ok);
    if (ok) _refreshTrips();
  }

  Future<void> _complete(TripModel t) async {
    final s = S.of(context);
    final ok = await _tripCtl.complete(widget.user.token, t.id);
    if (!mounted) return;
    AppToast.show(context, ok ? s.tripCompleted : s.tripCompleteFailed,
        error: !ok);
    if (ok) _refreshTrips();
  }

  Future<void> _cancel(TripModel t) async {
    final s = S.of(context);
    final confirmed = await _confirm(
      s.cancelTripQ,
      s.cancelTripBody,
      s.cancelTrip,
      destructive: true,
    );
    if (confirmed != true) return;
    final ok = await _tripCtl.cancel(widget.user.token, t.id);
    if (!mounted) return;
    AppToast.show(context, ok ? s.tripCancelled : s.tripCancelFailed,
        error: !ok);
    if (ok) _refreshTrips();
  }

  Future<bool?> _confirm(String title, String msg, String confirmLabel,
      {bool destructive = false}) {
    final s = S.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17)),
        content: Text(msg,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(s.keep),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  destructive ? AppColors.rose : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateTrip() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateTripScreen(user: widget.user)),
    );
    if (created == true) _refreshTrips();
  }

  String get _firstName => widget.user.name.split(' ').first;

  int get _pendingCount =>
      _bookings.where((b) => b.status == 'pending').length;

  int get _scheduledCount =>
      _trips.where((t) => t.status == 'scheduled').length;

  int get _activeCount =>
      _trips.where((t) => t.status == 'in_progress').length;

  double get _projectedEarnings {
    double sum = 0;
    for (final t in _trips) {
      if (t.status == 'completed') {
        sum += t.pricePerSeat * (t.seatsTotal - t.seatsAvailable);
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.user.isActive) return _pendingApprovalScaffold();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildStatsRow(),
                _buildTabSwitch(),
                Expanded(
                  child: _tab == 0 ? _buildTripsTab() : _buildBookingsTab(),
                ),
              ],
            ),
          ),
          // ── Emergency SOS button (left side, FAB is on right) ─────
          Positioned(
            bottom: 24,
            left: 20,
            child: const EmergencyButton(),
          ),
          if (_busy)
            Container(
              color: Colors.black.withOpacity(0.18),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _openCreateTrip,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_road_rounded, color: Colors.white),
              label: Text(S.of(context).newTrip,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _pendingApprovalScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: AppColors.primaryGradient,
                      boxShadow: AppShadows.primary(),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(S.of(context).accountUnderReview,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  Text(
                    S.of(context).accountUnderReviewBody,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecor.card(),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_rounded,
                            color: AppColors.primaryDark, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            S.of(context).supportContact,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: widget.user)),
            ),
            child: InitialAvatar(name: widget.user.name, size: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).driverHeader(_firstName),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                Text(S.of(context).manageTripsSub,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          Obx(() {
            final unread = _notifCtl.unreadCount.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(user: widget.user)),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: AppColors.textPrimary, size: 22),
                ),
                if (unread > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.rose,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Expanded(
              child: _statCard(
                  s.scheduled,
                  _scheduledCount.toString(),
                  Icons.event_available_rounded,
                  AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(
              child: _statCard(
                  s.active,
                  _activeCount.toString(),
                  Icons.directions_car_filled_rounded,
                  AppColors.emerald)),
          const SizedBox(width: 10),
          Expanded(
              child: _statCard(
                  s.earnings,
                  '${_projectedEarnings.toStringAsFixed(0)} ${s.currency}',
                  Icons.payments_rounded,
                  AppColors.sky)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _tabItem(S.of(context).myTrips, 0, Icons.route_rounded, badge: 0),
            _tabItem(S.of(context).requests, 1, Icons.inbox_rounded,
                badge: _pendingCount),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int idx, IconData icon, {int badge = 0}) {
    final selected = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tab = idx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selected ? AppColors.primaryGradient : null,
            boxShadow: selected ? AppShadows.primary() : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppColors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge.toString(),
                      style: TextStyle(
                          color: selected
                              ? AppColors.primaryDark
                              : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripsTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshTrips,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          if (_loadingTrips)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            ),
          if (!_loadingTrips && _trips.isEmpty)
            EmptyState(
              icon: Icons.route_rounded,
              title: S.of(context).noTripsYet,
              subtitle: S.of(context).noTripsBodyDriver,
            ),
          for (final t in _trips) _tripCard(t),
        ],
      ),
    );
  }

  Widget _tripCard(TripModel t) {
    final dt = t.departureAt;
    final timeStr =
        '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final canStart = t.status == 'scheduled';
    final canComplete = t.status == 'in_progress';
    final canCancel = t.status == 'scheduled' || t.status == 'in_progress';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  TripPassengersScreen(user: widget.user, trip: t)),
        );
        _refreshTrips();
        _refreshBookings();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppDecor.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${t.origin}  →  ${t.destination}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                ),
                StatusBadge(status: t.status),
              ],
            ),
            if (t.stops.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: t.stops
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                InfoPill(icon: Icons.schedule_rounded, text: timeStr),
                const SizedBox(width: 12),
                InfoPill(
                    icon: Icons.event_seat_rounded,
                    text: '${t.seatsAvailable}/${t.seatsTotal}'),
                const Spacer(),
                Text(
                    '${t.pricePerSeat.toStringAsFixed(2)} ${S.of(context).currency}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            if (canStart || canComplete || canCancel) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canStart)
                    Expanded(
                        child: _actionBtn(
                            S.of(context).start,
                            Icons.play_arrow_rounded,
                            AppColors.emerald,
                            () => _start(t))),
                  if (canStart) const SizedBox(width: 8),
                  if (canComplete)
                    Expanded(
                        child: _actionBtn(
                            S.of(context).complete,
                            Icons.check_circle_rounded,
                            AppColors.primary,
                            () => _complete(t))),
                  if (canComplete) const SizedBox(width: 8),
                  if (canCancel)
                    Expanded(
                        child: _actionBtn(S.of(context).cancelTrip,
                            Icons.close_rounded, AppColors.rose,
                            () => _cancel(t))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return SecondaryButton(
        label: label, icon: icon, color: color, onTap: onTap);
  }

  Widget _buildBookingsTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBookings,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (_loadingBookings)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            ),
          if (!_loadingBookings && _bookings.isEmpty)
            EmptyState(
              icon: Icons.inbox_rounded,
              title: S.of(context).noBookingRequests,
              subtitle: S.of(context).noBookingRequestsBody,
            ),
          for (final b in _bookings) _bookingCard(b),
        ],
      ),
    );
  }

  Widget _bookingCard(BookingModel b) {
    final dt = b.tripDepartureAt;
    final timeStr = dt == null
        ? ''
        : '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final isPending = b.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(name: b.passengerName ?? 'P', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.passengerName ?? S.of(context).passenger,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800)),
                    if (b.passengerPhone != null)
                      Text(b.passengerPhone!,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(status: b.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${b.tripOrigin ?? '—'}  →  ${b.tripDestination ?? '—'}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InfoPill(icon: Icons.schedule_rounded, text: timeStr),
                    const SizedBox(width: 12),
                    InfoPill(
                        icon: Icons.event_seat_rounded,
                        text: '${b.seats} seats'),
                    const Spacer(),
                    Text('${b.totalPrice.toStringAsFixed(2)} JD',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                if (b.pickupStop != null || b.dropoffStop != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded,
                          color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${b.pickupStop ?? b.tripOrigin ?? '—'}  →  ${b.dropoffStop ?? b.tripDestination ?? '—'}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: SecondaryButton(
                        label: S.of(context).accept,
                        icon: Icons.check_rounded,
                        color: AppColors.emerald,
                        onTap: () => _accept(b))),
                const SizedBox(width: 8),
                Expanded(
                    child: SecondaryButton(
                        label: S.of(context).reject,
                        icon: Icons.close_rounded,
                        color: AppColors.rose,
                        onTap: () => _reject(b))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
