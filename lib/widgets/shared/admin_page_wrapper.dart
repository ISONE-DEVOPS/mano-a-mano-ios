import 'package:flutter/material.dart';
import 'copyright_widget.dart';

class AdminPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminPageWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(child: child),
          const SizedBox(height: 20),
          const CopyrightWidget(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
