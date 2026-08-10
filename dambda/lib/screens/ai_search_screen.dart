import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/search_service.dart';
import '../state/auth_state.dart';
import '../widgets/dambda_app_bar.dart';

class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  final _controller = TextEditingController();
  final _service = SearchService();
  AiSearchResponse? _response;
  String? _error;
  bool _loading = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    final token = authState.accessToken;
    if (query.length < 2 || token == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.search(query, token);
      if (mounted) setState(() => _response = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'AI 검색 중 오류가 발생했어요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DambdaAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'AI 뷰티 검색',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('제품, 성분, 피부 고민을 물어보세요. AI가 최신 웹 정보를 찾아 요약합니다.'),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: '예: 민감성 피부에 좋은 보습 성분은?',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_response?.answer case final answer?) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 8),
                            Text(
                              'AI 답변',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(answer),
                      ],
                    ),
                  ),
                ),
              ],
              if (_response != null && _response!.results.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  '참고한 검색 결과',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._response!.results.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${item.content}\n${item.url}',
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
