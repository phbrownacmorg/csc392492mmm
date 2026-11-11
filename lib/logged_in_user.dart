import 'package:flutter/material.dart';
import 'package:music_app/services/auth_service.dart';

class LoggedInUser extends StatelessWidget {
  final Color textColor;

  const LoggedInUser({
    super.key,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService().getUserData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final firstName = data?['firstName'] ?? '';
        final lastName = data?['lastName'] ?? '';
        final fullName = '$firstName $lastName'.trim();

        return Text(
          fullName.isEmpty
              ? 'Loading user...'
              : fullName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}