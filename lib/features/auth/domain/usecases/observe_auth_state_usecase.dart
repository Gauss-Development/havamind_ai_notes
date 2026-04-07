import 'package:sample/features/auth/domain/auth_snapshot.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';

class ObserveAuthStateUseCase {
  ObserveAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AuthSnapshot> call() => _repository.watchAuthState();
}
