import '../entities/gravity_direction.dart';

/// Source of truth for "which way is down" right now. Implementations
/// decide how that's determined (device sensors, a fixed default, etc).
abstract interface class GravityRepository {
  Stream<GravityDirection> watchGravityDirection();
}
