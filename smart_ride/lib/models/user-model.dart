class UserModel {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? city;
  final String? image;       // raw path stored on the server
  final String? imageUrl;    // public URL the API computes for us
  final double ratingAverage;
  final int ratingsCount;
  final bool isActive;
  final String token;

  /// Account balance. Positive = credit, negative = outstanding no-show debt.
  final double balance;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.token,
    this.city,
    this.image,
    this.imageUrl,
    this.ratingAverage = 0,
    this.ratingsCount = 0,
    this.isActive = true,
    this.balance = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'passenger',
      city: json['city'],
      image: json['image'],
      imageUrl: json['image_url'],
      ratingAverage: _toDouble(json['rating_average']),
      ratingsCount: _toInt(json['ratings_count']),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] == 1 || json['is_active'] == '1'),
      token: token,
      balance: _toDouble(json['balance']),
    );
  }

  /// Used by the SessionService to persist a logged-in user locally.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'city': city,
        'image': image,
        'image_url': imageUrl,
        'rating_average': ratingAverage,
        'ratings_count': ratingsCount,
        'is_active': isActive,
        'token': token,
        'balance': balance,
      };

  /// Used by the SessionService when restoring a saved session.
  factory UserModel.fromStored(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'passenger',
      city: json['city'],
      image: json['image'],
      imageUrl: json['image_url'],
      ratingAverage: _toDouble(json['rating_average']),
      ratingsCount: _toInt(json['ratings_count']),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] == 1 ||
              json['is_active'] == '1' ||
              json['is_active'] == true),
      token: (json['token'] ?? '').toString(),
      balance: _toDouble(json['balance']),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    String? image,
    String? imageUrl,
    double? ratingAverage,
    int? ratingsCount,
    bool? isActive,
    String? token,
    double? balance,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      city: city ?? this.city,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      isActive: isActive ?? this.isActive,
      token: token ?? this.token,
      balance: balance ?? this.balance,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
