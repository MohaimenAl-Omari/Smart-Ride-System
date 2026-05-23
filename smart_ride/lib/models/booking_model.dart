class BookingModel {
  final int id;
  final int tripId;
  final int passengerId;
  final String? pickupStop;
  final String? dropoffStop;
  final int seats;
  final double totalPrice;

  /// Amount of prior no-show debt included in [totalPrice].
  final double debtCarried;

  final String status;

  /// true once the passenger has checked in.
  final bool isCheckedIn;

  /// true when trip completed and the passenger never checked in.
  final bool noShow;

  final String? passengerName;
  final String? passengerPhone;

  // Passenger pickup location — three structured fields
  final String? locationArea;
  final String? locationStreet;
  final String? locationBuilding;

  /// Payment method chosen by the passenger: 'cash', 'card', 'wallet', or null.
  final String? paymentMethod;

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
    this.debtCarried = 0.0,
    this.isCheckedIn = false,
    this.noShow = false,
    this.pickupStop,
    this.dropoffStop,
    this.passengerName,
    this.passengerPhone,
    this.locationArea,
    this.locationStreet,
    this.locationBuilding,
    this.paymentMethod,
    this.tripOrigin,
    this.tripDestination,
    this.tripDepartureAt,
    this.driverName,
    this.carModel,
    this.carPlate,
  });

  /// A human-readable address string built from the three location fields.
  /// Returns null if none of the fields were filled.
  String? get locationSummary {
    final parts = <String>[];
    if (locationBuilding?.isNotEmpty == true) parts.add('Bldg ${locationBuilding!}');
    if (locationStreet?.isNotEmpty == true)   parts.add(locationStreet!);
    if (locationArea?.isNotEmpty == true)     parts.add(locationArea!);
    return parts.isEmpty ? null : parts.join(', ');
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'] as Map<String, dynamic>?;
    final trip      = json['trip']      as Map<String, dynamic>?;
    final driver    = trip?['driver']   as Map<String, dynamic>?;

    return BookingModel(
      id:          json['id'],
      tripId:      json['trip_id']      ?? 0,
      passengerId: json['passenger_id'] ?? 0,
      pickupStop:  json['pickup_stop'],
      dropoffStop: json['dropoff_stop'],
      seats:       int.tryParse(json['seats'].toString()) ?? 1,
      totalPrice:  double.tryParse(json['total_price'].toString()) ?? 0.0,
      debtCarried: _toDouble(json['debt_carried']) ?? 0.0,
      status:      json['status'] ?? 'pending',
      isCheckedIn: json['is_checked_in'] == true || json['is_checked_in'] == 1,
      noShow:      json['no_show']       == true || json['no_show']       == 1,
      passengerName:  passenger?['name'],
      passengerPhone: passenger?['phone'],
      locationArea:     json['location_area']?.toString(),
      locationStreet:   json['location_street']?.toString(),
      locationBuilding: json['location_building']?.toString(),
      paymentMethod:    json['payment_method']?.toString(),
      tripOrigin:      trip?['origin'],
      tripDestination: trip?['destination'],
      tripDepartureAt: trip?['departure_at'] != null
          ? DateTime.tryParse(trip!['departure_at'].toString())
          : null,
      driverName: driver?['name'],
      carModel:   trip?['car_model'],
      carPlate:   trip?['car_plate'],
    );
  }

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());
}
