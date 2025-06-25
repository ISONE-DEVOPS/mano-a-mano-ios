import 'package:flutter/material.dart';

/// Widget de Copyright para o sistema Mano a Mano
/// Vivo Energy Cabo Verde - Shell ao KM
class CopyrightWidget extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final EdgeInsets padding;

  const CopyrightWidget({
    super.key,
    this.backgroundColor = const Color(0xFFDC2626), // Vermelho Shell
    this.textColor = Colors.white,
    this.accentColor = const Color(0xFFFFD700), // Dourado Shell
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: accentColor, width: 3.0)),
      ),
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '© $currentYear Vivo Energy Cabo Verde. Todos os direitos reservados. Mano a Mano v2.0',
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Desenvolvido por CLOUD TECHNOLOGY - PAGALI',
            style: TextStyle(
              color: textColor.withAlpha(230),
              fontSize: fontSize - 1,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Shell ao KM - Rally Paper | 2ª Edição',
            style: TextStyle(
              color: accentColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Scaffold com copyright automático
class CopyrightScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool includeCopyright;

  const CopyrightScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.includeCopyright = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          Expanded(child: body),
          if (includeCopyright) const CopyrightWidget(),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Wrapper para páginas admin
class AdminPageWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const AdminPageWrapper({
    super.key,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CopyrightScaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        actions: actions,
      ),
      body: child,
    );
  }
}

/// Wrapper para páginas do app mobile
class AppPageWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const AppPageWrapper({
    super.key,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CopyrightScaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        actions: actions,
      ),
      body: child,
    );
  }
}

/// Wrapper para páginas do staff
class StaffPageWrapper extends StatelessWidget {
  final Widget child;
  final String title;

  const StaffPageWrapper({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    return CopyrightScaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        leading: const Icon(Icons.admin_panel_settings),
      ),
      body: child,
    );
  }
}
