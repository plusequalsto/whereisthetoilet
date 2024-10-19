import 'package:realm/realm.dart';

part 'user_models.realm.dart';

@RealmModel()
class _UserModel {
  @PrimaryKey()
  late String userId;
  late String accessToken;
  late String refreshToken;
}
