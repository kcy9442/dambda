import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_exception.dart';
import 'http_timeout.dart';

class SearchResult {
  final String title;
  final String url;
  final String content;

  const SearchResult({
    required this.title,
    required this.url,
    required this.content,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    title: json['title']?.toString() ?? '',
    url: json['url']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
  );
}

class AiSearchResponse {
  final String? answer;
  final List<SearchResult> results;

  const AiSearchResponse({this.answer, required this.results});
}

class SearchService {
  Uri _uri(String path) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    return Uri.parse('$base$path');
  }

  Future<AiSearchResponse> search(String query, String accessToken) async {
    final response = await http
        .post(
          _uri('/search'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'query': query,
            'searchDepth': 'advanced',
            'maxResults': 5,
          }),
        )
        .timeout(requestTimeout, onTimeout: timeoutError);

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'AI 검색을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['results'] as List<dynamic>? ?? const [];
    return AiSearchResponse(
      answer: body['answer']?.toString(),
      results: items
          .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
