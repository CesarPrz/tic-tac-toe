// A normalized 2D direction that "down" currently points toward, in
// screen-space (positive `dy` points toward the bottom of the screen).

class GravityDirection {
  const GravityDirection(this.dx, this.dy);

  /// Straight down — used when no sensor is available.
  static const down = GravityDirection(0, 1);

  final double dx;
  final double dy;
}
