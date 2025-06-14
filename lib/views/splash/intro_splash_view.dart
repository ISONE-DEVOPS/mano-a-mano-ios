import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_colors.dart';

class IntroSplashView extends StatefulWidget {
  const IntroSplashView({super.key});

  @override
  State<IntroSplashView> createState() => _IntroSplashViewState();
}

class _IntroSplashViewState extends State<IntroSplashView> {
  final controller = PageController(viewportFraction: 1.0);
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => onLastPage = index == 2),
            children: const [
              _Slide(
                imagePath: 'assets/images/qr.jpg',
                title: 'Check-in QR',
                description:
                    'Faça scan dos códigos QR em cada posto para registar a sua passagem.',
                color: AppColors.primary,
              ),
              _Slide(
                imagePath: 'assets/images/pontuacao.jpg',
                title: 'Pontuação',
                description:
                    'Ganhe 10 pontos por cada resposta correta e pontos extras em mini-jogos.',
                color: AppColors.secondaryDark,
              ),
              _Slide(
                imagePath: 'assets/images/ranking.png',
                title: 'Ranking',
                description:
                    'Acompanhe a sua posição em tempo real e compita com outras equipas.',
                color: AppColors.primary,
              ),
            ],
          ),
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: controller,
                count: 3,
                effect: const WormEffect(
                  activeDotColor: AppColors.primary,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: onLastPage ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  offset: onLastPage ? Offset.zero : const Offset(0, 1),
                  child: ElevatedButton(
                    onPressed: () => Get.offAllNamed('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Começar Aventura'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final Color color;

  const _Slide({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
