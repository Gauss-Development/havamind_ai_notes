import 'package:sample/features/thesis/domain/entities/next_conversation_script.dart';

final _bulletPrefix = RegExp(r'^[\s]*[•\-\*\u2013\u2014]\s*');
final _labelSplit = RegExp(r'[:\u2014\u2013]\s*');

const _whoLabels = <String>{
  'who',
  'с кем',
  'кому',
  'segment',
  'audience',
  'talk to',
  'говорить',
};

const _hypothesisLabels = <String>{'hypothesis', 'гипотеза', 'проверить'};

const _doNotAskLabels = <String>{
  'what not to ask',
  'what not',
  "don't ask",
  'do not ask',
  'не спрашивать',
  'чего не спрашивать',
  'чего не',
};

/// Splits a free-text next-conversation script into who / hypothesis / don't-ask.
NextConversationScript parseNextConversationScript(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const NextConversationScript();
  }

  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map(_stripBullet)
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  if (lines.isEmpty) return const NextConversationScript();

  final labeled = _parseLabeled(lines);
  if (labeled != null) return labeled;

  if (lines.length == 1) {
    return NextConversationScript(who: lines.first);
  }
  if (lines.length == 2) {
    return NextConversationScript(who: lines[0], hypothesis: lines[1]);
  }
  return NextConversationScript(
    who: lines[0],
    hypothesis: lines[1],
    doNotAsk: lines.sublist(2).join('\n'),
  );
}

String _stripBullet(String line) {
  return line.replaceFirst(_bulletPrefix, '').trim();
}

NextConversationScript? _parseLabeled(List<String> lines) {
  String? who;
  String? hypothesis;
  String? doNotAsk;
  var sawLabel = false;
  var current = _ScriptSection.none;

  for (final line in lines) {
    final match = _matchLabel(line);
    if (match != null) {
      sawLabel = true;
      current = match.section;
      _appendSection(
        section: match.section,
        text: match.rest,
        who: (v) => who = _join(who, v),
        hypothesis: (v) => hypothesis = _join(hypothesis, v),
        doNotAsk: (v) => doNotAsk = _join(doNotAsk, v),
      );
      continue;
    }
    if (!sawLabel) return null;
    _appendSection(
      section: current,
      text: line,
      who: (v) => who = _join(who, v),
      hypothesis: (v) => hypothesis = _join(hypothesis, v),
      doNotAsk: (v) => doNotAsk = _join(doNotAsk, v),
    );
  }

  if (!sawLabel) return null;
  return NextConversationScript(
    who: who,
    hypothesis: hypothesis,
    doNotAsk: doNotAsk,
  );
}

void _appendSection({
  required _ScriptSection section,
  required String text,
  required void Function(String) who,
  required void Function(String) hypothesis,
  required void Function(String) doNotAsk,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;
  switch (section) {
    case _ScriptSection.who:
      who(trimmed);
    case _ScriptSection.hypothesis:
      hypothesis(trimmed);
    case _ScriptSection.doNotAsk:
      doNotAsk(trimmed);
    case _ScriptSection.none:
      break;
  }
}

String? _join(String? existing, String next) {
  if (existing == null || existing.isEmpty) return next;
  return '$existing\n$next';
}

({_ScriptSection section, String rest})? _matchLabel(String line) {
  final parts = line.split(_labelSplit);
  final head = (parts.isEmpty ? line : parts.first).trim().toLowerCase();
  final rest = parts.length > 1 ? parts.sublist(1).join(': ').trim() : '';

  if (_containsLabel(head, _doNotAskLabels)) {
    return (section: _ScriptSection.doNotAsk, rest: rest);
  }
  if (_containsLabel(head, _hypothesisLabels)) {
    return (section: _ScriptSection.hypothesis, rest: rest);
  }
  if (_containsLabel(head, _whoLabels)) {
    return (section: _ScriptSection.who, rest: rest);
  }
  return null;
}

bool _containsLabel(String head, Set<String> labels) {
  return labels.contains(head);
}

enum _ScriptSection { none, who, hypothesis, doNotAsk }
