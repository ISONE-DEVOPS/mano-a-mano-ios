

import 'package:get/get.dart';

/// Controller responsável pela lógica das atividades finais (Team Building, Jogos Finais, etc).
class FinalActivitiesController extends GetxController {
  /// Lista de atividades finais programadas
  final activities = <String>[
    'Corrida Mais Louca',
    'Põe o Combustível em Segurança',
    'Oleoduto',
    'Pista de Sabão',
    'Transporta a Botija em Segurança',
    'Quatro em Linha',
    'Tiro ao Alvo (Arco e Flecha)',
    'Cabo de Guerra',
  ].obs;

  /// Atividade atualmente selecionada
  final selectedActivity = ''.obs;

  void selectActivity(String activity) {
    selectedActivity.value = activity;
  }

  /// Reset para nova ronda ou evento
  void reset() {
    selectedActivity.value = '';
  }
}