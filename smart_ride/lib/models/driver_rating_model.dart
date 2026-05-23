class DriverReviewModel {
  final int id;
  final int stars;
  final String? review;
  final String? passengerName;
  final String? passengerImage;
  final DateTime? createdAt;

  const DriverReviewModel({
    required this.id,
    required this.stars,
    this.review,
    this.passengerName,
    this.passengerImage,
    this.createdAt,
  });

  factory DriverReviewModel.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'] as Map<String, dynamic>?;
    return DriverReviewModel(
      id:            int.tryParse(json['id'].toString()) ?? 0,
      stars:         int.tryParse((json['stars'] ?? 0).toString()) ?? 0,
      review:        json['review']?.toString(),
      passengerName: passenger?['name']?.toString(),
      passengerImage: passenger?['image_url']?.toString(),
      createdAt:     DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
class DriverRatingResponse {
  final double average;
  final int count;
  final List<DriverReviewModel> reviews;

  const DriverRatingResponse({
    required this.average,
    required this.count,
    required this.reviews,
  });

  factory DriverRatingResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['ratings'] as List?) ?? [];
    return DriverRatingResponse(
      average: double.tryParse((json['rating_average'] ?? 0).toString()) ?? 0,
      count:   int.tryParse((json['ratings_count'] ?? 0).toString()) ?? 0,
      reviews: list
          .map((e) => DriverReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
