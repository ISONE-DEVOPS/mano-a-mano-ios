/// Modelo de dados para representar uma atividade final de team building.
class FinalActivity {
  /// Identificador único da atividade.
  final String id;

  /// Título da atividade.
  final String title;

  /// Descrição detalhada da atividade.
  final String description;

  /// Duração da atividade em minutos.
  final int durationMinutes;

  /// Pontuação máxima possível para a atividade.
  final int maxScore;

  FinalActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.maxScore,
  });

  factory FinalActivity.fromJson(Map<String, dynamic> json) {
    return FinalActivity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      durationMinutes: json['durationMinutes'],
      maxScore: json['maxScore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'maxScore': maxScore,
    };
  }
}
