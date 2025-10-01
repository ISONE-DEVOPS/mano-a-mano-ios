import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      shadowColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.47),
      child: Container(
        color: Theme.of(context).colorScheme.primary,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sua localização',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.70),
                          ),
                        ),
                        Text(
                          location.isNotEmpty
                              ? location
                              : 'Localização indisponível',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data: $dataHoje',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
