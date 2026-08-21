import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/count_audio_notes_usecase.dart';

/// Holds the user's total audio-note count. Emits `null` until the first
/// fetch resolves so the UI can skip rendering counts that would otherwise
/// show a stale "loaded page size" number.
class NotesCountCubit extends Cubit<int?> {
  NotesCountCubit({required CountAudioNotesUseCase countNotes})
    : _countNotes = countNotes,
      super(null) {
    refresh();
  }

  final CountAudioNotesUseCase _countNotes;

  Future<void> refresh() async {
    final result = await _countNotes(const NoParams());
    if (isClosed) return;
    result.fold((_) {}, (count) => emit(count));
  }
}
