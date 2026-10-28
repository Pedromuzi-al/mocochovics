import '../widgets/app_interaction.dart';

import '../widgets/app_navigation_menu.dart';
import '../widgets/floating_navigation.dart';
import '../widgets/appearance_controls.dart';
import '../theme/design_tokens.dart';

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
  bool _collapsed = false;
  bool _menuOpen = false;
  bool _compactNavigation = false;

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
            AppHover(
              child: CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
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

  void _select(int index) {
    final reselecting = index == widget.navigationShell.currentIndex;
    if (index == 0 || reselecting) {
      widget.navigationShell.route.branches[index].navigatorKey.currentState
          ?.popUntil((route) => route.isFirst);
    }
    setState(() => _compactNavigation = false);
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == 0 || reselecting,
    );
  }

  Future<void> _openMenu() async {
    if (_menuOpen) return;
    _menuOpen = true;
    final width = MediaQuery.sizeOf(context).width;
    final menuWidth = (width - 40).clamp(0.0, 328.0);
    try {
      await Navigator.of(context, rootNavigator: true).push<void>(
        RawDialogRoute<void>(
          traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
          barrierDismissible: true,
          barrierLabel: 'Fechar menu',
          barrierColor: CupertinoColors.black.withValues(alpha: .4),
          transitionDuration: AppMotion.duration(context, AppMotion.reveal),
          requestFocus: true,
          pageBuilder: (menuContext, animation, secondaryAnimation) =>
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      Navigator.of(menuContext).pop(),
                },
                child: FocusScope(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: menuWidth,
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if ((details.primaryVelocity ?? 0) < -200) {
                            Navigator.of(menuContext).pop();
                          }
                        },
                        child: AppNavigationMenu(
                          currentIndex: widget.navigationShell.currentIndex,
                          email: _auth.email,
                          onToggle: () => Navigator.of(menuContext).pop(),
                          onSelect: (index) {
                            Navigator.of(menuContext).pop();
                            _select(index);
                          },
                          drawer: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          transitionBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position: Tween(begin: const Offset(-1, 0), end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: AppMotion.curve,
                      ),
                    ),
                child: child,
              ),
        ),
      );
    } finally {
      _menuOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= AppLayout.sidebarBreakpoint;
      if (wide) {
        final menuWidth = _collapsed
            ? 80.0
            : AppLayout.sidebarWidth +
                  (MediaQuery.textScalerOf(context).scale(15) / 15 - 1).clamp(
                        0.0,
                        1.0,
                      ) *
                      104;
        return CupertinoPageScaffold(
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.reveal),
                curve: AppMotion.curve,
                width: menuWidth,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: menuWidth,
                    maxWidth: menuWidth,
                    child: AppNavigationMenu(
                      currentIndex: widget.navigationShell.currentIndex,
                      email: _auth.email,
                      collapsed: _collapsed,
                      onToggle: () => setState(() => _collapsed = !_collapsed),
                      onSelect: _select,
                    ),
                  ),
                ),
              ),
              Expanded(child: widget.navigationShell),
            ],
          ),
        );
      }
      return CupertinoPageScaffold(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator
                        .resolveFrom(context)
                        .withValues(alpha: .25),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      AppButton(
                        onPressed: _openMenu,
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          CupertinoIcons.line_horizontal_3,
                          semanticLabel: 'Abrir menu',
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bar do Mocochovisk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const AppearanceButton(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: MediaQuery.paddingOf(context).copyWith(top: 0),
                ),
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (notification) {
                    if (notification.depth != 0 ||
                        notification.dragDetails == null ||
                        MediaQuery.accessibleNavigationOf(context) ||
                        MediaQuery.disableAnimationsOf(context)) {
                      return false;
                    }
                    final delta = notification.scrollDelta ?? 0;
                    final compact =
                        delta > 4 && notification.metrics.pixels > 80
                        ? true
                        : delta < -4
                        ? false
                        : _compactNavigation;
                    if (compact != _compactNavigation) {
                      setState(() => _compactNavigation = compact);
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                                ? 0
                                : MediaQuery.textScalerOf(context).scale(11) >
                                      16
                                ? 118
                                : 100,
                          ),
                          child: widget.navigationShell,
                        ),
                      ),
                      if (MediaQuery.viewInsetsOf(context).bottom == 0)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 12,
                          child: SafeArea(
                            top: false,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: FloatingNavigation(
                                  currentIndex:
                                      widget.navigationShell.currentIndex,
                                  onSelect: _select,
                                  compact: _compactNavigation,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
