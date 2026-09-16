import 'package:equatable/equatable.dart';

/// Parsed `theses.next_conversation_script` for the post-debrief screen.
class NextConversationScript extends Equatable {
  const NextConversationScript({this.who, this.hypothesis, this.doNotAsk});

  final String? who;
  final String? hypothesis;
  final String? doNotAsk;

  bool get isEmpty =>
      !_hasText(who) && !_hasText(hypothesis) && !_hasText(doNotAsk);

  @override
  List<Object?> get props => [who, hypothesis, doNotAsk];
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
