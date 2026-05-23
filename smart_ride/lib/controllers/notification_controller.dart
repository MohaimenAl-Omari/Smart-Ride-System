import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/constant.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  final String token;
  NotificationController({required this.token});
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool loading = false.obs;

  Timer? _pollingTimer;


  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchNotifications(),
    );
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchNotifications() async {
    loading.value = true;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['notifications'] as List?) ?? [];
        notifications.value = list
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        unreadCount.value =
            int.tryParse((data['unread_count'] ?? 0).toString()) ?? 0;
      }
    } catch (_) {
      // Fail silently — UI shows empty state.
    } finally {
      loading.value = false;
    }
  }

  Future<void> markAllRead() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      for (final n in notifications) {
        n.isRead = true;
      }
      notifications.refresh();
      unreadCount.value = 0;
    } catch (_) {}
  }

  Future<void> markRead(int id) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !notifications[idx].isRead) {
        notifications[idx].isRead = true;
        notifications.refresh();
        if (unreadCount.value > 0) unreadCount.value--;
      }
    } catch (_) {}
  }

  Future<void> deleteNotification(int id) async {
    final was = notifications.firstWhereOrNull((n) => n.id == id);
    notifications.removeWhere((n) => n.id == id);
    if (was != null && !was.isRead && unreadCount.value > 0) {
      unreadCount.value--;
    }
    try {
      await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {}
  }

  void refresh() => fetchNotifications();
}
