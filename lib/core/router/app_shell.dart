import '../theme/app_theme.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AuthController _auth;
  bool _showingSessionError = false;

  @override
  void initState() {
    super.initState();
    _auth = ref.read(authControllerProvider);
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    final message = _auth.sessionErrorMessage;
    if (!mounted ||
        !_auth.isAuthenticated ||
        message == null ||
        _showingSessionError) {
      return;
    }
    _showingSessionError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Não foi possível concluir o acesso'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (_auth.sessionErrorMessage == message) _auth.clearError();
      _showingSessionError = false;
      _onAuthChanged();
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Fornecedores',
        style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: MediaQuery.sizeOf(context).width / 5);
    final tabHeight = (labelPainter.height + 36).clamp(50.0, double.infinity);
    labelPainter.dispose();
    final tabBar = CupertinoTabBar(
      height: tabHeight,
      currentIndex: widget.navigationShell.currentIndex,
      inactiveColor: AppTheme.secondaryTextColor.resolveFrom(context),
      onTap: (index) {
        HapticFeedback.selectionClick();
        widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        );
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.doc_text),
          label: 'Extrato',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.cube_box),
          activeIcon: Icon(CupertinoIcons.cube_box_fill),
          label: 'Produtos',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person_2),
          activeIcon: Icon(CupertinoIcons.person_2_fill),
          label: 'Fornecedores',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.ellipsis_circle),
          activeIcon: Icon(CupertinoIcons.ellipsis_circle_fill),
          label: 'Mais',
        ),
      ],
    );
    // O GoRouter mantém um Navigator por aba. O padding permite rolar atrás
    // da barra translúcida sem esconder o último item.
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.paddingOf(
                  context,
                ).copyWith(bottom: bottomInset + tabBar.preferredSize.height),
              ),
              child: widget.navigationShell,
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: tabBar),
        ],
      ),
    );
  }
}
