import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/search/domain/utils/transcript_excerpt.dart';

void main() {
  group('stripTsHeadlineHtml', () {
    test('removes bold tags from ts_headline output', () {
      expect(
        stripTsHeadlineHtml('Found <b>founder</b> idea in notes'),
        'Found founder idea in notes',
      );
    });

    test('normalizes nbsp entities', () {
      expect(stripTsHeadlineHtml('word&nbsp;next'), 'word next');
    });
  });

  group('buildTranscriptExcerpt', () {
    test('returns excerpt centered on first match', () {
      final transcript =
          'We discussed the go-to-market plan for founders building voice products.';
      final excerpt = buildTranscriptExcerpt(
        transcript: transcript,
        query: 'founders',
        radius: 12,
      );

      expect(excerpt, isNotNull);
      expect(excerpt!, contains('founders'));
      expect(excerpt.startsWith('…'), isTrue);
    });

    test('returns null when query is missing', () {
      expect(
        buildTranscriptExcerpt(transcript: 'No match here', query: 'missing'),
        isNull,
      );
    });

    test('returns null for empty query', () {
      expect(
        buildTranscriptExcerpt(transcript: 'Some transcript', query: '   '),
        isNull,
      );
    });
  });
}
