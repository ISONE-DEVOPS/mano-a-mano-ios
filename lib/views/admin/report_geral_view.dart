import 'package:flutter/material.dart';
import 'tshirt_report_view.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios Gerais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text(
                'Participação por Checkpoint',
                style: TextStyle(color: Colors.black),
              ),
              subtitle: const Text(
                'Total de check-ins realizados em cada ponto',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // lógica futura para abrir este relatório
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text(
                'Pontuação Média por Equipa',
                style: TextStyle(color: Colors.black),
              ),
              subtitle: const Text(
                'Média de pontos obtidos em perguntas e jogos',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // lógica futura
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text(
                'Respostas Certas por Checkpoint',
                style: TextStyle(color: Colors.black),
              ),
              subtitle: const Text(
                'Análise de desempenho nas perguntas por posto',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // lógica futura
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text(
                'Ranking Final',
                style: TextStyle(color: Colors.black),
              ),
              subtitle: const Text(
                'Ordem de classificação das equipas no evento',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // lógica futura
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text(
                'Pontuação por Utilizador',
                style: TextStyle(color: Colors.black),
              ),
              subtitle: const Text(
                'Visualização da pontuação total em cada checkpoint',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
              ),
              onTap: () {
                // lógica futura para navegação
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text(
                'Participação por Equipa e Tamanhos de T-shirts',
                style: TextStyle(color: Colors.black),
              ),
              subtitle: const Text(
                'Distribuição dos tamanhos por equipa',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TshirtReportView()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
