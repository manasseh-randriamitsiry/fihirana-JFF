import '../../widgets/common/custom_snackbar.dart';

class SnackbarService {
  static void showSuccess(String message) {
    CustomSnackbar.success(message: message);
  }

  static void showError(String message) {
    CustomSnackbar.error(message: message);
  }

  static void showInfo(String message) {
    CustomSnackbar.info(message: message);
  }

  static void showWarning(String message) {
    CustomSnackbar.warning(message: message);
  }

  static void showLoading(String message) {
    CustomSnackbar.loading(message: message);
  }

  static void dismiss() {
    CustomSnackbar.dismiss();
  }
}
