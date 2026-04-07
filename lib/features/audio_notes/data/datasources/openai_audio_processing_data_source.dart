import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class OpenAiTranscriptionResult {
  const OpenAiTranscriptionResult({
    required this.transcriptText,
    this.language,
  });

  final String transcriptText;
  final String? language;
}

class OpenAiStartupAnalysisResult {
  const OpenAiStartupAnalysisResult({
    this.shortSummary,
    this.startupTitle,
    this.problem,
    this.solution,
    this.targetAudience,
    this.businessModel,
    this.keyMetrics,
    this.advantages,
    this.risksGaps,
    this.followUpQuestions,
    this.marketPotentialScore,
    this.technicalComplexityScore,
    required this.rawAiResponse,
  });

  final String? shortSummary;
  final String? startupTitle;
  final String? problem;
  final String? solution;
  final String? targetAudience;
  final String? businessModel;
  final String? keyMetrics;
  final String? advantages;
  final String? risksGaps;
  final List<String>? followUpQuestions;
  final int? marketPotentialScore;
  final int? technicalComplexityScore;
  final Map<String, dynamic> rawAiResponse;
}

class OpenAiAudioProcessingDataSource {
  OpenAiAudioProcessingDataSource({
    required String apiKey,
    http.Client? httpClient,
  }) : _apiKey = apiKey,
       _http = httpClient ?? http.Client();

  static const _transcriptionModel = 'gpt-4o-mini-transcribe';
  static const _analysisModel = 'gpt-4o-mini';

  final String _apiKey;
  final http.Client _http;

  Future<OpenAiTranscriptionResult> transcribeAudio(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer $_apiKey';
    request.fields['model'] = _transcriptionModel;
    request.fields['response_format'] = 'json';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await _http.send(request);
    final body = await streamed.stream.bytesToString();
    final decoded = _decodeJsonMap(body);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(_extractOpenAiError(decoded, streamed.statusCode));
    }

    final text = (decoded['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw Exception('OpenAI returned empty transcription');
    }
    final language = (decoded['language'] as String?)?.trim();
    return OpenAiTranscriptionResult(
      transcriptText: text,
      language: language == null || language.isEmpty ? null : language,
    );
  }

  Future<OpenAiStartupAnalysisResult> analyzeTranscript(
    String transcriptText,
  ) async {
    final prompt =
        '''
You are a startup business analyst.

Based on the transcription, return strictly JSON with this structure:
{
  "summary": "",
  "startup_title": "",
  "problem": "",
  "solution": "",
  "target_audience": "",
  "business_model": "",
  "key_metrics": "",
  "advantages": "",
  "risks_gaps": "",
  "follow_up_questions": ["", ""],
  "market_potential_score": 0,
  "technical_complexity_score": 0
}

Rules:
- if data is missing, use "not specified"
- follow_up_questions is always an array of strings (can be empty)
- market_potential_score — integer 0-100, market potential assessment
- technical_complexity_score — integer 0-100, technical complexity assessment
- no markdown, only JSON

Transcription:
$transcriptText
''';

    final response = await _http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _analysisModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.3,
      }),
    );

    final decoded = _decodeJsonMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractOpenAiError(decoded, response.statusCode));
    }

    final rawContent =
        (((decoded['choices'] as List?)?.firstOrNull as Map?)?['message']
                as Map?)?['content']
            as String? ??
        '{}';
    final parsed = _decodeJsonMap(_extractJsonBlock(rawContent));

    return OpenAiStartupAnalysisResult(
      shortSummary: _normalizeString(parsed['summary']),
      startupTitle: _normalizeString(parsed['startup_title']),
      problem: _normalizeString(parsed['problem']),
      solution: _normalizeString(parsed['solution']),
      targetAudience: _normalizeString(parsed['target_audience']),
      businessModel: _normalizeString(parsed['business_model']),
      keyMetrics: _normalizeString(parsed['key_metrics']),
      advantages: _normalizeString(parsed['advantages']),
      risksGaps: _normalizeString(parsed['risks_gaps']),
      followUpQuestions: _normalizeStringList(parsed['follow_up_questions']),
      marketPotentialScore: _normalizeInt(parsed['market_potential_score']),
      technicalComplexityScore: _normalizeInt(
        parsed['technical_complexity_score'],
      ),
      rawAiResponse: parsed,
    );
  }

  Map<String, dynamic> _decodeJsonMap(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON response from OpenAI');
    }
    return decoded;
  }

  String _extractOpenAiError(Map<String, dynamic> payload, int statusCode) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      final msg = error['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }
    }
    return 'OpenAI error (HTTP $statusCode)';
  }

  String _extractJsonBlock(String source) {
    final cleaned = source.trim();
    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      return cleaned;
    }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return cleaned.substring(start, end + 1);
    }
    throw Exception('OpenAI returned invalid analysis JSON');
  }

  int? _normalizeInt(Object? value) {
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.toInt().clamp(0, 100);
    return null;
  }

  String? _normalizeString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String>? _normalizeStringList(Object? value) {
    if (value is! List) return null;
    final list = value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return list.isEmpty ? null : list;
  }
}

extension on List<dynamic> {
  dynamic get firstOrNull => isEmpty ? null : first;
}
