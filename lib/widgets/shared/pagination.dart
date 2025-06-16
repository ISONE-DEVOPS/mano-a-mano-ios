import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Página ${currentPage + 1} de $totalPages'),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onPrevious,
                  child: const Text('Anterior'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Seguinte'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
