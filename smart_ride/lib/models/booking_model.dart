class BookingModel {
  final int id;
  final int tripId;
  final int passengerId;
  final String? pickupStop;
  final String? dropoffStop;
  final int seats;
  final double totalPrice;
  final String status;

  /// F7 — populated by the backend once the passenger calls /checkin.
  /// `null` means the passenger has not checked in yet.
  final DateTime? checkedInAt;

  /// F7 — flagged true on trip completion when an accepted booking never
  /// checked in. Used by the UI to show a "no-show" badge in history.
  final bool noShow;

  final String? passengerName;
  final String? passengerPhone;

  final String? tripOrigin;
  final String? tripDestination;
  final DateTime? tripDepartureAt;
  final String? driverName;
  final String? carModel;
  final String? carPlate;

  BookingModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.seats,
    required this.totalPrice,
    required this.status,
    this.checkedInAt,
    this.noShow = false,
    this.pickupStop,
    this.dropoffStop,
    this.passengerName,
    this.passengerPhone,
    this.tripOrigin,
    this.tripDestination,
    this.tripDepartureAt,
    this.driverName,
    this.carModel,
    this.carPlate,
  });

  bool get isCheckedIn => checkedInAt != null;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'] as Map<String, dynamic>?;
    final trip = json['trip'] as Map<String, dynamic>?;
    final driver = trip?['driver'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id'],
      tripId: json['trip_id'] ?? 0,
      passengerId: json['passenger_id'] ?? 0,
      pickupStop: json['pickup_stop'],
      dropoffStop: json['dropoff_stop'],
      seats: int.tryParse(json['seats'].toString()) ?? 1,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'].toString())
          : null,
      noShow: json['no_show'] == true || json['no_show'] == 1,
      passengerName: passenger?['name'],
      passengerPhone: passenger?['phone'],
      tripOrigin: trip?['origin'],
      tripDestination: trip?['destination'],
      tripDepartureAt: trip?['departure_at'] != null
          ? DateTime.tryParse(trip!['departure_at'].toString())
          : null,
      driverName: driver?['name'],
      carModel: trip?['car_model'],
      carPlate: trip?['car_plate'],
    );
  }
}
