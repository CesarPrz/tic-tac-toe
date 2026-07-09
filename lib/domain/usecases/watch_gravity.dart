import 'package:tic_tac_toe/domain/entities/gravity_direction.dart';
import 'package:tic_tac_toe/domain/repositories/gravity_repository.dart';

class WatchGravity {
  const WatchGravity(this._repository);

  final GravityRepository _repository;

  Stream<GravityDirection> call() => _repository.watchGravityDirection();
}
