import 'package:flutter/material.dart';
import 'copyright_widget.dart';

class AdminPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions; // 👈 Adicionado
  final bool showFooter;

  const AdminPageWrapper({
    super.key,
    required this.title,
    required this.child,
    this.actions, // 👈 Adicionado
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title),
        actions: actions, // 👈 Adicionado aqui
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(child: child),
          if (showFooter) ...[
            const SizedBox(height: 20),
            const CopyrightWidget(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
