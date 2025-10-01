// lib/models/event_config.dart
import 'package:flutter/material.dart';

enum CheckinMode { single, entryExit }

class RegistrationTier {
  final String code; // "VXE" | "RAI"
  final int? limit; // null = sem limite
  final int fee; // valor de inscrição

  RegistrationTier({
    required this.code,
    required this.limit,
    required this.fee,
  });

  factory RegistrationTier.fromMap(Map<String, dynamic> m) => RegistrationTier(
    code: m['code'] as String,
    limit: m['limit'] == null ? null : (m['limit'] as num).toInt(),
    fee: (m['fee'] as num).toInt(),
  );

  Map<String, dynamic> toMap() => {'code': code, 'limit': limit, 'fee': fee};
}

class EventConfig {
  final String eventId;
  final String editionId;
  final String name;
  final DateTime? date;
  final bool isActive;
  final String brand; // "shell" | "mano"
  final String? logoUrl;

  final CheckinMode checkinMode; // single vs entry_exit
  final bool hasQuestions;
  final bool hasGames;
  final bool hasScoring;

  final List<RegistrationTier> registrationTiers;

  // tema dinâmico
  final Color primaryColor;
  final Color onPrimaryColor;
  final Brightness brightness;

  const EventConfig({
    required this.eventId,
    required this.editionId,
    required this.name,
    required this.date,
    required this.isActive,
    required this.brand,
    required this.logoUrl,
    required this.checkinMode,
    required this.hasQuestions,
    required this.hasGames,
    required this.hasScoring,
    required this.registrationTiers,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.brightness,
  });

  factory EventConfig.fromMap(String eventId, Map<String, dynamic> m) {
    final modeStr = (m['checkinMode'] as String? ?? 'entry_exit').toLowerCase();
    final mode =
        modeStr == 'single' ? CheckinMode.single : CheckinMode.entryExit;

    final tiers =
        ((m['registrationTiers'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RegistrationTier.fromMap)
            .toList();

    // fallback de cores (Shell mantém; Mano a Mano = preto/laranja) [oai_citation:4‡Shell Colour downloadable swatch.pdf](file-service://file-DEU8jswbMoKcxabHMqhja8)
    final brand = (m['brand'] as String? ?? 'shell').toLowerCase();
    final isMano = brand == 'mano';

    final Color primary =
        isMano ? const Color(0xFFFF6600) : const Color(0xFFFFC600);
    final Color onPrimary =
        isMano ? const Color(0xFF000000) : const Color(0xFFDD1D21);
    final Brightness brightness = isMano ? Brightness.dark : Brightness.light;

    return EventConfig(
      eventId: eventId,
      editionId: m['editionId'] as String? ?? '',
      name: m['name'] as String? ?? 'Evento',
      date: (m['date'] != null) ? DateTime.tryParse(m['date'] as String) : null,
      isActive: (m['isActive'] as bool?) ?? false,
      brand: brand,
      logoUrl: m['logoUrl'] as String?,
      checkinMode: mode,
      hasQuestions: (m['hasQuestions'] as bool?) ?? true,
      hasGames: (m['hasGames'] as bool?) ?? true,
      hasScoring: (m['hasScoring'] as bool?) ?? true,
      registrationTiers: tiers,
      primaryColor: primary,
      onPrimaryColor: onPrimary,
      brightness: brightness,
    );
  }

  bool get isShell => brand == 'shell';
  bool get isMano => brand == 'mano';
}
