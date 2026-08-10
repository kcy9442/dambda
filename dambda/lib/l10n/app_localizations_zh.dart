// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navHome => '首页';

  @override
  String get navCategory => '分类';

  @override
  String get navLikes => '收藏';

  @override
  String get navMy => '我的';

  @override
  String get emailLabel => '电子邮箱';

  @override
  String get passwordLabel => '密码';

  @override
  String get loginButton => '登录';

  @override
  String get loginFailedDefault => '登录失败。';

  @override
  String get noAccountSignupPrompt => '还没有账号？立即注册';

  @override
  String get signupTitle => '注册';

  @override
  String get nicknameLabel => '昵称';

  @override
  String get countryLabel => '国家或地区';

  @override
  String get passwordHelper => '至少8个字符，并包含大小写字母和数字。';

  @override
  String get countryRequiredError => '请选择国家或地区。';

  @override
  String get signupFailedDefault => '注册失败。';

  @override
  String get signupButton => '注册';

  @override
  String signupSuccessMessage(String nickname) {
    return '欢迎你，$nickname。请使用新账号登录。';
  }

  @override
  String get retryButton => '重试';

  @override
  String get productNotFound => '未找到商品。';

  @override
  String get storeLabel => '购买地点';

  @override
  String get homeBannerTitle => '来到韩国，这些商品不容错过';

  @override
  String get homeBannerSubtitle => '旅行者喜爱的零食和伴手礼';

  @override
  String get categoryAll => '全部';

  @override
  String get categorySnack => '零食';

  @override
  String get categoryCosmetic => '美妆';

  @override
  String get categoryLiving => '生活用品';

  @override
  String get likesEmpty => '还没有收藏的商品';

  @override
  String get guestName => '游客';

  @override
  String get guestSubtitle => '在DAMBDA整理你浏览过的商品';

  @override
  String get statLikes => '收藏';

  @override
  String get statBrowsed => '浏览过的商品';

  @override
  String get menuLanguage => '语言设置';

  @override
  String get menuOrders => '订单记录';

  @override
  String get menuSupport => '客户服务';

  @override
  String get menuAbout => '关于应用';

  @override
  String get menuLogout => '退出登录';

  @override
  String get languagePickerTitle => '选择语言';

  @override
  String reviewCountLabel(int count) {
    return '$count条评价';
  }

  @override
  String get reviewsEmpty => '暂无评价，快来发表第一条评价吧！';

  @override
  String get deleteReviewTitle => '删除评价';

  @override
  String get deleteReviewContent => '确定要删除吗？此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get reviewValidationError => '请填写评分和评价内容。';

  @override
  String get reviewFormTitleNew => '发表评价';

  @override
  String get reviewFormTitleEdit => '编辑评价';

  @override
  String get reviewHint => '这款商品怎么样？';

  @override
  String get attachPhoto => '添加照片（可选）';

  @override
  String get submitReview => '提交评价';

  @override
  String get updateReview => '更新评价';
}
