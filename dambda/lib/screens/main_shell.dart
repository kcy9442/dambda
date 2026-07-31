import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'category_screen.dart';
import 'home_screen.dart';
import 'likes_screen.dart';
import 'my_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CategoryScreen(),
    LikesScreen(),
    MyScreen(),
  ];

  static const _items = [
    (icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: '홈'),
    (icon: Icons.menu_rounded, outlineIcon: Icons.menu_rounded, label: '카테고리'),
    (icon: Icons.favorite, outlineIcon: Icons.favorite_border, label: '좋아요'),
    (icon: Icons.person, outlineIcon: Icons.person_outline, label: '마이'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == _index ? _items[i].icon : _items[i].outlineIcon,
                          color: i == _index
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == _index
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i == _index
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
