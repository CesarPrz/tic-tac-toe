import '../../domain/entities/gravity_direction.dart';
import '../../domain/repositories/gravity_repository.dart';
import '../datasources/gravity_sensor_data_source.dart';

/// Uses the device's accelerometer when it's available and responsive,
/// falling back to a fixed downward direction otherwise (unsupported
/// platform, no hardware sensor, permission denied, etc).
class GravityRepositoryImpl implements GravityRepository {
  GravityRepositoryImpl(this._dataSource);

  final GravitySensorDataSource _dataSource;

  static const _sensorTimeout = Duration(seconds: 2);

  @override
  Stream<GravityDirection> watchGravityDirection() async* {
    try {
      yield* _dataSource.watchAccelerometerDirection().timeout(_sensorTimeout);
    } catch (_) {
      yield GravityDirection.down;
    }
  }
}
