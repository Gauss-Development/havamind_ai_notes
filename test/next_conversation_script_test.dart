import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/thesis/domain/utils/next_conversation_script.dart';

void main() {
  group('parseNextConversationScript', () {
    test('returns empty for null or blank input', () {
      expect(parseNextConversationScript(null).isEmpty, isTrue);
      expect(parseNextConversationScript('   ').isEmpty, isTrue);
    });

    test('maps labeled EN and RU sections', () {
      final script = parseNextConversationScript(
        'Who: clinic ops leads\n'
        'Hypothesis: they already pay a coordinator\n'
        'What not to ask: do not pitch the product',
      );

      expect(script.who, 'clinic ops leads');
      expect(script.hypothesis, 'they already pay a coordinator');
      expect(script.doNotAsk, 'do not pitch the product');
    });

    test('maps Russian labels', () {
      final script = parseNextConversationScript(
        'С кем: главврачи\n'
        'Гипотеза: платят из кармана\n'
        'Не спрашивать: не продавать питч',
      );

      expect(script.who, 'главврачи');
      expect(script.hypothesis, 'платят из кармана');
      expect(script.doNotAsk, 'не продавать питч');
    });

    test('splits unlabeled bullets into who / hypothesis / do-not-ask', () {
      final script = parseNextConversationScript(
        '• Talk to the next customer this week\n'
        '• They already tried a spreadsheet\n'
        '• Do not ask about willingness to pay first',
      );

      expect(script.who, 'Talk to the next customer this week');
      expect(script.hypothesis, 'They already tried a spreadsheet');
      expect(script.doNotAsk, 'Do not ask about willingness to pay first');
    });

    test('single line becomes who', () {
      final script = parseNextConversationScript(
        'Talk to the next customer this week.',
      );
      expect(script.who, 'Talk to the next customer this week.');
      expect(script.hypothesis, isNull);
      expect(script.doNotAsk, isNull);
    });
  });
}
