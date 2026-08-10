import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_exception.dart';
import '../services/search_service.dart';
import '../state/auth_state.dart';

class ProductAiQuestion extends StatefulWidget {
  final Product product;

  const ProductAiQuestion({super.key, required this.product});

  @override
  State<ProductAiQuestion> createState() => _ProductAiQuestionState();
}

class _ProductAiQuestionState extends State<ProductAiQuestion> {
  final _controller = TextEditingController();
  final _service = SearchService();
  String? _answer;
  String? _error;
  bool _loading = false;

  String get _categoryLabel => switch (widget.product.category) {
    'SNACK' => '간식·식품',
    'COSMETIC' => '화장품·뷰티',
    'LIVING' => '생활용품',
    _ => widget.product.category,
  };

  Future<void> _ask() async {
    final question = _controller.text.trim();
    final token = authState.accessToken;
    if (question.length < 2 || token == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.search(
        '$_categoryLabel 제품 "${widget.product.name}"에 관한 질문입니다. $question',
        token,
      );
      if (mounted) setState(() => _answer = response.answer ?? '답변을 찾지 못했어요.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'AI 답변을 불러오지 못했어요.');
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.product.name}에 대해 AI에게 물어보세요',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              enabled: !_loading,
              onSubmitted: (_) => _ask(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: switch (widget.product.category) {
                  'SNACK' => '알레르기, 맛, 원재료 등을 물어보세요',
                  'COSMETIC' => '성분, 피부 타입, 사용법 등을 물어보세요',
                  'LIVING' => '사용법, 소재, 주의사항 등을 물어보세요',
                  _ => '이 제품에 대해 궁금한 점을 물어보세요',
                },
                border: const OutlineInputBorder(),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(onPressed: _ask, icon: const Icon(Icons.send)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_answer != null) ...[
              const SizedBox(height: 14),
              SelectableText(_answer!),
            ],
          ],
        ),
      ),
    );
  }
}
