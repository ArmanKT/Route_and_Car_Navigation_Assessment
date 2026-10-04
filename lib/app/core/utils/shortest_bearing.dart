class ShortestBearing {
  ShortestBearing._();

  /// Calculates the shortest angular delta between current and target angle in degrees.
  /// Result is in range [-180, 180].
  /// E.g. from 359 to 1 returns +2 degrees, not -358 degrees.
  static double shortestAngleDelta(double fromDegrees, double toDegrees) {
    var delta = (toDegrees - fromDegrees) % 360.0;
    if (delta > 180.0) {
      delta -= 360.0;
    } else if (delta < -180.0) {
      delta += 360.0;
    }
    return delta;
  }

  /// Interpolates between fromDegrees and toDegrees using the shortest path.
  /// Fraction t is in [0.0, 1.0].
  static double interpolateAngle(double fromDegrees, double toDegrees, double t) {
    final delta = shortestAngleDelta(fromDegrees, toDegrees);
    final result = (fromDegrees + delta * t.clamp(0.0, 1.0)) % 360.0;
    return (result + 360.0) % 360.0;
  }
}
