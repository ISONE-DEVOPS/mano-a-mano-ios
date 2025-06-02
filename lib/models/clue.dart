/// Modelo para representar uma pista ("Concha") entregue à equipa.
/// A pista é usada para orientar o próximo ponto de picagem.
class Clue {
  final String id;
  final String clueText;
  final String destination;

  Clue({required this.id, required this.clueText, required this.destination});

  factory Clue.fromJson(Map<String, dynamic> json) {
    return Clue(
      id: json['id'],
      clueText: json['clueText'],
      destination: json['destination'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'clueText': clueText, 'destination': destination};
  }
}
