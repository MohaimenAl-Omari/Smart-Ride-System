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
import 'trip_details_screen.dart';
import 'booking_details_screen.dart';

class PassengerHome extends StatefulWidget {
  final UserModel user;
  const PassengerHome({super.key, required this.user});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome>
    with TickerProviderStateMixin {
  final TripController _tripCtl = TripController();
  final BookingController _bookingCtl = BookingController();
  final AuthController _authCtl = AuthController();
  late final NotificationController _notifCtl;

  final TextEditingController _fromCtl = TextEditingController();
  final TextEditingController _toCtl = TextEditingController();

  int _tab = 0;
  bool _loadingTrips = false;
  bool _loadingBookings = false;
  List<TripModel> _trips = [];
  List<BookingModel> _bookings = [];

  /// Mutable copy of the user — refreshed from /api/me on every load
  /// so the debt balance banner always reflects the latest server state.
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    // Start notification polling immediately so the badge stays live.
    _notifCtl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(token: widget.user.token));
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    // Refresh user balance first, then trips and bookings in parallel
    final fresh = await _authCtl.getMe(widget.user.token);
    if (mounted && fresh != null) {
      setState(() => _currentUser = fresh);
    }
    await Future.wait([_refreshTrips(), _refreshBookings()]);
  }

  @override
  void dispose() {
    _fromCtl.dispose();
    _toCtl.dispose();
    super.dispose();
  }

  Future<void> _refreshTrips() async {
    setState(() => _loadingTrips = true);
    final list = await _tripCtl.search(
      token: widget.user.token,
      from: _fromCtl.text.trim().isEmpty ? null : _fromCtl.text.trim(),
      to: _toCtl.text.trim().isEmpty ? null : _toCtl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _trips = list;
      _loadingTrips = false;
    });
  }

  Future<void> _refreshBookings() async {
    setState(() => _loadingBookings = true);
    final list = await _bookingCtl.myBookings(widget.user.token);
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

  Future<void> _cancelBooking(BookingModel b) async {
    final s = S.of(context);
    final confirmed = await _confirmDialog(
      title: s.cancelBookingQ,
      message: s.cancelBookingBody,
      confirmText: s.cancelBooking,
      destructive: true,
    );
    if (confirmed != true) return;
    final ok = await _bookingCtl.cancel(widget.user.token, b.id);
    if (!mounted) return;
    AppToast.show(context, ok ? s.bookingCancelled : s.failedToCancel,
        error: !ok);
    if (ok) _refreshBookings();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    String? confirmText,
    bool destructive = false,
  }) {
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
        content: Text(message,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
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
            child: Text(confirmText ?? s.confirm),
          ),
        ],
      ),
    );
  }

  String get _firstName => _currentUser.name.split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                if (_currentUser.balance < 0) _buildDebtBanner(),
                _buildTabSwitch(),
                Expanded(
                  child: _tab == 0 ? _buildSearchTab() : _buildBookingsTab(),
                ),
              ],
            ),
          ),
          // ── Emergency SOS button ──────────────────────────────────
          Positioned(
            bottom: 24,
            right: 20,
            child: const EmergencyButton(),
          ),
        ],
      ),
    );
  }

  /// Prominent debt card shown when the passenger has an unpaid no-show penalty.
  Widget _buildDebtBanner() {
    final debt = _currentUser.balance.abs();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444),
            const Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Outstanding Debt',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${debt.toStringAsFixed(2)} JD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠  You missed a trip check-in. This amount will be added to your next booking.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            child: InitialAvatar(name: _currentUser.name, size: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).greeting(_firstName),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                Text(S.of(context).whereToToday,
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
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
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

  Widget _buildTabSwitch() {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _tabItem(s.findARide, 0, Icons.search_rounded),
            _tabItem(s.myBookings, 1, Icons.confirmation_number_rounded),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int idx, IconData icon) {
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
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                    size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
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

  Widget _buildSearchTab() {
    final s = S.of(context);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshTrips,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _buildSearchBox(),
          const SizedBox(height: 18),
          SectionHeader(
            title: s.tripsAvailable(_trips.length),
            subtitle: s.updatedJustNow,
            trailing: _loadingTrips
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.primary)),
                  )
                : null,
          ),
          if (_trips.isEmpty && !_loadingTrips)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: s.noTripsYet,
              subtitle: s.noTripsBody,
            ),
          for (final t in _trips) _tripCard(t),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniField(
                    _fromCtl, s.from, Icons.my_location_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniField(_toCtl, s.to, Icons.place_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: s.searchTrips,
            icon: Icons.search_rounded,
            height: 46,
            onTap: _refreshTrips,
          ),
        ],
      ),
    );
  }

  Widget _miniField(TextEditingController c, String hint, IconData icon) {
    return Container(
      decoration: AppDecor.field(),
      child: TextField(
        controller: c,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primaryDark),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        ),
      ),
    );
  }

  Widget _tripCard(TripModel t) {
    final dt = t.departureAt;
    final timeStr =
        '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final lowSeats = t.seatsAvailable <= 2;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  TripDetailsScreen(user: widget.user, tripId: t.id)),
        );
        _refreshBookings();
        _refreshTrips();
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
                _routeNode(t.origin, true),
                Expanded(child: _routeLine(t.stops.length)),
                _routeNode(t.destination, false),
              ],
            ),
            if (t.stops.isNotEmpty) ...[
              const SizedBox(height: 10),
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
            const SizedBox(height: 14),
            Row(
              children: [
                InfoPill(icon: Icons.schedule_rounded, text: timeStr),
                const SizedBox(width: 12),
                InfoPill(
                  icon: Icons.event_seat_rounded,
                  text: '${t.seatsAvailable}/${t.seatsTotal}',
                  color: lowSeats ? AppColors.amber : AppColors.textSecondary,
                ),
                const Spacer(),
                Text(
                    '${t.pricePerSeat.toStringAsFixed(2)} ${S.of(context).currency}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            if (t.driverName != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  InitialAvatar(name: t.driverName!, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.driverName!,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        if (t.carModel != null)
                          Text(
                              [t.carModel, t.carPlate]
                                  .where((e) =>
                                      e != null && e.toString().isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            color: AppColors.primaryDark, size: 14),
                        SizedBox(width: 4),
                        Text('View',
                            style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeNode(String label, bool start) {
    final color = start ? AppColors.primary : AppColors.primaryDark;
    return Column(
      crossAxisAlignment:
          start ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3)),
      ],
    );
  }

  Widget _routeLine(int stopCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: List.generate(
              stopCount + 1,
              (i) => Expanded(
                child: Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: stopCount == 0 ? 0 : 2),
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Icon(Icons.directions_car_filled_rounded,
              color: AppColors.primary, size: 14),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final upcoming = _bookings
        .where((b) => b.status != 'completed' && b.status != 'cancelled')
        .toList();
    final history = _bookings
        .where((b) => b.status == 'completed' || b.status == 'cancelled')
        .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBookings,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (_loadingBookings)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          if (!_loadingBookings && _bookings.isEmpty)
            EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: S.of(context).noBookingsYet,
              subtitle: S.of(context).noBookingsBody,
            ),
          if (upcoming.isNotEmpty) ...[
            SectionHeader(
              title: S.of(context).upcoming,
              subtitle: S.of(context).upcomingSub,
            ),
            for (final b in upcoming) _bookingCard(b),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionHeader(
              title: S.of(context).pastTrips,
              subtitle: S.of(context).pastTripsSub,
            ),
            for (final b in history) _bookingCard(b),
          ],
        ],
      ),
    );
  }

  Widget _bookingCard(BookingModel b) {
    final dt = b.tripDepartureAt;
    final timeStr = dt == null
        ? ''
        : '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    // Cannot cancel once checked in (enforced on both client and server)
    final canCancel = !b.isCheckedIn &&
        (b.status == 'pending' || b.status == 'accepted');

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  BookingDetailsScreen(user: widget.user, booking: b)),
        );
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
                  child: Text(
                      '${b.tripOrigin ?? '—'}  →  ${b.tripDestination ?? '—'}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                ),
                StatusBadge(status: b.status),
              ],
            ),
            if ((b.pickupStop != null && b.pickupStop!.isNotEmpty) ||
                (b.dropoffStop != null && b.dropoffStop!.isNotEmpty)) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.alt_route_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${b.pickupStop ?? b.tripOrigin ?? '—'} → ${b.dropoffStop ?? b.tripDestination ?? '—'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                InfoPill(icon: Icons.schedule_rounded, text: timeStr),
                const SizedBox(width: 12),
                InfoPill(
                    icon: Icons.event_seat_rounded,
                    text: '${b.seats} ${S.of(context).seats}'),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        '${b.totalPrice.toStringAsFixed(2)} ${S.of(context).currency}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800)),
                    if (b.debtCarried > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.rose.withOpacity(0.3)),
                        ),
                        child: Text(
                          '+ ${b.debtCarried.toStringAsFixed(2)} JD debt',
                          style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (b.driverName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(b.driverName!,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                    if (b.carPlate != null) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppColors.textMuted)),
                      Text(b.carPlate!,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
            ],
            if (canCancel) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                label: S.of(context).cancelBooking,
                icon: Icons.close_rounded,
                color: AppColors.rose,
                onTap: () => _cancelBooking(b),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
