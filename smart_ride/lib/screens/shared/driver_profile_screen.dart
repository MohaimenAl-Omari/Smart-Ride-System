// DriverProfileScreen — F4: Driver Rating Visibility
//
// Shows the driver's profile (name, city, car), average star rating,
// total review count, and the last 60 individual passenger reviews.
//
// Navigation: tapping a driver's name in TripDetailsScreen pushes this.
// Data source: GET /api/drivers/{id}/ratings

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/constant.dart';
import '../../models/user-model.dart';
import '../../models/driver_rating_model.dart';
import '../../controllers/rating_controller.dart';

class DriverProfileScreen extends StatefulWidget {
  /// The ID of the driver whose profile we are viewing.
  final int driverId;

  /// Name of the driver — shown immediately while data loads.
  final String driverName;

  /// The current user's bearer token for the API call.
  final UserModel viewer;

  const DriverProfileScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.viewer,
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final RatingController _ctl = RatingController();
  DriverRatingResponse? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _ctl.fetchDriverRatings(
      token: widget.viewer.token,
      driverId: widget.driverId,
    );
    if (!mounted) return;
    setState(() {
      _data = result;
      _loading = false;
    });
  }

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
                _appBar(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _data == null
                          ? _errorState()
                          : _buildContent(_data!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------

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
          const Text(
            'Driver Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------

  Widget _buildContent(DriverRatingResponse data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // Hero card: avatar + name + aggregate rating
        _heroCard(data),
        const SizedBox(height: 18),
        // Rating breakdown bar
        _ratingBreakdown(data),
        const SizedBox(height: 18),
        // Reviews list header
        SectionHeader(
          title: 'Passenger Reviews',
          subtitle: '${data.count} review${data.count != 1 ? 's' : ''}',
        ),
        if (data.reviews.isEmpty)
          EmptyState(
            icon: Icons.rate_review_rounded,
            title: 'No reviews yet',
            subtitle: '${widget.driverName} hasn\'t received any ratings yet.',
          )
        else
          ...data.reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _reviewCard(r),
              )),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Hero card
  // ---------------------------------------------------------------

  Widget _heroCard(DriverRatingResponse data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecor.card(),
      child: Column(
        children: [
          // Large avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: AppShadows.primary(),
            ),
            child: Center(
              child: Text(
                widget.driverName.isEmpty
                    ? '?'
                    : widget.driverName.trim()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Driver name
          Text(
            widget.driverName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Driver',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),

          // Average rating stars
          if (data.count > 0) ...[
            RatingBarIndicator(
              rating: data.average,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star_rounded, color: AppColors.amber),
              itemCount: 5,
              itemSize: 28,
            ),
            const SizedBox(height: 8),
            Text(
              '${data.average.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Based on ${data.count} review${data.count != 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ] else ...[
            // No ratings yet placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (_) => const Icon(Icons.star_outline_rounded,
                    color: AppColors.textMuted, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No ratings yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Rating breakdown (star distribution bars)
  // ---------------------------------------------------------------

  Widget _ratingBreakdown(DriverRatingResponse data) {
    if (data.count == 0) return const SizedBox.shrink();

    // Count reviews per star level (1–5).
    final counts = List.filled(5, 0);
    for (final r in data.reviews) {
      final i = (r.stars - 1).clamp(0, 4);
      counts[i]++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Rating Breakdown',
            subtitle: 'Distribution by star level',
          ),
          for (int star = 5; star >= 1; star--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '$star',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded,
                      color: AppColors.amber, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: data.count > 0
                            ? counts[star - 1] / data.count
                            : 0.0,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${counts[star - 1]}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  // ---------------------------------------------------------------
  // Individual review card
  // ---------------------------------------------------------------

  Widget _reviewCard(DriverReviewModel r) {
    final dateStr = r.createdAt != null
        ? '${r.createdAt!.day}/${r.createdAt!.month}/${r.createdAt!.year}'
        : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(
                name: r.passengerName ?? 'Passenger',
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.passengerName ?? 'Anonymous',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Star pills
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color:
                        i < r.stars ? AppColors.amber : AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (r.review != null && r.review!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.review!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------

  Widget _errorState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load profile',
        subtitle: 'Check your connection and try again.',
      ),
    );
  }
}
