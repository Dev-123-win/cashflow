import 'package:get_it/get_it.dart';
import '../../services/ad_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/fee_calculation_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/task_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  getIt.registerLazySingleton<AdService>(() => AdService());
  getIt.registerLazySingleton<CloudflareWorkersService>(
    () => CloudflareWorkersService(),
  );
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
  getIt.registerLazySingleton<LocalNotificationService>(
    () => LocalNotificationService(),
  );
  getIt.registerLazySingleton<RequestDeduplicationService>(
    () => RequestDeduplicationService(),
  );
  getIt.registerLazySingleton<FeeCalculationService>(
    () => FeeCalculationService(),
  );
  getIt.registerLazySingleton<DeviceFingerprintService>(
    () => DeviceFingerprintService(),
  );
  getIt.registerLazySingleton<TaskService>(() => TaskService());
}
