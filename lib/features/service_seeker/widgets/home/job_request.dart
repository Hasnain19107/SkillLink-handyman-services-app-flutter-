import 'package:flutter/material.dart';

class JobRequestButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      child: Text('Post a Job Request', style: TextStyle(color: Colors.white)),
    );
  }
}
