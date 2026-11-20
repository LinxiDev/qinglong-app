import 'package:material_ui/material_ui.dart';

/// 头像变更通知：修改密码页上传成功后自增，「我的」页监听后重新拉取用户信息。
final ValueNotifier<int> avatarRevision = ValueNotifier<int>(0);
