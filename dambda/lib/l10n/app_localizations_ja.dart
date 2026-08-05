// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navHome => 'ホーム';

  @override
  String get navCategory => 'カテゴリー';

  @override
  String get navLikes => 'お気に入り';

  @override
  String get navMy => 'マイページ';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get loginButton => 'ログイン';

  @override
  String get loginFailedDefault => 'ログインに失敗しました。';

  @override
  String get noAccountSignupPrompt => 'アカウントをお持ちでない方はこちら';

  @override
  String get signupTitle => '新規登録';

  @override
  String get nicknameLabel => 'ニックネーム';

  @override
  String get countryLabel => '国・地域';

  @override
  String get passwordHelper => '8文字以上で、英大文字・小文字・数字を含めてください。';

  @override
  String get countryRequiredError => '国・地域を選択してください。';

  @override
  String get signupFailedDefault => '登録に失敗しました。';

  @override
  String get signupButton => '登録する';

  @override
  String signupSuccessMessage(String nickname) {
    return '$nicknameさん、ようこそ。登録したアカウントでログインしてください。';
  }

  @override
  String get retryButton => '再試行';

  @override
  String get productNotFound => '商品が見つかりません。';

  @override
  String get storeLabel => '購入場所';

  @override
  String get homeBannerTitle => '韓国に来たら、ぜひチェックしてください';

  @override
  String get homeBannerSubtitle => '旅行者に人気のお菓子＆お土産';

  @override
  String get categoryAll => 'すべて';

  @override
  String get categorySnack => 'お菓子';

  @override
  String get categoryCosmetic => 'コスメ';

  @override
  String get categoryLiving => '生活用品';

  @override
  String get likesEmpty => 'お気に入りの商品はまだありません';

  @override
  String get guestName => 'ゲスト旅行者';

  @override
  String get guestSubtitle => '気になる商品をDAMBDAで整理しましょう';

  @override
  String get statLikes => 'お気に入り';

  @override
  String get statBrowsed => '閲覧した商品';

  @override
  String get menuLanguage => '言語設定';

  @override
  String get menuOrders => '注文履歴';

  @override
  String get menuSupport => 'お問い合わせ';

  @override
  String get menuAbout => 'アプリ情報';

  @override
  String get menuLogout => 'ログアウト';

  @override
  String get languagePickerTitle => '言語を選択';

  @override
  String reviewCountLabel(int count) {
    return 'レビュー $count件';
  }

  @override
  String get reviewsEmpty => 'レビューはまだありません。最初のレビューを投稿しましょう！';

  @override
  String get deleteReviewTitle => 'レビューを削除';

  @override
  String get deleteReviewContent => '本当に削除しますか？この操作は元に戻せません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get reviewValidationError => '評価とレビュー内容を入力してください。';

  @override
  String get reviewFormTitleNew => 'レビューを書く';

  @override
  String get reviewFormTitleEdit => 'レビューを編集';

  @override
  String get reviewHint => 'この商品はいかがでしたか？';

  @override
  String get attachPhoto => '写真を添付（任意）';

  @override
  String get submitReview => 'レビューを投稿';

  @override
  String get updateReview => 'レビューを更新';
}
