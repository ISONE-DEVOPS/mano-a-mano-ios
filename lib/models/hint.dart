

/// Modelo que representa uma pista (hint) entregue à equipa.
/// Cada pista contém o texto e o destino relacionado com o próximo ponto.
class Hint {
  final String id;
  final String clueText;
  final String nextCheckpoint;

  Hint({
    required this.id,
    required this.clueText,
    required this.nextCheckpoint,
  });

  factory Hint.fromJson(Map<String, dynamic> json) {
    return Hint(
      id: json['id'],
      clueText: json['clueText'],
      nextCheckpoint: json['nextCheckpoint'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clueText': clueText,
      'nextCheckpoint': nextCheckpoint,
    };
  }
}