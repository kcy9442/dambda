import 'package:flutter/material.dart';
import '../data/countries.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/dambda_app_bar.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  String _countryName(String code) {
    final match = countries.where((c) => c.code == code);
    return match.isEmpty ? code : match.first.nameKo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DambdaAppBar(),
      body: ListenableBuilder(
        listenable: Listenable.merge([appState, authState]),
        builder: (context, _) {
          final profile = authState.profile;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surface,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.nickname ?? 'Guest Traveler',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile != null
                            ? '${_countryName(profile.country)} · ${profile.email}'
                            : '둘러본 아이템을 담다에서 정리해보세요',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: '좋아요',
                      value: '${appState.likedProducts.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: '둘러본 아이템',
                      value: '${appState.products.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const _MenuRow(icon: Icons.language, label: '언어 설정 · Language'),
              const _MenuRow(icon: Icons.receipt_long, label: '주문 내역'),
              const _MenuRow(icon: Icons.help_outline, label: '고객센터'),
              const _MenuRow(icon: Icons.info_outline, label: '앱 정보'),
              _MenuRow(
                icon: Icons.logout,
                label: '로그아웃',
                onTap: authState.logout,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap ?? () {},
    );
  }
}
