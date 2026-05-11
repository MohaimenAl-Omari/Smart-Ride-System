import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';
import '../../models/trip_model.dart';
import '../../models/booking_model.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/trip_controller.dart';

/// Driver-side detail view for a single trip:
/// - Route summary with stops
/// - Trip controls (start / complete / cancel)
/// - List of all bookings for this trip with per-passenger
///   accept / reject / check-in actions (F6, F7, F8 in the spec).
class TripPassengersScreen extends StatefulWidget {
  final UserModel user;
  final TripModel trip;
  const TripPassengersScreen(
      {super.key, required this.user, required this.trip});

  @override
  State<TripPassengersScreen> createState() => _TripPassengersScreenState();
}

class _TripPassengersScreenState extends State<TripPassengersScreen> {
  final BookingController _bookingCtl = BookingController();
  final TripController _tripCtl = TripController();

  late TripModel _trip;
  bool _loading = true;
  bool _busy = false;
  List<BookingModel> _bookings = [];
  final Set<int> _checkedInIds = {};

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fresh = await _tripCtl.show(token: widget.user.token, id: _trip.id);
    final list = await _bookingCtl.driverBookings(widget.user.token);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _trip = fresh;
      _bookings = list.where((b) => b.tripId == _trip.id).toList();
      _loading = false;
    });
  }

  Future<void> _accept(BookingModel b) async {
    setState(() => _busy = true);
    final ok = await _bookingCtl.accept(widget.user.token, b.id);
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(context, ok ? 'Booking accepted' : 'Failed', error: !ok);
    if (ok) _load();
  }

  Future<void> _reject(BookingModel b) async {
    setState(() => _busy = true);
    final ok = await _bookingCtl.reject(widget.user.token, b.id);
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(context, ok ? 'Booking rejected' : 'Failed', error: !ok);
    if (ok) _load();
  }

  void _checkIn(BookingModel b) {
    HapticFeedback.lightImpact();
    setState(() => _checkedInIds.add(b.id));
    AppToast.show(context, 'Checked in ${b.passengerName ?? 'passenger'}');
  }

  Future<void> _start() async {
    final ok = await _tripCtl.start(widget.user.token, _trip.id);
    if (!mounted) return;
    AppToast.show(context, ok ? 'Trip started' : 'Failed to start',
        error: !ok);
    if (ok) _load();
  }

  Future<void> _complete() async {
    final ok = await _tripCtl.complete(widget.user.token, _trip.id);
    if (!mounted) return;
    AppToast.show(context, ok ? 'Trip completed' : 'Failed to complete',
        error: !ok);
    if (ok) _load();
  }

  Future<void> _cancel() async {
    final ok = await _tripCtl.cancel(widget.user.token, _trip.id);
    if (!mounted) return;
    AppToast.show(context, ok ? 'Trip cancelled' : 'Failed to cancel',
        error: !ok);
    if (ok) _load();
  }

  int get _accepted =>
      _bookings.where((b) => b.status == 'accepted').length;

  int get _checkedInCount {
    final acceptedIds =
        _bookings.where((b) => b.status == 'accepted').map((b) => b.id);
    return acceptedIds.where(_checkedInIds.contains).length;
  }

  bool get _canStart {
    return _trip.status == 'scheduled' &&
        _checkedInCount >= _trip.minPassengers;
  }

  @override
  Widget build(BuildContext context) {
    final t = _trip;
    final dt = t.departureAt;
    final timeStr =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : Column(
                    children: [
                      _appBar(),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 28),
                            children: [
                              _heroCard(t, timeStr),
                              const SizedBox(height: 12),
                              _checkinProgressCard(),
                              const SizedBox(height: 12),
                              _controls(),
                              const SizedBox(height: 14),
                              SectionHeader(
                                title: 'Passengers',
                                subtitle:
                                    '${_bookings.length} ${_bookings.length == 1 ? 'booking' : 'bookings'} on this trip',
                              ),
                              if (_bookings.isEmpty)
                                const EmptyState(
                                  icon: Icons.airline_seat_recline_normal_rounded,
                                  title: 'No bookings yet',
                                  subtitle:
                                      'Once passengers book this trip, they\'ll appear here.',
                                ),
                              for (final b in _bookings) _passengerCard(b),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
          Text(S.of(context).tripDetails,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          StatusBadge(status: _trip.status),
        ],
      ),
    );
  }

  Widget _heroCard(TripModel t, String timeStr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.primary(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t.origin,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4)),
              const SizedBox(width: 8),
              const Icon(Icons.east_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.destination,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
              ),
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(timeStr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 14),
              const Icon(Icons.event_seat_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text('${t.seatsAvailable}/${t.seatsTotal} free',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${t.pricePerSeat.toStringAsFixed(2)} JD',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkinProgressCard() {
    final accepted = _accepted;
    final min = _trip.minPassengers;
    final goal = min > 0 ? min : (accepted == 0 ? 1 : accepted);
    final ratio = accepted == 0 ? 0.0 : (_checkedInCount / goal).clamp(0.0, 1.0);
    final met = _checkedInCount >= min;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded,
                  color: AppColors.primaryDark, size: 18),
              const SizedBox(width: 8),
              const Text('Check-in progress',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('$_checkedInCount/$min checked in',
                  style: TextStyle(
                      color: met ? AppColors.emerald : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(
                  met ? AppColors.emerald : AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            met
                ? 'Minimum reached — you can start the trip whenever you\'re ready.'
                : 'Trip will start once at least $min passenger${min == 1 ? '' : 's'} ${min == 1 ? 'has' : 'have'} checked in.',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    final canStart = _canStart;
    final canComplete = _trip.status == 'in_progress';
    final canCancel =
        _trip.status == 'scheduled' || _trip.status == 'in_progress';

    if (!canStart && !canComplete && !canCancel) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (canStart)
          Expanded(
              child: PrimaryButton(
                  label: 'Start trip',
                  icon: Icons.play_arrow_rounded,
                  height: 48,
                  onTap: _start)),
        if (canComplete)
          Expanded(
              child: PrimaryButton(
                  label: 'Complete trip',
                  icon: Icons.check_circle_rounded,
                  height: 48,
                  onTap: _complete)),
        if ((canStart || canComplete) && canCancel) const SizedBox(width: 8),
        if (canCancel)
          Expanded(
              child: SecondaryButton(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  color: AppColors.rose,
                  onTap: _cancel)),
      ],
    );
  }

  Widget _passengerCard(BookingModel b) {
    final isPending = b.status == 'pending';
    final isAccepted = b.status == 'accepted';
    final isCheckedIn = _checkedInIds.contains(b.id);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(name: b.passengerName ?? 'P', size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.passengerName ?? 'Passenger',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    Text('${b.seats} seats · ${b.totalPrice.toStringAsFixed(2)} JD',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(
                  status: isCheckedIn && isAccepted ? 'checked_in' : b.status,
                  dense: true),
            ],
          ),
          if (b.pickupStop != null || b.dropoffStop != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alt_route_rounded,
                      color: AppColors.primaryDark, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${b.pickupStop ?? b.tripOrigin ?? '—'}  →  ${b.dropoffStop ?? b.tripDestination ?? '—'}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                    child: SecondaryButton(
                        label: 'Accept',
                        icon: Icons.check_rounded,
                        color: AppColors.emerald,
                        onTap: () => _accept(b))),
                const SizedBox(width: 8),
                Expanded(
                    child: SecondaryButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        color: AppColors.rose,
                        onTap: () => _reject(b))),
              ] else if (isAccepted && !isCheckedIn) ...[
                Expanded(
                    child: SecondaryButton(
                        label: 'Check in',
                        icon: Icons.qr_code_rounded,
                        color: AppColors.primary,
                        onTap: () => _checkIn(b))),
              ] else if (isAccepted && isCheckedIn) ...[
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.emerald.withOpacity(0.4)),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AppColors.emerald, size: 16),
                          SizedBox(width: 6),
                          Text('Checked in',
                              style: TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
