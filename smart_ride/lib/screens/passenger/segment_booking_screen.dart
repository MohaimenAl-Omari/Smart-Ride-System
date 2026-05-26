import 'package:flutter/material.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';
import '../../models/trip_segment_model.dart';
import '../../controllers/segment_controller.dart';
import '../shared/payment_screen.dart';

class SegmentBookingScreen extends StatefulWidget {
  final UserModel user;
  final int       tripId;
  final String    from;
  final String    to;
  final int       seats;
  const SegmentBookingScreen({
    super.key,
    required this.user,
    required this.tripId,
    required this.from,
    required this.to,
    required this.seats,
  });

  @override
  State<SegmentBookingScreen> createState() => _SegmentBookingScreenState();
}

class _SegmentBookingScreenState extends State<SegmentBookingScreen> {
  final SegmentController _ctl = SegmentController();

  bool _loading  = true;
  bool _booking  = false;
  bool _attempted = false;

  List<TripSegmentModel> _segments     = const [];
  List<String>           _orderedStops = const [];
  final _areaCtl     = TextEditingController();
  final _streetCtl   = TextEditingController();
  final _buildingCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _areaCtl.dispose();
    _streetCtl.dispose();
    _buildingCtl.dispose();
    super.dispose();
  }


  Future<void> _load() async {
    final segs = await _ctl.listSegments(widget.user.token, widget.tripId);
    if (!mounted) return;
    setState(() {
      _segments     = segs;
      _orderedStops = _buildOrderedStops(segs);
      _loading      = false;
    });
  }

  List<String> _buildOrderedStops(List<TripSegmentModel> segs) {
    if (segs.isEmpty) return const [];
    final sorted = [...segs]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return [sorted.first.startStop, ...sorted.map((s) => s.endStop)];
  }

  List<TripSegmentModel> _route() {
    final iFrom = _orderedStops.indexOf(widget.from);
    final iTo   = _orderedStops.indexOf(widget.to);
    if (iFrom < 0 || iTo <= iFrom) return const [];
    return _segments
        .where((s) => s.orderIndex >= iFrom && s.orderIndex < iTo)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  double get _totalPrice =>
      _route().fold(0.0, (acc, s) => acc + s.price) * widget.seats;

  double get _grandTotal {
    final bal = widget.user.balance;
    return bal < 0 ? _totalPrice + bal.abs() : _totalPrice;
  }

  int get _totalMinutes =>
      _route().fold(0, (acc, s) => acc + s.estimatedMinutes);

  bool get _areaFilled => _areaCtl.text.trim().isNotEmpty;

  bool get _canBook {
    final route = _route();
    return route.isNotEmpty &&
        route.every((s) => s.seatsAvailable >= widget.seats) &&
        _areaFilled;
  }

  String _bookLabel(S s) {
    if (_route().isEmpty) return s.noSegmentsForRoute;
    if (!_areaFilled)     return s.enterPickupArea;
    return s.confirmBooking;
  }

  Future<void> _book() async {
    setState(() => _attempted = true);
    if (!_canBook) return;
    setState(() => _booking = true);

    final res = await _ctl.bookWithLocation(
      token:            widget.user.token,
      tripId:           widget.tripId,
      from:             widget.from,
      to:               widget.to,
      seats:            widget.seats,
      locationArea:     _areaCtl.text.trim(),
      locationStreet:   _streetCtl.text.trim(),
      locationBuilding: _buildingCtl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _booking = false);
    AppToast.show(context, res.message, error: !res.success);

    if (res.success) {
      final charged = res.booking != null
          ? (double.tryParse(
                  res.booking!['total_price']?.toString() ?? '') ??
              _grandTotal)
          : _grandTotal;

      final bookingId = res.booking?['id'] as int?;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            amount:    charged,
            tripRoute: '${widget.from} → ${widget.to}',
            seats:     widget.seats,
            bookingId: bookingId,
            token:     widget.user.token,
            onSuccess: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(s.confirmBooking)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _segments.isEmpty
              ? EmptyState(
                  title: s.noSegmentsAvailable,
                  subtitle: s.noSegmentsAvailableSub,
                  icon: Icons.alt_route_rounded,
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = S.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [

        SectionHeader(
          title: s.yourRoute,
          subtitle: s.yourRouteSub,
        ),
        _routeCard(),
        const SizedBox(height: 18),
        SectionHeader(
          title: s.yourPickupAddress,
          subtitle: s.yourPickupAddressSub,
        ),
        _buildLocationCard(),
        const SizedBox(height: 18),
        _summaryCard(),
        const SizedBox(height: 18),

        PrimaryButton(
          label:   _bookLabel(s),
          icon:    Icons.check_circle_outline_rounded,
          onTap:   _canBook && !_booking ? _book : null,
          loading: _booking,
        ),
      ],
    );
  }

  Widget _routeCard() {
    final s = S.of(context);
    final route = _route();
    if (route.isEmpty) {
      return EmptyState(
        title: s.routeNotFound,
        subtitle: s.routeNotFoundSub,
        icon: Icons.directions_outlined,
      );
    }
    return Container(
      decoration: AppDecor.card(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // From → To header
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.from}  →  ${widget.to}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                InfoPill(
                  icon:  Icons.event_seat_rounded,
                  text:  '${widget.seats} seat${widget.seats > 1 ? 's' : ''}',
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (final s in route)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${s.orderIndex + 1}',
                        style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${s.startStop}  →  ${s.endStop}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                  InfoPill(
                    icon:  Icons.event_seat_rounded,
                    text:  '${s.seatsAvailable}/${s.seatsTotal}',
                    color: s.seatsAvailable >= widget.seats
                        ? AppColors.primaryDark
                        : AppColors.rose,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('JOD ${s.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildLocationCard() {
    final s = S.of(context);
    final areaError = _attempted && !_areaFilled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: areaError
              ? AppColors.rose.withOpacity(0.6)
              : AppColors.border,
          width: areaError ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Area / Neighborhood (required)
          _locationField(
            controller: _areaCtl,
            label:     s.locationArea,
            hint:      'e.g.  Abdali,  4th Circle,  Zarqa',
            icon:      Icons.location_city_rounded,
            required:  true,
            showError: areaError,
            errorText: s.areaRequired,
          ),
          const SizedBox(height: 14),

          _locationField(
            controller: _streetCtl,
            label: s.streetName,
            hint:  'e.g.  Al-Madinah Al-Munawwarah St.',
            icon:  Icons.signpost_rounded,
          ),
          const SizedBox(height: 14),
          _locationField(
            controller: _buildingCtl,
            label: s.buildingNumber,
            hint:  'e.g.  12,   7A,   Blue Tower',
            icon:  Icons.apartment_rounded,
          ),

          if (_areaFilled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primaryDark, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildPreview(),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildPreview() {
    final parts = <String>[];
    final b = _buildingCtl.text.trim();
    final s = _streetCtl.text.trim();
    final a = _areaCtl.text.trim();
    if (b.isNotEmpty) parts.add('Bldg $b');
    if (s.isNotEmpty) parts.add(s);
    if (a.isNotEmpty) parts.add(a);
    return parts.join(', ');
  }

  Widget _locationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required  = false,
    bool showError = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            if (required)
              const Text(' *',
                  style: TextStyle(
                      color: AppColors.rose,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: showError
                  ? AppColors.rose.withOpacity(0.7)
                  : AppColors.border,
              width: showError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller:      controller,
            textInputAction: TextInputAction.next,
            onChanged:       (_) => setState(() {}),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
              prefixIcon: Icon(icon,
                  color: AppColors.primaryDark, size: 17),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 13),
            ),
          ),
        ),
        if (showError && errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText,
              style: const TextStyle(
                  color: AppColors.rose,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  // ── Summary card ──────────────────────────────────────────────────

  Widget _summaryCard() {
    final s        = S.of(context);
    final hours    = _totalMinutes ~/ 60;
    final mins     = _totalMinutes % 60;
    final timeText = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final userBal  = widget.user.balance;
    final hasDebt  = userBal < 0;
    final debtAmt  = hasDebt ? userBal.abs() : 0.0;
    final grand    = _grandTotal;

    return Container(
      decoration: AppDecor.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDebt) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.tripCost,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('JOD ${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.rose.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.rose.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.rose, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.outstandingDebt,
                        style: const TextStyle(
                            color: AppColors.rose,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text('JOD ${debtAmt.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.rose,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasDebt ? s.grandTotal : s.total,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('JOD ${grand.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: hasDebt
                                ? AppColors.rose
                                : AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'Approx. $timeText  •  ${widget.seats} seat${widget.seats > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (_route().isNotEmpty)
                StatusBadge(
                  status: _canBook ? 'accepted' : 'rejected',
                  dense:  true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
