import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome Admin"),
            ElevatedButton(
              onPressed: () {
                print("Admin action: delete users / manage sheets");
              },
              child: Text("Manage System"),
            ),
          ],
        ),
      ),
    );
  }
}