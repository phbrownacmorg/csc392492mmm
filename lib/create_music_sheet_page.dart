import 'package:flutter/material.dart';
import 'music_sheet_widget.dart';


class CreateMusicSheetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Music Sheet'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              MusicSheetWidget(),
              SizedBox(height: 20),
              Container(
                color: Colors.grey[300],
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: Center(child: Text('Bottom Banner')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}