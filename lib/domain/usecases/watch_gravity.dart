import '../entities/gravity_direction.dart';
import '../repositories/gravity_repository.dart';

class WatchGravity {
  const WatchGravity(this._repository);

  final GravityRepository _repository;

  Stream<GravityDirection> call() => _repository.watchGravityDirection();
}
