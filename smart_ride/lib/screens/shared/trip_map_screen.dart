// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../../core/constant.dart';
// import '../../models/trip_model.dart';
// import '../../models/booking_model.dart';
//
// class TripMapScreen extends StatefulWidget {
//   final TripModel trip;
//
//   /// All accepted bookings for this trip (only those with location data
//   /// will show passenger markers).
//   final List<BookingModel> bookings;
//
//   const TripMapScreen({
//     super.key,
//     required this.trip,
//     required this.bookings,
//   });
//
//   @override
//   State<TripMapScreen> createState() => _TripMapScreenState();
// }
//
// class _TripMapScreenState extends State<TripMapScreen> {
//   GoogleMapController? _mapController;
//
//   // ---------------------------------------------------------------
//   // Build markers
//   // ---------------------------------------------------------------
//
//   Set<Marker> _buildMarkers() {
//     final markers = <Marker>{};
//
//     // 1. Origin / driver departure point.
//     //    Most trips don't have stored GPS for the city — we use Jordan
//     //    city coordinates as a fallback lookup map.
//     final originCoords = _jordanCityLatLng(widget.trip.origin);
//     if (originCoords != null) {
//       markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: originCoords,
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueBlue), // 🔵 driver / departure
//         infoWindow: InfoWindow(
//           title: '🚗 Driver starts here',
//           snippet: widget.trip.origin,
//         ),
//       ));
//     }
//
//     // 2. Intermediate stops (grey / azure).
//     for (final (i, stop) in widget.trip.stops.indexed) {
//       final coords = _jordanCityLatLng(stop);
//       if (coords != null) {
//         markers.add(Marker(
//           markerId: MarkerId('stop_$i'),
//           position: coords,
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueViolet), // ⚫ intermediate stop
//           infoWindow: InfoWindow(
//             title: '🛑 Stop',
//             snippet: stop,
//           ),
//         ));
//       }
//     }
//
//     // 3. Destination (red).
//     final destCoords = _jordanCityLatLng(widget.trip.destination);
//     if (destCoords != null) {
//       markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: destCoords,
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueRed), // 🔴 destination
//         infoWindow: InfoWindow(
//           title: '🏁 Destination',
//           snippet: widget.trip.destination,
//         ),
//       ));
//     }
//
//     // 4. Passenger pickup locations (teal / green).
//     //    Only shown when the booking has GPS coordinates set (F2 feature).
//     for (final (i, booking) in widget.bookings.indexed) {
//       if (booking.pickupLat != null && booking.pickupLng != null) {
//         markers.add(Marker(
//           markerId: MarkerId('passenger_$i'),
//           position: LatLng(booking.pickupLat!, booking.pickupLng!),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueCyan), // 🟢 passenger pickup
//           infoWindow: InfoWindow(
//             title: '🧍 ${booking.passengerName ?? 'Passenger'}',
//             snippet: booking.pickupAddress ?? 'Pickup point',
//           ),
//         ));
//       }
//     }
//
//     return markers;
//   }
//
//   // ---------------------------------------------------------------
//   // Camera
//   // ---------------------------------------------------------------
//
//   /// Fits all markers in the viewport when the map is ready.
//   void _fitMarkers() {
//     final markers = _buildMarkers();
//     if (markers.isEmpty || _mapController == null) return;
//
//     double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
//     for (final m in markers) {
//       final l = m.position;
//       if (l.latitude < minLat) minLat = l.latitude;
//       if (l.latitude > maxLat) maxLat = l.latitude;
//       if (l.longitude < minLng) minLng = l.longitude;
//       if (l.longitude > maxLng) maxLng = l.longitude;
//     }
//
//     _mapController!.animateCamera(
//       CameraUpdate.newLatLngBounds(
//         LatLngBounds(
//           southwest: LatLng(minLat - 0.05, minLng - 0.05),
//           northeast: LatLng(maxLat + 0.05, maxLng + 0.05),
//         ),
//         72, // padding in pixels
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------
//   // Build
//   // ---------------------------------------------------------------
//
//   @override
//   Widget build(BuildContext context) {
//     final passengerCount =
//         widget.bookings.where((b) => b.pickupLat != null).length;
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: Stack(
//         children: [
//           // Full-screen map
//           GoogleMap(
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(31.9539, 35.9106), // Amman default
//               zoom: 8,
//             ),
//             onMapCreated: (ctrl) {
//               _mapController = ctrl;
//               // Delay slightly so map tiles are ready
//               Future.delayed(const Duration(milliseconds: 400), _fitMarkers);
//             },
//             markers: _buildMarkers(),
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: true,
//           ),
//
//           // Top overlay: back button + title
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       width: 42,
//                       height: 42,
//                       decoration: BoxDecoration(
//                         color: AppColors.surface,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: AppShadows.card(),
//                       ),
//                       child: const Icon(Icons.arrow_back_ios_new_rounded,
//                           color: AppColors.textPrimary, size: 16),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 10),
//                       decoration: BoxDecoration(
//                         color: AppColors.surface,
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: AppShadows.card(),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             '${widget.trip.origin}  →  ${widget.trip.destination}',
//                             style: const TextStyle(
//                               color: AppColors.textPrimary,
//                               fontSize: 13.5,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                           Text(
//                             '$passengerCount passenger marker${passengerCount != 1 ? 's' : ''}',
//                             style: const TextStyle(
//                               color: AppColors.textSecondary,
//                               fontSize: 11.5,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Legend panel (bottom)
//           Positioned(
//             bottom: 16,
//             left: 16,
//             child: SafeArea(
//               top: false,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 14, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: AppColors.surface,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: AppShadows.floating(),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _legendItem(Icons.circle, AppColors.sky, 'Driver / Origin'),
//                     const SizedBox(height: 6),
//                     _legendItem(
//                         Icons.circle, AppColors.primary, 'Passenger Pickup'),
//                     const SizedBox(height: 6),
//                     _legendItem(Icons.circle, const Color(0xFF7C3AED),
//                         'Intermediate Stop'),
//                     const SizedBox(height: 6),
//                     _legendItem(Icons.circle, AppColors.rose, 'Destination'),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _legendItem(IconData icon, Color color, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: color, size: 12),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: const TextStyle(
//               color: AppColors.textSecondary,
//               fontSize: 11.5,
//               fontWeight: FontWeight.w600),
//         ),
//       ],
//     );
//   }
//
//   // ---------------------------------------------------------------
//   // Helper: rough GPS coordinates for common Jordanian cities
//   // (used when bookings don't carry exact GPS — presentation purposes)
//   // ---------------------------------------------------------------
//
//   static final Map<String, LatLng> _cityMap = {
//     'Amman':   const LatLng(31.9539, 35.9106),
//     'Irbid':   const LatLng(32.5556, 35.8500),
//     'Zarqa':   const LatLng(32.0728, 36.0878),
//     'Aqaba':   const LatLng(29.5321, 35.0063),
//     'Jarash':  const LatLng(32.2742, 35.8962),
//     'Jerash':  const LatLng(32.2742, 35.8962),
//     'Mafraq':  const LatLng(32.3432, 36.2087),
//     'Karak':   const LatLng(31.1803, 35.7045),
//     'Madaba':  const LatLng(31.7161, 35.7938),
//     'Ajloun':  const LatLng(32.3329, 35.7517),
//     'Salt':    const LatLng(32.0381, 35.7277),
//     'Balqa':   const LatLng(32.0381, 35.7277),
//     'Tafilah': const LatLng(30.8376, 35.6072),
//     'Maan':    const LatLng(30.1928, 35.7321),
//   };
//
//   LatLng? _jordanCityLatLng(String city) {
//     // Case-insensitive lookup
//     final normalised = city.trim();
//     return _cityMap[normalised] ??
//         _cityMap.entries
//             .firstWhere(
//               (e) => e.key.toLowerCase() == normalised.toLowerCase(),
//               orElse: () => const MapEntry('', LatLng(0, 0)),
//             )
//             .value
//             .let((ll) => ll.latitude == 0 && ll.longitude == 0 ? null : ll);
//   }
// }
//
// // Extension for the null-safe let() pattern used above
// extension _Let<T> on T {
//   R let<R>(R Function(T) block) => block(this);
// }
