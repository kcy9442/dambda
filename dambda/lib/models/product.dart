import 'package:flutter/material.dart';

class Comment {
  final String author;
  final String text;

  const Comment({required this.author, required this.text});
}

class Product {
  final String id;
  final String nameKo;
  final String nameEn;
  final int price;
  final String store;
  final String category;
  final String emoji;
  final List<Color> gradient;
  final bool touristPick;
  final List<Comment> comments;

  const Product({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.price,
    required this.store,
    required this.category,
    required this.emoji,
    required this.gradient,
    this.touristPick = false,
    this.comments = const [],
  });

  String get priceLabel {
    final text = price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '$text원';
  }
}
