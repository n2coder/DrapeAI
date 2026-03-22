import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const _kBiometricEnabled = 'biometric_enabled';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  /// Whether the device supports biometric or device-credential auth.
  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck || isSupported;
  }

  /// Whether the user has opted in to biometric lock.
  Future<bool> isEnabled() async {
    final val = await _storage.read(key: _kBiometricEnabled);
    return val == 'true';
  }

  /// Persist the user's biometric lock preference.
  Future<void> setEnabled(bool enabled) async {
    await _storage.write(
      key: _kBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Prompt biometric / device PIN. Returns true if authenticated.
  Future<bool> authenticate({String reason = 'Unlock DrapeAI'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,   // also allows device PIN/pattern
          stickyAuth: true,       // keep prompt alive if app loses focus
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Clear biometric preference (called on sign-out).
  Future<void> clear() async {
    await _storage.delete(key: _kBiometricEnabled);
  }
}
