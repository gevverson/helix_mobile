import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helix_mobile/config/app_constants.dart';
import 'package:helix_mobile/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    TokenStore.resetForTest();
  });

  test('write stores the token in secure storage, never in SharedPreferences', () async {
    await TokenStore.write('tok-A');
    expect(await const FlutterSecureStorage().read(key: AppConstants.tokenKey), 'tok-A');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.tokenKey), isNull);
  });

  test('a token left in SharedPreferences by an older build is migrated and removed', () async {
    SharedPreferences.setMockInitialValues({AppConstants.tokenKey: 'legacy'});

    expect(await TokenStore.read(), 'legacy'); // user stays signed in

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.tokenKey), isNull);
    expect(await const FlutterSecureStorage().read(key: AppConstants.tokenKey), 'legacy');
  });

  test('clear removes the token everywhere', () async {
    await TokenStore.write('tok-A');
    await TokenStore.clear();
    TokenStore.resetForTest(); // read from storage, not the cache
    expect(await TokenStore.read(), isNull);
  });
}
