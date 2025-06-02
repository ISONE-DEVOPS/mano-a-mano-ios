/// Modelo de dados para representar um desafio em cada ponto de picagem.
/// Inclui tipo de atividade, descrição, tempo estimado e pontuação.
class Challenge {
  final String id;
  final String title;
  final String description;
  final String location;
  final int estimatedMinutes;
  final int maxPoints;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.estimatedMinutes,
    required this.maxPoints,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      estimatedMinutes: json['estimatedMinutes'],
      maxPoints: json['maxPoints'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'estimatedMinutes': estimatedMinutes,
      'maxPoints': maxPoints,
    };
  }
}
