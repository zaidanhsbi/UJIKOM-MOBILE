import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'data/datasources/exam_local_storage.dart';
import 'presentation/router/app_router.dart';

/// Titik masuk utama aplikasi BinoExam.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ExamLocalStorage.initHive();
  runApp(const ProviderScope(child: BinoExamApp()));
}

class BinoExamApp extends ConsumerWidget {
  const BinoExamApp({super.key});

  /// Membangun widget akar aplikasi dengan tema dan konfigurasi router.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BinoExam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
