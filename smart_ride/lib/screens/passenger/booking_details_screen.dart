import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../models/user-model.dart';
import '../../models/booking_model.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/support_controller.dart';

class BookingDetailsScreen extends StatefulWidget {
  final UserModel user;
  final BookingModel booking;
  const BookingDetailsScreen(
      {super.key, required this.user, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingController _bookingCtl = BookingController();
  final RatingController _ratingCtl = RatingController();
  late BookingModel b;

  final TextEditingController _reviewCtl = TextEditingController();

  bool _busy = false;
  bool _checkedIn = false;
  int _rating = 0;
  bool _ratingSent = false;
  bool _submittingRating = false;

  @override
  void dispose() {
    _reviewCtl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    b = widget.booking;
    _checkedIn = b.isCheckedIn || b.status == 'checked_in';
  }

  Future<void> _checkIn() async {
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    final res = await _bookingCtl.checkIn(widget.user.token, b.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res.success) _checkedIn = true;
    });
    AppToast.show(context, res.message, error: !res.success);
  }

  Future<void> _cancel() async {
    final ok = await _bookingCtl.cancel(widget.user.token, b.id);
    if (!mounted) return;
    AppToast.show(context, ok ? 'Booking cancelled · refund queued' : 'Failed',
        error: !ok);
    if (ok) Navigator.pop(context);
  }

  Future<void> _submitRating() async {
    if (_rating == 0) return;
    final s = S.of(context);
    HapticFeedback.lightImpact();
    setState(() => _submittingRating = true);
    final res = await _ratingCtl.rate(
      token: widget.user.token,
      bookingId: b.id,
      stars: _rating,
      review: _reviewCtl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submittingRating = false);
    if (res.success) {
      setState(() => _ratingSent = true);
      AppToast.show(context, s.ratingThanks(_rating));
    } else {
      AppToast.show(context, res.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = b.tripDepartureAt;
    final timeStr = dt == null
        ? '—'
        : '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final canCheckIn = !_checkedIn &&
        b.status == 'accepted' &&
        dt != null &&
        now.isAfter(dt.subtract(const Duration(minutes: 60))) &&
        now.isBefore(dt.add(const Duration(minutes: 30)));

    final canCancel = b.status == 'pending' || b.status == 'accepted';
    final canRate = b.status == 'completed' && !_ratingSent;

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
                      _summaryHero(timeStr),
                      const SizedBox(height: 12),
                      _segmentCard(),
                      if (b.driverName != null) ...[
                        const SizedBox(height: 12),
                        _driverCard(),
                      ],
                      const SizedBox(height: 12),
                      _paymentCard(),
                      const SizedBox(height: 16),
                      if (canCheckIn) ...[
                        PrimaryButton(
                          label: 'Check in for this trip',
                          icon: Icons.qr_code_rounded,
                          height: 54,
                          loading: _busy,
                          onTap: _checkIn,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_checkedIn)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.emerald.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.emerald),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You\'re checked in. Hold tight — the trip starts once the driver confirms minimum passengers.',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (canCancel) ...[
                        const SizedBox(height: 10),
                        SecondaryButton(
                          label: 'Cancel booking',
                          icon: Icons.close_rounded,
                          color: AppColors.rose,
                          onTap: _cancel,
                        ),
                      ],
                      if (canRate) ...[
                        const SizedBox(height: 18),
                        _ratingCard(),
                      ],
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
          Text(S.of(context).bookingDetailsTitle,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          StatusBadge(status: _checkedIn ? 'checked_in' : b.status),
        ],
      ),
    );
  }

  Widget _summaryHero(String timeStr) {
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
              const Icon(Icons.directions_car_filled_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text('Booking #${b.id}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${b.tripOrigin ?? '—'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.south_rounded, color: Colors.white, size: 18),
          ),
          Text('${b.tripDestination ?? '—'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
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
              Text('${b.seats} seats',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Your segment',
            subtitle: 'Where you board and get off',
          ),
          Row(
            children: [
              Expanded(
                child: _stopBox(
                    'Pickup', b.pickupStop ?? b.tripOrigin ?? '—', true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stopBox('Drop-off',
                    b.dropoffStop ?? b.tripDestination ?? '—', false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stopBox(String label, String value, bool start) {
    final color = start ? AppColors.primary : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _driverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Row(
        children: [
          InitialAvatar(name: b.driverName ?? 'Driver', size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.driverName ?? 'Driver',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    [b.carModel, b.carPlate]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.emeraldSoft,
              border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
            ),
            child: const Icon(Icons.phone_rounded,
                color: AppColors.emerald, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Payment',
            subtitle: 'Held in escrow until trip completes',
          ),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryDark),
              const SizedBox(width: 8),
              const Text('Total',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              Text('${b.totalPrice.toStringAsFixed(2)} JD',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.skySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: Color(0xFF0369A1), size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Funds release to the driver only after trip completion. Refunds are automatic on cancellation or no-show.',
                    style: TextStyle(
                        color: Color(0xFF0369A1),
                        fontSize: 11.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard() {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: s.rateYourDriver,
            subtitle: s.rateYourDriverSub,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 38,
                    color: filled ? AppColors.amber : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppDecor.field(),
            child: TextField(
              controller: _reviewCtl,
              maxLines: 3,
              maxLength: 1000,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: s.reviewOptional,
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: s.submitRating,
            icon: Icons.send_rounded,
            height: 48,
            loading: _submittingRating,
            onTap: _rating == 0 || _submittingRating ? null : _submitRating,
          ),
        ],
      ),
    );
  }
}
