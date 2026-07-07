import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/usecases/watch_gravity.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({required this.watchGravity, super.key});

  final WatchGravity watchGravity;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  late final TitleScreenGame _game = TitleScreenGame(
    watchGravity: widget.watchGravity,
    container: ProviderScope.containerOf(context),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget<TitleScreenGame>(
            game: _game,
            overlayBuilderMap: <String, Widget Function(BuildContext, TitleScreenGame)>{
              TitleScreenGame.settingsOverlayKey:
                  (BuildContext context, TitleScreenGame game) =>
                      _SettingsCogButton(game: game),
              TitleScreenGame.gameEndOverlayKey:
                  (BuildContext context, TitleScreenGame game) =>
                      _GameEndOverlay(game: game),
            },
          ),
          if (kDebugMode) _DevControls(game: _game),
        ],
      ),
    );
  }
}

/// Debug-build-only controls for iterating on the title screen's background
/// animation. Stripped from release builds via [kDebugMode].
class _DevControls extends StatelessWidget {
  const _DevControls({required this.game});

  final TitleScreenGame game;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _DevButton(
                icon: Icons.refresh,
                tooltip: 'Reload animation',
                onPressed: game.reloadBackground,
              ),
              const SizedBox(width: 8),
              _DevButton(
                icon: Icons.shuffle,
                tooltip: 'Switch animation',
                onPressed: game.switchBackground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  const _DevButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Settings cog shown in the top-right corner once the board is on screen
/// (see [TitleScreenGame.settingsOverlayKey]). Opens the in-game menu.
class _SettingsCogButton extends StatelessWidget {
  const _SettingsCogButton({required this.game});

  final TitleScreenGame game;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Tooltip(
            message: 'Menu',
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                onPressed: () => _showMenuDialog(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenuDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _ThemedDialog(
        title: 'Menu',
        buttons: <Widget>[
          _DialogButton(
            label: 'Stop playing',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showQuitConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showQuitConfirmationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _ThemedDialog(
        title: 'Are you sure you want to quit this game?',
        buttons: <Widget>[
          _DialogButton(
            label: 'Yes',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              game.returnToTitle();
            },
          ),
          const SizedBox(width: 12),
          _DialogButton(
            label: 'No',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }
}

/// Shown once a round ends (see [TitleScreenGame.gameEndOverlayKey]): the
/// winning mark drawn large on a teal block, the result, and a "Play again"
/// link — styled after a dark-chrome card with a colored insert.
class _GameEndOverlay extends StatelessWidget {
  const _GameEndOverlay({required this.game});

  final TitleScreenGame game;

  @override
  Widget build(BuildContext context) {
    final GameStatus? status = game.lastGameStatus;
    final Player? winner = switch (status) {
      GameStatus.xWon => Player.x,
      GameStatus.oWon => Player.o,
      GameStatus.draw || GameStatus.inProgress || null => null,
    };
    final String resultText = switch (status) {
      GameStatus.xWon => 'X WON!',
      GameStatus.oWon => 'O WON!',
      GameStatus.draw => 'DRAW!',
      GameStatus.inProgress || null => '',
    };

    return Positioned.fill(
      child: Stack(
        children: <Widget>[
          // Blocks input to the board/cog underneath while this is showing.
          ModalBarrier(color: Colors.black.withValues(alpha: 0.6)),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: AppColors.overlayChrome,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Game over',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: AppColors.panel,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (winner != null) ...<Widget>[
                          _ResultMark(player: winner),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          resultText,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: game.playAgain,
                    child: const Text(
                      'Play again',
                      style: TextStyle(
                        color: AppColors.canvasBackground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A large drawn X or O, styled like the marks on the board itself, shown
/// atop the win overlay's teal insert.
class _ResultMark extends StatelessWidget {
  const _ResultMark({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: CustomPaint(painter: _ResultMarkPainter(player: player)),
    );
  }
}

class _ResultMarkPainter extends CustomPainter {
  _ResultMarkPainter({required this.player});

  final Player player;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.overlayMark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double inset = size.width * 0.32;

    if (player == Player.x) {
      canvas.drawLine(
        center.translate(-inset, -inset),
        center.translate(inset, inset),
        paint,
      );
      canvas.drawLine(
        center.translate(inset, -inset),
        center.translate(-inset, inset),
        paint,
      );
    } else {
      canvas.drawCircle(center, inset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ResultMarkPainter oldDelegate) =>
      oldDelegate.player != player;
}

/// A dialog styled to match the game's bright teal/coral theme, with a title
/// and a row of [buttons] below it.
class _ThemedDialog extends StatelessWidget {
  const _ThemedDialog({required this.title, required this.buttons});

  final String title;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.accent, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisSize: MainAxisSize.min, children: buttons),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onPressed});

  final String label;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textLight,
        side: const BorderSide(color: AppColors.textLight, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
