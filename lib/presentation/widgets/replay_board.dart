import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tic_tac_toe/domain/commands/place_mark_command.dart';
import 'package:tic_tac_toe/domain/entities/board.dart' as domain;
import 'package:tic_tac_toe/domain/entities/player.dart';
import 'package:tic_tac_toe/domain/entities/position.dart';
import 'package:tic_tac_toe/presentation/theme/app_colors.dart';

/// A small board that replays [moves] one at a time, holds on the finished
/// position for a beat, then clears and loops — reconstructed by replaying
/// each [PlaceMarkCommand] from an empty [domain.Board], so it stays a pure
/// readout of the move history rather than duplicating any game logic.
class ReplayBoard extends StatefulWidget {
  const ReplayBoard({required this.moves, super.key});

  final List<PlaceMarkCommand> moves;

  @override
  State<ReplayBoard> createState() => _ReplayBoardState();
}

class _ReplayBoardState extends State<ReplayBoard> {
  static const Duration _stepDuration = Duration(milliseconds: 450);
  static const Duration _holdDuration = Duration(milliseconds: 1200);
  static const Duration _pauseDuration = Duration(milliseconds: 500);

  int _visibleMoves = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_pauseDuration, _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _visibleMoves = _visibleMoves < widget.moves.length ? _visibleMoves + 1 : 0;
    });

    final Duration nextDelay = _visibleMoves == 0
        ? _pauseDuration
        : _visibleMoves == widget.moves.length
        ? _holdDuration
        : _stepDuration;
    _timer = Timer(nextDelay, _tick);
  }

  domain.Board get _board {
    domain.Board board = domain.Board();
    for (final PlaceMarkCommand command in widget.moves.take(_visibleMoves)) {
      board = command.execute(board);
    }
    return board;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: CustomPaint(painter: _ReplayBoardPainter(board: _board)),
    );
  }
}

class _ReplayBoardPainter extends CustomPainter {
  _ReplayBoardPainter({required this.board});

  final domain.Board board;

  final Paint _gridPaint = Paint()
    ..color = Colors.white24
    ..strokeWidth = 2;

  final Paint _xPaint = Paint()
    ..color = AppColors.accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;

  final Paint _oPaint = Paint()
    ..color = AppColors.overlayMark
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / 3;
    final double cellHeight = size.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cellWidth * i, 0),
        Offset(cellWidth * i, size.height),
        _gridPaint,
      );
      canvas.drawLine(
        Offset(0, cellHeight * i),
        Offset(size.width, cellHeight * i),
        _gridPaint,
      );
    }

    for (int i = 0; i < 9; i++) {
      final Player? mark = board.at(Position.fromIndex(i));
      if (mark == null) continue;

      final Offset center = Offset(
        (i % 3 + 0.5) * cellWidth,
        (i ~/ 3 + 0.5) * cellHeight,
      );
      final double inset = cellWidth * 0.28;

      if (mark == Player.x) {
        canvas.drawLine(
          center.translate(-inset, -inset),
          center.translate(inset, inset),
          _xPaint,
        );
        canvas.drawLine(
          center.translate(inset, -inset),
          center.translate(-inset, inset),
          _xPaint,
        );
      } else {
        canvas.drawCircle(center, inset, _oPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReplayBoardPainter oldDelegate) => true;
}
