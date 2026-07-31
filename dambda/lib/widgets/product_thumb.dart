import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductThumb extends StatelessWidget {
  final Product product;
  final double size;
  final double radius;

  const ProductThumb({
    super.key,
    required this.product,
    this.size = 84,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: product.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        product.emoji,
        style: TextStyle(fontSize: size * 0.42),
      ),
    );
  }
}
