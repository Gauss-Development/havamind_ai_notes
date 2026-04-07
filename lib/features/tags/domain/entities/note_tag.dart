import 'package:equatable/equatable.dart';

class NoteTag extends Equatable {
  const NoteTag({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, name, createdAt];
}
