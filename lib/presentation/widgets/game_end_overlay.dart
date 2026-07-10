import 'package:flutter/material.dart';
import 'package:tic_tac_toe/domain/entities/game_status.dart';
import 'package:tic_tac_toe/presentation/game/title_screen_game.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';
import 'package:tic_tac_toe/presentation/widgets/play_again_button.dart';
import 'package:tic_tac_toe/presentation/widgets/replay_board.dart';

/// Shown once a round ends (see `TitleScreenGame.gameEndOverlayKey`): a
/// looping replay of the round's moves on a teal block, the result, a chunky
/// "Play again" button, and a "Main menu" link — styled after a dark-chrome
/// card with a colored insert.
class GameEndOverlay extends StatelessWidget {
  const GameEndOverlay({required this.game, super.key});

  final TitleScreenGame game;

  @override
  Widget build(BuildContext context) {
    final GameStatus? status = game.lastGameStatus;
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
                        if (game.lastMoveHistory.isNotEmpty) ...<Widget>[
                          ReplayBoard(moves: game.lastMoveHistory),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        PlayAgainButton(onPressed: game.playAgain),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: game.returnToTitle,
                          child: const Text(
                            'Main menu',
                            style: TextStyle(
                              color: AppColors.canvasBackground,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
