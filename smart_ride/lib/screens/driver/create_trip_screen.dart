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
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _seats = TextEditingController(text: '4');
  final _minPassengers = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _carModel = TextEditingController();
  final _carPlate = TextEditingController();
  final _notes = TextEditingController();
  final _newStop = TextEditingController();

  final List<String> _stops = [];
  DateTime? _departure;
  bool _saving = false;

  final TripController _tripCtl = TripController();

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _seats.dispose();
    _minPassengers.dispose();
    _price.dispose();
    _carModel.dispose();
    _carPlate.dispose();
    _notes.dispose();
    _newStop.dispose();
    super.dispose();
  }

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
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
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
    if (time == null) return;
    setState(() {
      _departure =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addStop() {
    final v = _newStop.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _stops.add(v);
      _newStop.clear();
    });
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (_origin.text.trim().isEmpty ||
        _destination.text.trim().isEmpty ||
        _seats.text.trim().isEmpty ||
        _price.text.trim().isEmpty ||
        _departure == null) {
      AppToast.show(context, s.tripFormError, error: true);
      return;
    }
    final seats = int.tryParse(_seats.text.trim()) ?? 0;
    final minPassengers = int.tryParse(_minPassengers.text.trim()) ?? 1;
    final price = double.tryParse(_price.text.trim()) ?? -1;
    if (seats <= 0 || price < 0) {
      AppToast.show(context, s.seatsPriceError, error: true);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    final created = await _tripCtl.create(
      token: widget.user.token,
      origin: _origin.text.trim(),
      destination: _destination.text.trim(),
      departureAt: _departure!,
      seatsTotal: seats,
      pricePerSeat: price,
      minPassengers: minPassengers,
      carModel: _carModel.text.trim(),
      carPlate: _carPlate.text.trim(),
      notes: _notes.text.trim(),
      stops: _stops,
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
    final s = S.of(context);
    final dt = _departure;
    final timeStr = dt == null
        ? s.pickDateTime
        : '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _appBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: [
                      _section(s.route,
                          subtitle: s.routeSub,
                          children: [
                            _field(_origin, s.origin,
                                Icons.my_location_rounded),
                            const SizedBox(height: 12),
                            _field(_destination, s.destination,
                                Icons.place_outlined),
                          ]),
                      const SizedBox(height: 14),
                      _section(s.stopsAlongTheWay,
                          subtitle: s.stopsSub,
                          children: [
                            Row(
                              children: [
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
                              ],
                            ),
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
                      _section(s.departure, children: [
                        GestureDetector(
                          onTap: _pickDeparture,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AppDecor.field(),
                            child: Row(
                              children: [
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
                                      fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _section(s.seatsAndPrice,
                          subtitle: s.seatsAndPriceSub,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _field(_seats, s.totalSeats,
                                        Icons.event_seat_rounded,
                                        keyboardType: TextInputType.number)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _field(_minPassengers, s.minSeats,
                                        Icons.groups_rounded,
                                        keyboardType: TextInputType.number)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _field(_price, s.pricePerSeat,
                                Icons.payments_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true)),
                          ]),
                      const SizedBox(height: 14),
                      _section(s.vehicle,
                          subtitle: s.vehicleSub,
                          children: [
                            _field(_carModel, s.carModel,
                                Icons.directions_car_filled_rounded),
                            const SizedBox(height: 12),
                            _field(_carPlate, s.plateNumber,
                                Icons.confirmation_number_rounded),
                          ]),
                      const SizedBox(height: 14),
                      _section(s.notes,
                          subtitle: s.notesSub,
                          children: [
                            _field(_notes, s.notesHint,
                                Icons.notes_rounded,
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
          Text(S.of(context).newTripTitle,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
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
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
            onTap: () => setState(() => _stops.removeAt(idx)),
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
