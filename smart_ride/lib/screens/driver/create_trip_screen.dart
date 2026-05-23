import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';
import '../../controllers/trip_controller.dart';

class CreateTripScreen extends StatefulWidget {
  final UserModel user;
  const CreateTripScreen({super.key, required this.user});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _origin      = TextEditingController();
  final _destination = TextEditingController();
  final _seats       = TextEditingController(text: '4');
  final _minPass     = TextEditingController(text: '1');
  final _carModel    = TextEditingController();
  final _carPlate    = TextEditingController();
  final _notes       = TextEditingController();
  final _newStop     = TextEditingController();

  final List<String> _stops = [];

  final List<TextEditingController> _segPriceCtls = [];

  DateTime? _departure;
  bool _saving = false;

  final TripController _tripCtl = TripController();

  @override
  void initState() {
    super.initState();
    _rebuildSegmentControllers();
  }

  @override
  void dispose() {
    for (final c in [
      _origin, _destination, _seats, _minPass,
      _carModel, _carPlate, _notes, _newStop, ..._segPriceCtls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    final v = _newStop.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _stops.add(v);
      _newStop.clear();
      _rebuildSegmentControllers();
    });
  }

  void _removeStop(int idx) {
    setState(() {
      _stops.removeAt(idx);
      _rebuildSegmentControllers();
    });
  }

  void _rebuildSegmentControllers() {
    final oldValues = _segPriceCtls.map((c) => c.text).toList();
    for (final c in _segPriceCtls) c.dispose();
    _segPriceCtls.clear();

    final segCount = _stops.length + 1; // legs = points - 1
    for (int i = 0; i < segCount; i++) {
      _segPriceCtls.add(
        TextEditingController(text: i < oldValues.length ? oldValues[i] : ''),
      );
    }
  }

  List<String> get _orderedPoints =>
      [_origin.text.trim(), ..._stops, _destination.text.trim()];

