import 'package:flutter/material.dart';
import '../data/sample_products.dart';
import '../models/product.dart';

class AppState extends ChangeNotifier {
  final List<Product> products = List.of(sampleProducts);
  final Set<String> _likedIds = {};
  final Map<String, List<Comment>> _extraComments = {};

  bool isLiked(String productId) => _likedIds.contains(productId);

  void toggleLike(String productId) {
    if (_likedIds.contains(productId)) {
      _likedIds.remove(productId);
    } else {
      _likedIds.add(productId);
    }
    notifyListeners();
  }

  List<Product> get likedProducts =>
      products.where((p) => _likedIds.contains(p.id)).toList();

  List<Comment> commentsFor(Product product) {
    return [...product.comments, ...?_extraComments[product.id]];
  }

  void addComment(String productId, String author, String text) {
    if (text.trim().isEmpty) return;
    _extraComments.putIfAbsent(productId, () => []);
    _extraComments[productId]!.add(Comment(author: author, text: text.trim()));
    notifyListeners();
  }
}

final AppState appState = AppState();
