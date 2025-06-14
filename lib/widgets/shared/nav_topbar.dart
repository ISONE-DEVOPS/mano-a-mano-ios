import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class NavTopBar extends StatelessWidget {
  final String location;
  final String userName;
  final int notifications;
  final String? title;

  const NavTopBar({
    super.key,
    required this.location,
    required this.userName,
    this.notifications = 0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final String dataHoje = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Material(
      elevation: 2,
      shadowColor: AppColors.textSecondary.withAlpha(120),
      child: Container(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sua localização',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        location.isNotEmpty
                            ? location
                            : 'Localização indisponível',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data: $dataHoje',
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                  // Stack(
                  //   children: [
                  //     const Icon(
                  //       Icons.notifications_none,
                  //       size: 28,
                  //       color: Colors.white,
                  //     ),
                  //     if (notifications > 0)
                  //       Positioned(
                  //         right: 0,
                  //         child: CircleAvatar(
                  //           radius: 8,
                  //           backgroundColor: Colors.red,
                  //           child: Text(
                  //             '$notifications',
                  //             style: const TextStyle(
                  //               fontSize: 10,
                  //               color: Colors.white,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //   ],
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
