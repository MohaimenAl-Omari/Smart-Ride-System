import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../controllers/booking_controller.dart';
import '../shared/driver_profile_screen.dart';
import 'segment_booking_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final UserModel user;
  final int tripId;
  const TripDetailsScreen(
      {super.key, required this.user, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final TripController _tripCtl = TripController();
  final BookingController _bookingCtl = BookingController();

  TripModel? _trip;
  bool _loading = true;
  bool _booking = false;

  int _seats = 1;
  String? _pickupStop;
  String? _dropoffStop;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await _tripCtl.show(token: widget.user.token, id: widget.tripId);
    if (!mounted) return;
    setState(() {
      _trip = t;
      _loading = false;
    });
  }

  Future<void> _book() async {
    if (_trip == null) return;
    setState(() => _booking = true);
    HapticFeedback.mediumImpact();
    final res = await _bookingCtl.create(
      token: widget.user.token,
      tripId: _trip!.id,
      seats: _seats,
      pickupStop: _pickupStop,
      dropoffStop: _dropoffStop,
    );
    if (!mounted) return;
    setState(() => _booking = false);
    AppToast.show(context, res.message, error: !res.success);
    if (res.success) Navigator.pop(context);
  }

  /// Returns true when the passenger has chosen stops that differ from the
  /// full route (origin → destination). For partial routes the exact price is
  /// only known after SegmentBookingScreen queries the per-segment API data.
  bool _isPartialRoute(TripModel t) {
    final from = _pickupStop ?? t.origin;
    final to = _dropoffStop ?? t.destination;
    return from != t.origin || to != t.destination;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : (_trip == null ? _missing() : _buildContent(_trip!)),
          ),
        ],
      ),
    );
  }

  Widget _missing() {
    final s = S.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.rose, size: 40),
          const SizedBox(height: 12),
          Text(s.tripUnavailable,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.goBack,
                style: const TextStyle(color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TripModel t) {
    final dt = t.departureAt;
    final timeStr =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final maxSeats = t.seatsAvailable > 0 ? t.seatsAvailable : 1;
    final stopsForPicker = ['(none)', t.origin, ...t.stops, t.destination];

    return Column(
      children: [
        _appBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _routeCard(t),
              const SizedBox(height: 12),
              _detailsRow(timeStr, t),
              const SizedBox(height: 12),
              if (t.driverName != null) _driverCard(t),
              if (t.driverName != null) const SizedBox(height: 12),
              if (t.notes != null && t.notes!.isNotEmpty) _notesCard(t),
              if (t.notes != null && t.notes!.isNotEmpty)
                const SizedBox(height: 12),
              _bookingPanel(t, maxSeats, stopsForPicker),
              const SizedBox(height: 18),
              _bookButton(t),
            ],
          ),
        ),
      ],
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
        ],
      ),
    );
  }

  Widget _routeCard(TripModel t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stopRow(t.origin, isStart: true),
          for (final s in t.stops) _stopRow(s),
          _stopRow(t.destination, isEnd: true),
        ],
      ),
    );
  }

  Widget _stopRow(String label,
      {bool isStart = false, bool isEnd = false}) {
    final color = isStart
        ? AppColors.primary
        : (isEnd ? AppColors.primaryDark : AppColors.borderStrong);
    final isHero = isStart || isEnd;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: isHero ? 14 : 10,
                height: isHero ? 14 : 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: isHero
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.35), blurRadius: 8),
                        ]
                      : null,
                ),
              ),
              if (!isEnd)
                Container(
                  width: 2,
                  height: 22,
                  color: AppColors.borderStrong,
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 4),
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: isHero ? 16 : 14,
                      fontWeight:
                          isHero ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: -0.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsRow(String time, TripModel t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: AppDecor.card(),
      child: Row(
        children: [
          Expanded(
              child: _stat(S.of(context).departure, time,
                  Icons.schedule_rounded)),
          _vDivider(),
          Expanded(
              child: _stat(S.of(context).seats,
                  '${t.seatsAvailable}/${t.seatsTotal}',
                  Icons.event_seat_rounded)),
          _vDivider(),
          Expanded(
              child: _stat(
                  S.of(context).perSeat,
                  '${t.pricePerSeat.toStringAsFixed(2)} ${S.of(context).currency}',
                  Icons.payments_rounded)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 32,
        color: AppColors.border,
      );

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 16),
        ),
        const SizedBox(height: 6),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10.5)),
      ],
    );
  }

  Widget _driverCard(TripModel t) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverProfileScreen(
            driverId: t.driverId,
            driverName: t.driverName ?? '',
            viewer: widget.user,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.card(),
        child: Row(
          children: [
            InitialAvatar(name: t.driverName!, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.driverName!,
                          style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryDark),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Star rating row
                  if (t.driverRatingsCount > 0) ...[
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: t.driverRatingAverage,
                          itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.amber),
                          itemCount: 5,
                          itemSize: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${t.driverRatingAverage.toStringAsFixed(1)}  (${t.driverRatingsCount})',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ] else ...[
                    Text(
                      S.of(context).noRatingsYet,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    [t.carModel, t.carPlate]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (t.driverPhone != null)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.emeraldSoft,
                  border:
                      Border.all(color: AppColors.emerald.withOpacity(0.4)),
                ),
                child: const Icon(Icons.phone_rounded,
                    color: AppColors.emerald, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _notesCard(TripModel t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFFB45309), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).driverNotes,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(t.notes ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingPanel(
      TripModel t, int maxSeats, List<String> stopsForPicker) {
    final s = S.of(context);
    final partial = _isPartialRoute(t);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: s.yourBooking,
            subtitle: s.yourBookingSub,
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: AppDecor.field(),
            child: Row(
              children: [
                const Icon(Icons.event_seat_rounded,
                    size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(s.seats,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                _seatStepper(maxSeats),
              ],
            ),
          ),
          if (t.stops.isNotEmpty) ...[
            const SizedBox(height: 10),
            _stopPicker(s.pickupAt, _pickupStop, stopsForPicker,
                (v) => setState(() => _pickupStop = v == '(none)' ? null : v)),
            const SizedBox(height: 10),
            _stopPicker(s.dropoffAt, _dropoffStop, stopsForPicker,
                (v) => setState(() => _dropoffStop = v == '(none)' ? null : v)),
          ],
          const SizedBox(height: 14),
          // ── Price display ─────────────────────────────────────────
          // For the full route we show the exact price per seat × seats.
          // For a partial route the real price is per-segment and only
          // known after SegmentBookingScreen fetches API data, so we
          // show an "exact price at checkout" notice instead of a
          // potentially wrong proportional estimate.
          if (!partial)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded,
                      color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Text(s.total,
                      style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    '${(_seats * t.pricePerSeat).toStringAsFixed(2)} ${s.currency}',
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.priceAtCheckout,
                            style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(s.priceAtCheckoutSub,
                            style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
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

  Widget _seatStepper(int maxSeats) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
            icon: Icon(Icons.remove_rounded,
                size: 18,
                color: _seats > 1
                    ? AppColors.primaryDark
                    : AppColors.textMuted),
          ),
          SizedBox(
            width: 26,
            child: Text(_seats.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed:
                _seats < maxSeats ? () => setState(() => _seats++) : null,
            icon: Icon(Icons.add_rounded,
                size: 18,
                color: _seats < maxSeats
                    ? AppColors.primaryDark
                    : AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _stopPicker(String label, String? value, List<String> options,
      ValueChanged<String?> onChanged) {
    final isPickup = label == S.of(context).pickupAt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: AppDecor.field(),
      child: Row(
        children: [
          Icon(
              isPickup
                  ? Icons.my_location_rounded
                  : Icons.place_outlined,
              size: 16,
              color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          DropdownButton<String>(
            value: value ?? '(none)',
            dropdownColor: AppColors.surface,
            underline: const SizedBox.shrink(),
            iconEnabledColor: AppColors.textSecondary,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600),
            items: options
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _bookButton(TripModel t) {
    final s = S.of(context);
    final disabled = t.status != 'scheduled' || t.seatsAvailable < 1;
    final label = t.seatsAvailable < 1
        ? s.soldOut
        : t.status != 'scheduled'
            ? s.tripStatusLabel(t.status)
            : s.confirmAndBook;
    return PrimaryButton(
      label: label,
      icon: Icons.lock_outline_rounded,
      loading: false,
      height: 54,
      onTap: disabled
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SegmentBookingScreen(
                    user:   widget.user,
                    tripId: widget.tripId,
                    from:   _pickupStop  ?? t.origin,
                    to:     _dropoffStop ?? t.destination,
                    seats:  _seats,
                  ),
                ),
              ),
    );
  }
}
