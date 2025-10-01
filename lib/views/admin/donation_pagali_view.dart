import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationShellScreen extends StatefulWidget {
  const DonationShellScreen({super.key});

  @override
  State<DonationShellScreen> createState() => _DonationShellScreenState();
}

class _DonationShellScreenState extends State<DonationShellScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Dados das doações
  bool _isLoading = true;
  String _totalDonations = "0";
  String _totalDonors = "0";
  String _lastUpdateTime = "";
  String? _error;
  String? _campaignName;

  // Cores da Shell
  final Color shellRed = const Color(0xFFE31E24);
  final Color shellYellow = const Color(0xFFFFD320);
  final Color shellOrange = const Color(0xFFFF6900);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDonationData();

    // Atualizar dados a cada 30 segundos
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadDonationData();
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  Future<void> _loadDonationData() async {
    try {
      final result = await _sendSoapRequest();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
          _totalDonations = result['totalDonations'] ?? "0";
          _totalDonors = result['totalDonors'] ?? "0";
          _lastUpdateTime = DateTime.now().toString().substring(11, 19);
          _campaignName =
              result['campaign'] != null &&
                      (result['campaign'] as String).isNotEmpty
                  ? result['campaign']
                  : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Erro ao carregar dados: $e";
        });
      }
    }
  }

  Future<Map<String, dynamic>> _sendSoapRequest() async {
    if (kIsWeb) {
      return {'totalDonations': 'N/D', 'totalDonors': 'N/D', 'campaign': ''};
    }

    final url = Uri.parse(
      'https://www.pagali.cv/pagali/index.php?r=pagaliMobileWS/servico&ws=1',
    );

    const soapEnvelope = '''
  <?xml version="1.0" encoding="UTF-8"?>
  <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
                    xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
                    xmlns:urn="urn:PagaliMobileWSControllerwsdl">
     <soapenv:Header/>
     <soapenv:Body>
        <urn:getStatsDonativosEntidade soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
           <codigo_ent xsi:type="xsd:string">00077</codigo_ent>
        </urn:getStatsDonativosEntidade>
     </soapenv:Body>
  </soapenv:Envelope>
  ''';

    final headers = {
      'Content-Type': 'text/xml; charset=utf-8',
      'SOAPAction': '',
    };

    final response = await http.post(url, headers: headers, body: soapEnvelope);
    debugPrint('📨 SOAP Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonStart = response.body.indexOf('{');
      final jsonEnd = response.body.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonString = response.body.substring(jsonStart, jsonEnd + 1);
        final data = jsonDecode(jsonString);
        debugPrint(
          '📦 JSON formatado:\n${const JsonEncoder.withIndent('  ').convert(data)}',
        );

        if (data['status'] == true &&
            data['response'] is List &&
            data['response'].isNotEmpty) {
          final item = data['response'][0];
          final totalDonations = item['montante']?.toString() ?? '0';
          final totalDonors = item['total']?.toString() ?? '0';
          final campaign = item['campanha']?.toString() ?? '';
          return {
            'totalDonations': totalDonations,
            'totalDonors': totalDonors,
            'campaign': campaign,
          };
        } else {
          throw Exception('Estrutura inesperada no JSON.');
        }
      } else {
        throw Exception('Falha ao extrair JSON da resposta.');
      }
    } else {
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadDonationData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: shellRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Resumo de doações e número de doadores',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildCampaignInfo(),
                  const SizedBox(height: 24),
                  _buildHowToDonate(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                  // if (_rawJson != null) ...[
                  //   const SizedBox(height: 24),
                  //   const Text(
                  //     '📦 Resposta JSON (temporário):',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  //   const SizedBox(height: 8),
                  //   Container(
                  //     padding: const EdgeInsets.all(12),
                  //     decoration: BoxDecoration(
                  //       color: Colors.black12,
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     child: Text(
                  //       _rawJson!,
                  //       style: const TextStyle(
                  //         fontFamily: 'monospace',
                  //         fontSize: 12,
                  //       ),
                  //     ),
                  //   ),
                  // ],
                ],
              ),
            ),
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _loadDonationData,
      //   icon: const Icon(Icons.terminal),
      //   label: const Text('Ver resposta'),
      //   backgroundColor: shellRed,
      // ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: shellRed,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [shellRed, shellOrange],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('🐚', style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _campaignName != null
                      ? 'Shell ao Km - ${_campaignName!}'
                      : 'Shell ao Km',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Doações em tempo real',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).round()),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDonationData,
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            shellYellow.withAlpha((0.1 * 255).round()),
            shellOrange.withAlpha((0.1 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shellYellow.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF86207C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            '💝 Campanha de Solidariedade',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Durante o Rally Paper "Shell ao Km - Mano a Mano", estamos a arrecadar fundos para apoiar a Associação Colmeia e as suas ações sociais na nossa comunidade.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Faça a diferença na vida de uma criança com necessidades especiais, crie uma comunidade inclusiva e melhore a si mesmo!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDonationData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Estatísticas da Campanha',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.payments,
                title: 'Total Arrecadado',
                value: '$_totalDonations CVE',
                subtitle: 'Escudos cabo-verdianos',
                color: shellRed,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.people,
                title: 'Doadores',
                value: _totalDonors,
                subtitle: 'Pessoas generosas',
                color: shellOrange,
              ),
            ),
          ],
        ),
        if (_lastUpdateTime.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '🕒 Última atualização: $_lastUpdateTime',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withAlpha((0.1 * 255).round()),
              color.withAlpha((0.05 * 255).round()),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: shellRed),
                const SizedBox(width: 8),
                Text(
                  '🎯 Sobre a Associação Colmeia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A Associação Colmeia dedica-se a apoiar comunidades carenciadas em Cabo Verde, focando em educação, saúde e desenvolvimento social. A sua missão é criar oportunidades e melhorar a qualidade de vida das famílias mais vulneráveis.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://colmeiaapa.org.cv/')),
              child: Text(
                '🌐 Visitar website da Colmeia',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: shellYellow.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: shellYellow.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cada doação, por mais pequena que seja, faz a diferença na vida de alguém!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToDonate() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_border, color: shellRed),
                const SizedBox(width: 8),
                Text(
                  '💰 Como Doar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDonationStep(
              '1',
              'Acesse o Pagali',
              'Abra a aplicação Pagali no seu telemóvel',
            ),
            _buildDonationStep(
              '2',
              'Procure por Doações',
              'Navegue até à secção de Donativos disponíveis',
            ),
            _buildDonationStep(
              '3',
              'Associação Colmeia',
              'Doar para a Associação Colmeia',
            ),
            _buildDonationStep(
              '4',
              'Escolha o valor ou insere o que pretente e confirme a transação',
              'Fazer a Doação',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF86207C),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            shellRed.withAlpha((0.1 * 255).round()),
            shellOrange.withAlpha((0.1 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐚', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Shell ao Km - Mano a Mano',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: shellRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Juntos, fazemos a diferença! 🤝',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
