import 'package:flutter/material.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../controllers/booking_controller.dart';
import '../../models/booking_model.dart';
import '../../models/user-model.dart';
import 'booking_details_screen.dart';

class PassengerHistoryScreen extends StatefulWidget {
  final UserModel user;
  const PassengerHistoryScreen({super.key, required this.user});

  @override
  State<PassengerHistoryScreen> createState() =>
      _PassengerHistoryScreenState();
}

class _PassengerHistoryScreenState extends State<PassengerHistoryScreen> {
  final BookingController _ctl = BookingController();
  bool _loading = true;
  List<BookingModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _ctl.myBookings(widget.user.token);
    if (!mounted) return;
    setState(() {
      _items = all
          .where((b) =>
              b.status == 'completed' ||
              b.status == 'cancelled' ||
              b.status == 'rejected' ||
              b.status == 'refunded')
          .toList();
      _loading = false;
    });
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
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                        : ListView(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 28),
                            children: [
                              SectionHeader(
                                title: s.previousTrips,
                                subtitle: s.previousTripsSub,
                              ),
                              if (_items.isEmpty)
                                EmptyState(
                                  icon: Icons.history_rounded,
                                  title: s.noHistory,
                                  subtitle: s.noHistoryBody,
                                ),
                              for (final b in _items) _card(b, s),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          Text(s.tripHistory,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _card(BookingModel b, S s) {
    final dt = b.tripDepartureAt;
    final timeStr = dt == null
        ? '—'
        : '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  BookingDetailsScreen(user: widget.user, booking: b)),
        );
        _load();
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
                StatusBadge(status: b.noShow ? 'no_show' : b.status),
              ],
            ),
            const SizedBox(height: 8),
            if (b.driverName != null)
              Row(
                children: [
                  const Icon(Icons.person_rounded,
                      color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Text('${s.driverNameLabel}: ${b.driverName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                InfoPill(icon: Icons.schedule_rounded, text: timeStr),
                const Spacer(),
                Text('${b.totalPrice.toStringAsFixed(2)} ${s.currency}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
