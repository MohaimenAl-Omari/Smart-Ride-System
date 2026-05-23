class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id:        int.tryParse(json['id'].toString()) ?? 0,
      userId:    int.tryParse((json['user_id'] ?? 0).toString()) ?? 0,
      title:     (json['title'] ?? '').toString(),
      body:      (json['body'] ?? '').toString(),
      type:      (json['type'] ?? '').toString(),
      isRead:    json['is_read'] == true || json['is_read'] == 1,
      data:      json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                 DateTime.now(),
    );
  }

  NotifStyle get style {
    switch (type) {
      case 'booking_created':
      case 'booking_accepted':
        return const NotifStyle(0xe22a, 0xFF10B981); // check_circle / emerald
      case 'booking_rejected':
      case 'booking_cancelled':
        return const NotifStyle(0xe232, 0xFFEF4444); // cancel / rose
      case 'trip_started':
        return const NotifStyle(0xe1d4, 0xFF0EA5A4); // directions_car / teal
      case 'trip_cancelled':
        return const NotifStyle(0xe232, 0xFFEF4444);
      case 'trip_completed':
        return const NotifStyle(0xe22a, 0xFF0EA5E9); // check / sky
      case 'driver_rated':
        return const NotifStyle(0xe5d2, 0xFFF59E0B); // star / amber
      default:
        return const NotifStyle(0xe7f4, 0xFF94A3B8); // notifications / muted
    }
  }
}

class NotifStyle {
  final int iconCodePoint;
  final int colorValue;
  const NotifStyle(this.iconCodePoint, this.colorValue);
}
