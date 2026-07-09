import 'package:equatable/equatable.dart';

class EmailPasswordParams extends Equatable {
  const EmailPasswordParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
