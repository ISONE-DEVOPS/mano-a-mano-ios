import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helpers para validação e construção de rotas
/// Usado pelo AppPages para criar views com validação de argumentos
class RouteHelpers {
  
  // =================== BUILDERS COM VALIDAÇÃO ===================

  /// Constrói AddCheckpointsView com validação de argumentos
  static Widget buildAddCheckpointsView() {
    try {
      final args = Get.arguments;
      if (args == null ||
          args is! Map ||
          !args.containsKey('edicaoId') ||
          !args.containsKey('eventId')) {
        return buildErrorPage(
          'Argumentos inválidos para AddCheckpointsView',
          'É necessário fornecer edicaoId e eventId',
          requiredArgs: ['edicaoId', 'eventId'],
        );
      }
      
      // Retorna a view diretamente sem wrapper
      return _buildAddCheckpointsViewDirect();
    } catch (e) {
      return buildErrorPage('Erro ao carregar checkpoints', e.toString());
    }
  }

  /// Constrói RegisterParticipantView com validação opcional de argumentos
  static Widget buildRegisterParticipantView() {
    try {
      // Pode receber userId como String ou Map com parâmetros
      final args = Get.arguments;
      
      return _buildRegisterParticipantViewDirect(args);
    } catch (e) {
      return buildErrorPage('Erro ao carregar registro', e.toString());
    }
  }

  /// Constrói PaymentView com validação de argumentos obrigatórios
  static Widget buildPaymentView() {
    try {
      final args = Get.arguments;
      if (args == null ||
          args is! Map<String, dynamic> ||
          !args.containsKey('eventId') ||
          !args.containsKey('amount')) {
        return buildErrorPage(
          'Dados de pagamento inválidos',
          'É necessário fornecer eventId e amount',
          requiredArgs: ['eventId', 'amount'],
        );
      }
      
      final eventId = args['eventId'] as String;
      final amount = args['amount'] as double;
      
      return _buildPaymentViewDirect(eventId, amount);
    } catch (e) {
      return buildErrorPage('Erro ao carregar pagamento', e.toString());
    }
  }

  /// Constrói RouteMapView com validação de eventId
  static Widget buildRouteMapView() {
    try {
      final eventId = Get.arguments;
      if (eventId == null || eventId is! String) {
        return buildErrorPage(
          'Evento não selecionado',
          'É necessário fornecer um eventId válido',
          requiredArgs: ['eventId'],
        );
      }
      
      return _buildRouteMapViewDirect(eventId);
    } catch (e) {
      return buildErrorPage('Erro ao carregar mapa', e.toString());
    }
  }

  /// Constrói RouteEditorView com validação de eventId
  static Widget buildRouteEditorView() {
    try {
      final eventId = Get.arguments;
      if (eventId == null || eventId is! String) {
        return buildErrorPage(
          'Evento não selecionado',
          'É necessário fornecer um eventId válido',
          requiredArgs: ['eventId'],
        );
      }
      
      return _buildRouteEditorViewDirect(eventId);
    } catch (e) {
      return buildErrorPage('Erro ao carregar editor', e.toString());
    }
  }

  /// Constrói CheckpointsListDialog com validação de argumentos
  static Widget buildCheckpointsListDialog() {
    try {
      final args = Get.arguments;
      if (args == null ||
          args is! Map<String, dynamic> ||
          !args.containsKey('edicaoId') ||
          !args.containsKey('eventId')) {
        return buildErrorPage(
          'Argumentos inválidos para lista de checkpoints',
          'É necessário fornecer edicaoId e eventId',
          requiredArgs: ['edicaoId', 'eventId'],
        );
      }
      
      return _buildCheckpointsListDialogDirect(
        args['edicaoId'] as String,
        args['eventId'] as String,
      );
    } catch (e) {
      return buildErrorPage('Erro ao carregar lista', e.toString());
    }
  }

  // =================== PÁGINA DE ERRO PADRÃO ===================

  /// Constrói uma página de erro padronizada
  static Widget buildErrorPage(
    String title,
    String message, {
    List<String>? requiredArgs,
    VoidCallback? onRetry,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone de erro
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Título
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Mensagem
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Argumentos obrigatórios (se especificados)
              if (requiredArgs != null && requiredArgs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withAlpha(76),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Argumentos obrigatórios:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...requiredArgs.map(
                        (arg) => Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4),
                          child: Text(
                            '• $arg',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Botões de ação
              Column(
                children: [
                  // Botão de retry (se disponível)
                  if (onRetry != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Botão voltar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Tenta voltar, se não conseguir vai para home
                        try {
                          Get.back();
                        } catch (e) {
                          Get.offAllNamed('/home');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Voltar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(Get.context!).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botão home
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Get.offAllNamed('/home'),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Ir para Home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(Get.context!).primaryColor,
                        side: BorderSide(
                          color: Theme.of(Get.context!).primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  // =================== HELPERS PRIVADOS ===================

  /// Builders diretos para evitar dependências circulares
  static Widget _buildAddCheckpointsViewDirect() {
    // Esta função será chamada apenas se os argumentos estiverem válidos
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Checkpoints')),
      body: const Center(
        child: Text('AddCheckpointsView será carregada aqui'),
      ),
    );
  }

  static Widget _buildRegisterParticipantViewDirect(dynamic args) {
    // Lógica para determinar os parâmetros
    String? userId;
    String? editionId;
    String? eventId;

    if (args is String) {
      userId = args;
    } else if (args is Map<String, dynamic>) {
      userId = args['userId'] as String?;
      editionId = args['editionId'] as String?;
      eventId = args['eventId'] as String?;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(userId != null ? 'Editar Participante' : 'Novo Participante'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('RegisterParticipantView será carregada aqui'),
            if (userId != null) Text('Editando usuário: $userId'),
            if (editionId != null) Text('Edição: $editionId'),
            if (eventId != null) Text('Evento: $eventId'),
          ],
        ),
      ),
    );
  }

  static Widget _buildPaymentViewDirect(String eventId, double amount) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PaymentView será carregada aqui'),
            Text('Evento: $eventId'),
            Text('Valor: €${amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  static Widget _buildRouteMapViewDirect(String eventId) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa do Percurso')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('RouteMapView será carregada aqui'),
            Text('Evento: $eventId'),
          ],
        ),
      ),
    );
  }

  static Widget _buildRouteEditorViewDirect(String eventId) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de Percurso')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('RouteEditorView será carregada aqui'),
            Text('Evento: $eventId'),
          ],
        ),
      ),
    );
  }

  static Widget _buildCheckpointsListDialogDirect(String edicaoId, String eventId) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Checkpoints')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CheckpointsListDialog será carregada aqui'),
            Text('Edição: $edicaoId'),
            Text('Evento: $eventId'),
          ],
        ),
      ),
    );
  }

  // =================== VALIDADORES ===================

  /// Valida se os argumentos contêm as chaves obrigatórias
  static bool validateRequiredArgs(
    dynamic args,
    List<String> requiredKeys,
  ) {
    if (args == null || args is! Map) return false;
    
    for (final key in requiredKeys) {
      if (!args.containsKey(key)) return false;
    }
    
    return true;
  }

  /// Extrai argumentos de forma segura
  static T? safeGetArgument<T>(String key, [T? defaultValue]) {
    try {
      final args = Get.arguments;
      if (args is Map && args.containsKey(key)) {
        return args[key] as T;
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Valida se uma string é um ID válido (não vazio)
  static bool isValidId(String? id) {
    return id != null && id.trim().isNotEmpty;
  }
}