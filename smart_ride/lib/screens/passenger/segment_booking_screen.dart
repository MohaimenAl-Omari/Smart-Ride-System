// SegmentBookingScreen — passenger UI for the Ride Segmentation feature.
//
// Flow:
//   1. Load all segments for the trip from /api/trips/{id}/segments.
//   2. Let the passenger choose a "from" stop and a "to" stop using
//      simple dropdowns (only valid forward routes are offered).
//   3. Show the selected route, total price and estimated time.
//   4. Tap "Book this segment" -> POST /api/segments/book.
//
// The screen uses the same AppColors / AppDecor / PrimaryButton
// primitives as the rest of the app so it fits visually.

import 'package:flutter/material.dart';
import '../../core/constant.dart';
import '../../models/user-model.dart';
import '../../models/trip_segment_model.dart';
import '../../controllers/segment_controller.dart';

class SegmentBookingScreen extends StatefulWidget {
  final UserModel user;
  final int tripId;

  const SegmentBookingScreen({
    super.key,
    required this.user,
    required this.tripId,
  });

  @override
  State<SegmentBookingScreen> createState() => _SegmentBookingScreenState();
}

class _SegmentBookingScreenState extends State<SegmentBookingScreen> {
  final SegmentController _ctl = SegmentController();

  bool _loading = true;
  bool _booking = false;

  List<TripSegmentModel> _segments = const [];
  List<String> _orderedStops = const [];

  String? _from;
  String? _to;
  int _seats = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final segs = await _ctl.listSegments(widget.user.token, widget.tripId);
    if (!mounted) return;
    setState(() {
      _segments = segs;
      _orderedStops = _buildOrderedStops(segs);
      _from = _orderedStops.isNotEmpty ? _orderedStops.first : null;
      _to = _orderedStops.length >= 2 ? _orderedStops.last : null;
      _loading = false;
    });
  }

  List<String> _buildOrderedStops(List<TripSegmentModel> segs) {
    if (segs.isEmpty) return const [];
    final sorted = [...segs]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return [
      sorted.first.startStop,
      ...sorted.map((s) => s.endStop),
    ];
  }

  List<TripSegmentModel> _route() {
    if (_from == null || _to == null) return const [];
    final iFrom = _orderedStops.indexOf(_from!);
    final iTo = _orderedStops.indexOf(_to!);
    if (iFrom < 0 || iTo <= iFrom) return const [];
    return _segments
        .where((s) =>
            s.orderIndex >= iFrom && s.orderIndex < iTo)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  double get _totalPrice =>
      _route().fold(0.0, (acc, s) => acc + s.price) * _seats;

  int get _totalMinutes =>
      _route().fold(0, (acc, s) => acc + s.estimatedMinutes);

  bool get _canBook {
    final route = _route();
    if (route.isEmpty) return false;
    return route.every((s) => s.seatsAvailable >= _seats);
  }

  Future<void> _book() async {
    if (!_canBook || _from == null || _to == null) return;
    setState(() => _booking = true);
    final res = await _ctl.book(
      token: widget.user.token,
      tripId: widget.tripId,
      from: _from!,
      to: _to!,
      seats: _seats,
    );
    if (!mounted) return;
    setState(() => _booking = false);
    AppToast.show(context, res.message, error: !res.success);
    if (res.success) {
      // Reload so the UI reflects the new seat counts.
      await _load();
    }
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Book a segment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _segments.isEmpty
              ? const EmptyState(
                  title: 'No segments yet',
                  subtitle:
                      'The driver has not generated segments for this trip yet.',
                  icon: Icons.alt_route_rounded,
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const SectionHeader(
          title: 'Pick your stops',
          subtitle: 'Only forward routes are allowed.',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecor.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStopDropdown(
                label: 'From',
                value: _from,
                items: _orderedStops
                    .take(_orderedStops.length - 1)
                    .toList(),
                onChanged: (v) => setState(() {
                  _from = v;
                  if (_to != null &&
                      _orderedStops.indexOf(_to!) <=
                          _orderedStops.indexOf(v ?? '')) {
                    _to = null;
                  }
                }),
              ),
              const SizedBox(height: 12),
              _buildStopDropdown(
                label: 'To',
                value: _to,
                items: _from == null
                    ? const []
                    : _orderedStops
                        .skip(_orderedStops.indexOf(_from!) + 1)
                        .toList(),
                onChanged: (v) => setState(() => _to = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Seats',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _seatStepper(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader(
          title: 'Selected route',
          subtitle: 'Per-segment seat availability.',
        ),
        _routeCard(),
        const SizedBox(height: 18),
        _summaryCard(),
        const SizedBox(height: 18),
        PrimaryButton(
          label: _canBook
              ? 'Book this segment'
              : 'Choose a valid forward route',
          icon: Icons.check_circle_outline_rounded,
          onTap: _canBook && !_booking ? _book : null,
          loading: _booking,
        ),
      ],
    );
  }

  Widget _buildStopDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: AppDecor.field(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : null,
                isExpanded: true,
                hint: const Text('Select a stop'),
                items: items
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seatStepper() {
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove, _seats > 1 ? () => setState(() => _seats--) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$_seats',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        btn(Icons.add, _seats < 6 ? () => setState(() => _seats++) : null),
      ],
    );
  }

  Widget _routeCard() {
    final route = _route();
    if (route.isEmpty) {
      return const EmptyState(
        title: 'No route selected',
        subtitle: 'Choose a "From" and a later "To" stop.',
        icon: Icons.directions_outlined,
      );
    }
    return Container(
      decoration: AppDecor.card(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final s in route)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s.orderIndex + 1}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${s.startStop}  →  ${s.endStop}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InfoPill(
                    icon: Icons.event_seat_rounded,
                    text: '${s.seatsAvailable}/${s.seatsTotal}',
                    color: s.seatsAvailable >= _seats
                        ? AppColors.primaryDark
                        : AppColors.rose,
                  ),
                  const SizedBox(width: 8),
                  InfoPill(
                    icon: Icons.attach_money_rounded,
                    text: s.price.toStringAsFixed(2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final hours = _totalMinutes ~/ 60;
    final mins = _totalMinutes % 60;
    final timeText =
        hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    return Container(
      decoration: AppDecor.card(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'JOD ${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Approx. $timeText  •  $_seats seat${_seats > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (_route().isNotEmpty)
            StatusBadge(
              status: _canBook ? 'accepted' : 'rejected',
              dense: true,
            ),
        ],
      ),
    );
  }
}
