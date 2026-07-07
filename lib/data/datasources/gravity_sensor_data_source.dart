import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/gravity_direction.dart';

abstract interface class GravitySensorDataSource {
  Stream<GravityDirection> watchAccelerometerDirection();
}

class GravitySensorDataSourceImpl implements GravitySensorDataSource {
  const GravitySensorDataSourceImpl();

  @override
  Stream<GravityDirection> watchAccelerometerDirection() {
    return accelerometerEventStream().map(_toDirection);
  }

  GravityDirection _toDirection(AccelerometerEvent event) {
    final double magnitude = sqrt(event.x * event.x + event.y * event.y);
    if (magnitude < 0.01) {
      return GravityDirection.down;
    }
    return GravityDirection(-event.x / magnitude, event.y / magnitude);
  }
}
