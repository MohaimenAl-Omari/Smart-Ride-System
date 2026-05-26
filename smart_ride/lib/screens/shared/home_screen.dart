import 'package:flutter/material.dart';
import '../../models/user-model.dart';
import '../passenger/passenger_home.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) => PassengerHome(user: user);
}
