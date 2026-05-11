import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constant.dart';
import '../models/trip_model.dart';

class TripController {
  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<TripModel>> search({
    required String token,
    String? from,
    String? to,
    String? date,
  }) async {
    final params = <String, String>{};
    if (from != null && from.isNotEmpty) params['from'] = from;
    if (to != null && to.isNotEmpty) params['to'] = to;
    if (date != null && date.isNotEmpty) params['date'] = date;

    final uri = Uri.parse('$baseUrl/trips/search')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await http.get(uri, headers: _headers(token));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      final list = (data['trips'] as List?) ?? [];
      return list.map((e) => TripModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<TripModel?> show({required String token, required int id}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/trips/$id'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      return TripModel.fromJson(data['trip']);
    }
    return null;
  }

  Future<List<TripModel>> driverTrips(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/driver/trips'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      final list = (data['trips'] as List?) ?? [];
      return list.map((e) => TripModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<TripModel?> create({
    required String token,
    required String origin,
    required String destination,
    required DateTime departureAt,
    required int seatsTotal,
    required double pricePerSeat,
    int minPassengers = 1,
    String? carModel,
    String? carPlate,
    String? notes,
    List<String> stops = const [],
  }) async {
    final body = <String, dynamic>{
      'origin': origin,
      'destination': destination,
      'departure_at': departureAt.toIso8601String(),
      'seats_total': seatsTotal,
      'price_per_seat': pricePerSeat,
      'min_passengers': minPassengers,
      if (carModel != null && carModel.isNotEmpty) 'car_model': carModel,
      if (carPlate != null && carPlate.isNotEmpty) 'car_plate': carPlate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (stops.isNotEmpty) 'stops': stops,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/driver/trips'),
      headers: {..._headers(token), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      return TripModel.fromJson(data['trip']);
    }
    return null;
  }

  Future<bool> cancel(String token, int tripId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/trips/$tripId/cancel'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['status'] == true;
  }

  Future<bool> start(String token, int tripId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/trips/$tripId/start'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    print(data);
    return res.statusCode == 200 && data['status'] == true;
  }


  Future<List<DriverHistoryTrip>> driverHistory(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/driver/trips/history'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      final list = (data['trips'] as List?) ?? [];
      return list.map((e) => DriverHistoryTrip.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> complete(String token, int tripId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/trips/$tripId/complete'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['status'] == true;
  }
}


class DriverHistoryTrip {
  final int id;
  final String origin;
  final String destination;
  final DateTime departureAt;
  final int seatsTotal;
  final double pricePerSeat;
  final String status;
  final int passengersCount; // sum of seats sold
  final double totalEarnings;
  final List<String> stops;

  DriverHistoryTrip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.seatsTotal,
    required this.pricePerSeat,
    required this.status,
    required this.passengersCount,
    required this.totalEarnings,
    this.stops = const [],
  });

  factory DriverHistoryTrip.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List? ?? [];
    return DriverHistoryTrip(
      id: json['id'] ?? 0,
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      departureAt:
          DateTime.tryParse(json['departure_at']?.toString() ?? '') ??
              DateTime.now(),
      seatsTotal: int.tryParse(json['seats_total'].toString()) ?? 0,
      pricePerSeat:
          double.tryParse(json['price_per_seat'].toString()) ?? 0,
      status: json['status'] ?? 'completed',
      passengersCount:
          int.tryParse(json['passengers_count'].toString()) ?? 0,
      totalEarnings:
          double.tryParse(json['total_earnings'].toString()) ?? 0,
      stops: stopsJson
          .map<String>((s) => s is Map<String, dynamic>
              ? (s['name'] ?? '').toString()
              : s.toString())
          .toList(),
    );
  }
}
