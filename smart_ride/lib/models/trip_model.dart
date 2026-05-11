class TripModel {
  final int id;
  final int driverId;
  final String origin;
  final String destination;
  final DateTime departureAt;
  final int seatsTotal;
  final int seatsAvailable;
  final int minPassengers;
  final double pricePerSeat;
  final String? carModel;
  final String? carPlate;
  final String? notes;
  final String status;
  final String? driverName;
  final String? driverPhone;
  final List<String> stops;
  final List<dynamic> bookings;

  TripModel({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.minPassengers,
    required this.pricePerSeat,
    required this.status,
    this.carModel,
    this.carPlate,
    this.notes,
    this.driverName,
    this.driverPhone,
    this.stops = const [],
    this.bookings = const [],
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final stopsJson = json['stops'] as List? ?? [];
    final bookingsJson = json['bookings'] as List? ?? [];

    final origin = (json['origin'] ?? '').toString();
    final destination = (json['destination'] ?? '').toString();

    // The backend's trip_stops table stores origin + intermediates +
    // destination (see TripController@store). For UI consumers we only
    // want the intermediate stops here — origin/destination are already
    // first-class fields. We also de-duplicate to be defensive against
    // any double-seeding and to keep DropdownButton happy (Flutter's
    // DropdownButton asserts that its current value matches exactly one
    // item, so a duplicate stop would crash the screen).
    final allStops = stopsJson
        .map<String>((s) => (s is Map<String, dynamic>)
            ? (s['name'] ?? '').toString()
            : s.toString())
        .where((s) => s.isNotEmpty)
        .toList();

    final intermediateStops = <String>[];
    for (final s in allStops) {
      if (s == origin || s == destination) continue;
      if (intermediateStops.contains(s)) continue;
      intermediateStops.add(s);
    }

    return TripModel(
      id: json['id'],
      driverId: json['driver_id'] ?? driver?['id'] ?? 0,
      origin: origin,
      destination: destination,
      departureAt: DateTime.tryParse(json['departure_at'] ?? '') ??
          DateTime.now(),
      seatsTotal: int.tryParse(json['seats_total'].toString()) ?? 0,
      seatsAvailable: int.tryParse(json['seats_available'].toString()) ?? 0,
      minPassengers: int.tryParse((json['min_passengers'] ?? 1).toString()) ?? 1,
      pricePerSeat:
          double.tryParse(json['price_per_seat'].toString()) ?? 0.0,
      carModel: json['car_model'],
      carPlate: json['car_plate'],
      notes: json['notes'],
      status: json['status'] ?? 'scheduled',
      driverName: driver?['name'],
      driverPhone: driver?['phone'],
      stops: intermediateStops,
      bookings: bookingsJson,
    );
  }
}
