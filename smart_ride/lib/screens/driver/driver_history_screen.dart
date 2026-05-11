import 'package:flutter/material.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../controllers/trip_controller.dart';
import '../../models/user-model.dart';

/// Driver-only "Previous trips" view. Shows completed/cancelled trips
/// with passenger count, total earnings, route, date and status.
class DriverHistoryScreen extends StatefulWidget {
  final UserModel user;
  const DriverHistoryScreen({super.key, required this.user});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final TripController _ctl = TripController();
  bool _loading = true;
  List<DriverHistoryTrip> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _ctl.driverHistory(widget.user.token);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  double get _totalEarnings =>
      _items.fold<double>(0, (sum, t) => sum + t.totalEarnings);

  int get _totalPassengers =>
      _items.fold<int>(0, (sum, t) => sum + t.passengersCount);

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
                              _summary(s),
                              const SizedBox(height: 14),
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
                              for (final t in _items) _card(t, s),
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

  Widget _summary(S s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.primary(),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stat(
              icon: Icons.directions_car_filled_rounded,
              value: _items.length.toString(),
              label: s.previousTrips,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _stat(
              icon: Icons.groups_rounded,
              value: _totalPassengers.toString(),
              label: s.passengersWord,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _stat(
              icon: Icons.payments_rounded,
              value: '${_totalEarnings.toStringAsFixed(0)} ${s.currency}',
              label: s.earningsWord,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
      {required IconData icon,
      required String value,
      required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _card(DriverHistoryTrip t, S s) {
    final dt = t.departureAt;
    final timeStr =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Container(
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              ),
              StatusBadge(status: t.status),
            ],
          ),
          if (t.stops.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: t.stops
                  .map((stop) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(stop,
                            style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              InfoPill(icon: Icons.schedule_rounded, text: timeStr),
              const SizedBox(width: 12),
              InfoPill(
                icon: Icons.person_rounded,
                text: '${t.passengersCount} ${s.passengersWord}',
              ),
              const Spacer(),
              Text('${t.totalEarnings.toStringAsFixed(2)} ${s.currency}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