  Future<void> _pickDeparture() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _departure =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }


  Future<void> _save() async {
    final s      = S.of(context);
    final origin = _origin.text.trim();
    final dest   = _destination.text.trim();

    if (origin.isEmpty || dest.isEmpty || _departure == null) {
      AppToast.show(context, s.tripFormError, error: true);
      return;
    }

    final seats = int.tryParse(_seats.text.trim()) ?? 0;
    if (seats <= 0) {
      AppToast.show(context, s.seatsPriceError, error: true);
      return;
    }

    // Ensure segment controllers are in sync
    if (_segPriceCtls.length != _stops.length + 1) {
      _rebuildSegmentControllers();
    }

    // ── Cumulative price validation ───────────────────────────────
    // The driver enters prices as cumulative totals from origin:
    //   Field 0: origin → stop1  (e.g. A→B = 3 JD)
    //   Field 1: origin → stop2  (e.g. A→C = 6 JD)
    // Per-segment prices are derived as diffs: seg[i] = cum[i] - cum[i-1]
    // so a full-trip passenger pays 6 JD and a partial passenger pays 3 JD.
    final points = _orderedPoints;
    final cumulativePrices = <double>[];
    for (int i = 0; i < _segPriceCtls.length; i++) {
      final v = double.tryParse(_segPriceCtls[i].text.trim());
      final label = i < points.length - 1
          ? '${points[0]} → ${points[i + 1]}'
          : 'segment ${i + 1}';
      if (v == null || v <= 0) {
        AppToast.show(
          context,
          s.segPriceGtZero(label),
          error: true,
        );
        return;
      }
      // Each cumulative price must be strictly greater than the previous
      if (i > 0 && v <= cumulativePrices[i - 1]) {
        final prevLabel = '${points[0]} → ${points[i]}';
        AppToast.show(
          context,
          s.segPriceMustBeHigher(
            label,
            prevLabel,
            cumulativePrices[i - 1].toStringAsFixed(2),
          ),
          error: true,
        );
        return;
      }
      cumulativePrices.add(v);
    }

    // Derive per-segment prices (what gets stored in trip_segments.price)
    final segmentPrices = <double>[];
    for (int i = 0; i < cumulativePrices.length; i++) {
      segmentPrices.add(
        i == 0 ? cumulativePrices[0] : cumulativePrices[i] - cumulativePrices[i - 1],
      );
    }

    // Full-trip cost = last cumulative price
    final totalTripPrice = cumulativePrices.last;

    HapticFeedback.lightImpact();
    setState(() => _saving = true);

    final created = await _tripCtl.create(
      token:         widget.user.token,
      origin:        origin,
      destination:   dest,
      departureAt:   _departure!,
      seatsTotal:    seats,
      pricePerSeat:  totalTripPrice,
      minPassengers: int.tryParse(_minPass.text.trim()) ?? 1,
      carModel:      _carModel.text.trim(),
      carPlate:      _carPlate.text.trim(),
      notes:         _notes.text.trim(),
      stops:         _stops,
      segmentPrices: segmentPrices,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (created != null) {
      AppToast.show(context, s.tripPublished);
      Navigator.pop(context, true);
    } else {
      AppToast.show(context, s.failedCreateTrip, error: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final s  = S.of(context);
    final dt = _departure;
    final timeStr = dt == null
        ? s.pickDateTime
        : '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _appBar(s),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: [
                      // ── Route ──────────────────────────────────────
                      _section(s.route, subtitle: s.routeSub, children: [
                        _field(_origin, s.origin, Icons.my_location_rounded),
                        const SizedBox(height: 12),
                        _field(_destination, s.destination,
                            Icons.place_outlined),
                      ]),
                      const SizedBox(height: 14),

                      // ── Intermediate stops ─────────────────────────
                      _section(s.stopsAlongTheWay,
                          subtitle: s.stopsSub,
                          children: [
                        Row(children: [
                          Expanded(
                            child: _field(_newStop, s.stopName,
                                Icons.add_location_alt_rounded),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _addStop,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: AppDecor.gradient(),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white),
                            ),
                          ),
                        ]),
                        if (_stops.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _stops
                                .asMap()
                                .entries
                                .map((e) => _stopChip(e.key, e.value))
                                .toList(),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 14),

                      // ── Segment prices ─────────────────────────────
                      // Always shown (origin→destination is always present).
                      if (_origin.text.trim().isNotEmpty &&
                          _destination.text.trim().isNotEmpty)
                        _segmentPriceSection(),

                      const SizedBox(height: 14),

                      // ── Departure ──────────────────────────────────
                      _section(s.departure, children: [
                        GestureDetector(
                          onTap: _pickDeparture,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AppDecor.field(),
                            child: Row(children: [
                              const Icon(Icons.event_rounded,
                                  color: AppColors.primaryDark, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: dt == null
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textMuted),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // ── Seats ──────────────────────────────────────
                      // "Price per seat" removed — prices are per segment only.
                      _section(
                        s.seatsAndPrice,
                        subtitle: s.seatsAndPriceSub,
                        children: [
                          Row(children: [
                            Expanded(
                              child: _field(
                                _seats,
                                s.totalSeats,
                                Icons.event_seat_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _field(
                                _minPass,
                                s.minSeats,
                                Icons.groups_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Vehicle ────────────────────────────────────
                      _section(s.vehicle, subtitle: s.vehicleSub, children: [
                        _field(_carModel, s.carModel,
                            Icons.directions_car_filled_rounded),
                        const SizedBox(height: 12),
                        _field(_carPlate, s.plateNumber,
                            Icons.confirmation_number_rounded),
                      ]),
                      const SizedBox(height: 14),

                      // ── Notes ──────────────────────────────────────
                      _section(s.notes, subtitle: s.notesSub, children: [
                        _field(_notes, s.notesHint, Icons.notes_rounded,
                            maxLines: 3),
                      ]),
                      const SizedBox(height: 22),

                      PrimaryButton(
                        label: s.publishTrip,
                        icon: Icons.send_rounded,
                        loading: _saving,
                        height: 54,
                        onTap: _saving ? null : _save,
                      ),
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

  Widget _segmentPriceSection() {
    final points = _orderedPoints;
    if (points.length < 2) return const SizedBox.shrink();

    if (_segPriceCtls.length != points.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_rebuildSegmentControllers);
      });
    }

    return _section(
      'Segment Prices',
      subtitle:
          'Enter the price from the start to each stop. '
          'Example: A→B = 3 JD, A→C = 6 JD means the full trip costs 6 JD '
          'and a passenger riding only A→B pays 3 JD.',
      children: [
        for (int i = 0; i < points.length - 1 && i < _segPriceCtls.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _segmentPriceRow(
            // Always show "origin → stopN" (cumulative, not per-leg)
            from: points[0],
            to:   points[i + 1],
            ctl:  _segPriceCtls[i],
            hint: i == 0
                ? 'Price for this leg'
                : 'Total from start (> ${_segPriceCtls[i-1].text.isEmpty ? "prev" : "${_segPriceCtls[i-1].text} JD"})',
          ),
        ],
      ],
    );
  }

  Widget _segmentPriceRow({
    required String from,
    required String to,
    required TextEditingController ctl,
    String hint = '0.00',
  }) {
    return Container(
      decoration: AppDecor.field(),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.route_rounded,
              color: AppColors.primaryDark, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${from.isEmpty ? 'Origin' : from}  →  ${to.isEmpty ? 'Dest' : to}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hint,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: TextField(
              controller: ctl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}), // refresh hints
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 13),
                suffixText: 'JD',
                suffixStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------

  Widget _appBar(S s) {
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
          Text(
            s.newTripTitle,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _section(String title,
      {String? subtitle, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Container(
      decoration: AppDecor.field(),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}), // repaint segment section labels
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: maxLines > 1
              ? null
              : Icon(icon, size: 18, color: AppColors.primaryDark),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _stopChip(int idx, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded,
              size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeStop(idx),
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
