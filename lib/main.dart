import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:future_hub/employee/orders/cubit/order_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'common/auth/cubit/auth_cubit.dart';
import 'common/auth/cubit/auth_state.dart';
import 'common/info/cubit/info_cubit.dart';
import 'common/notifications/cubit/notifications_cubit.dart';
import 'common/notifications/services/notifications_service.dart';
import 'common/points/cubit/prevoius_orders_cubit/cubit.dart';
import 'common/shared/cubits/drawer_cubit/cubit.dart';
import 'common/shared/cubits/locale_cubit.dart';
import 'common/shared/cubits/orders_cubit/orders_cubit.dart';
import 'common/shared/cubits/products_cubit/products_cubit.dart';
import 'common/shared/cubits/wallet_cubit/wallet_cubit.dart';
import 'common/shared/palette.dart';
import 'common/shared/router.dart';
import 'common/shared/services/map_services.dart';
import 'common/shared/services/remote/dio_manager.dart';
import 'common/shared/utils/cache_manager.dart';
import 'common/splash/cubit/cubit.dart';
import 'company/companyOrders/cubit/cubit/company_order_cubit.dart';
import 'company/coupons/cubit/coupons_cubit.dart';
import 'company/employees/cubit/employees_cubit.dart';
import 'employee/oil/cubit/best_oil_cubit/best_oil_cubit.dart' as oil_best;
import 'employee/oil/cubit/oil_cubit.dart';
import 'employee/orders/cubit/employee_order_cubit.dart';
import 'employee/orders/cubit/employee_punchers_cubit.dart';
import 'employee/orders/cubit/employee_services_branches_cubit.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'puncher/daily_report/cubit/puncher_report_cubit.dart';
import 'puncher/orders/order_cubit/service_provider_orders_cubit.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late BuildContext genContext;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('ar', timeago.ArMessages());

  await CacheManager.init();
  await DioHelper.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationsService().initializeNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (Platform.isAndroid) {
    await _createNotificationChannel();
  }

  await MapServices.ensureLocationEnabled();
  try {
    await MapServices.initPusherAndTracking();
  } catch (e, s) {
    print('Pusher init error: $e\n$s');
  }

  final service = FlutterBackgroundService();
  if (await CacheManager.isTrackingActive()) {
    final isRunning = await service.isRunning();
    if (!isRunning && await CacheManager.isTrackingActive()) {
      await service.startService();
    }
  }
  await setupFCM();
  runApp(const FutureHubApp());
}

Future<void> _createNotificationChannel() async {
  const channel = AndroidNotificationChannel(
    'driver_tracking',
    'تتبع السائق',
    description: 'جاري تتبع موقعك',
    importance: Importance.low,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  String? token;
  int retryCount = 0;

  while (token == null && retryCount < 5) {
    try {
      token = await messaging.getToken();
      print("FCM Token: $token");
    } catch (e) {
      print("FCM Error (retry ${retryCount + 1}): $e");
      await Future.delayed(const Duration(seconds: 2));
      retryCount++;
    }
  }

  if (token == null) {
    print("Failed to get FCM token after 5 attempts");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    name: 'Future-hub',
  );
  NotificationsService().showNotification(message);
}

class FutureHubApp extends StatelessWidget {
  const FutureHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    genContext = context;
    final media = MediaQuery.of(context);
    final textScaleFactor =
        media.textScaleFactor * (Platform.isAndroid ? 0.70 : 0.85);

    return BlocProvider(
      create: (context) => AuthCubit()..init(),
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScaleFactor)),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final signedInProviders = [
              BlocProvider(
                  create: (context) => InfoCubit()..init(), lazy: false),
              BlocProvider(create: (context) => LocaleCubit()),
              BlocProvider(create: (context) => NotificationsCubit()..init()),
              BlocProvider(
                  create: (context) => EmployeesCubit()
                    ..init()
                    ..fetchBranches()
                    ..fetchVehicles()),
              BlocProvider(
                  create: (context) => EmployeePunchersCubit()..loadPunchers()),
              BlocProvider(create: (_) => ServicesPunchersCubit()),
              BlocProvider(create: (context) => ProductsCubit()),
              BlocProvider(create: (context) => OrdersCubit()),
              BlocProvider(
                create: (context) {
                  final authState = context.read<AuthCubit>().state;
                  final cubit = ServiceProviderOrdersCubit();
                  if (authState is AuthSignedIn) {
                    if (authState.user.puncherTypes!.contains('Fuel')) {
                      cubit.loadOrders();
                    } else {
                      cubit.loadServicesOrders();
                    }
                  }
                  return cubit;
                },
              ),
              BlocProvider(
                  create: (context) => EmployeeOrderCubit()..loadOrders()),
              BlocProvider(create: (context) => PincherReportCubit()),
              BlocProvider(
                  create: (context) =>
                      CompanyOrderCubit()..loadCompanyOrders()),
              BlocProvider(create: (context) => OrderCubit()),
              BlocProvider(create: (context) => WalletCubit()),
              BlocProvider(create: (context) => OilCubit()..init()),
              BlocProvider(create: (context) => CouponsCubit()),
              BlocProvider(create: (context) => oil_best.ProductsCubit()),
              BlocProvider(create: (context) => UserGiftsCubit()),
              BlocProvider(create: (context) => DrawerCubit()),
            ];

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => LocaleCubit()),
                BlocProvider(create: (context) => DrawerCubit()),
                BlocProvider(
                    create: (context) => SplashCubit()..onInit(context)),
                BlocProvider(
                    create: (context) => InfoCubit()..init(), lazy: false),
                if (state is AuthSignedIn) ...signedInProviders,
              ],
              child: BlocBuilder<LocaleCubit, Locale?>(
                builder: (context, state) {
                  return MaterialApp.router(
                    title: 'Futurehub',
                    routerConfig: router,
                    debugShowCheckedModeBanner: false,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [
                      Locale('en'),
                      Locale('ar'),
                      Locale('ur'),
                    ],
                    locale: state,
                    theme: ThemeData(
                      appBarTheme: const AppBarTheme(
                          backgroundColor: Palette.whiteColor),
                      useMaterial3: false,
                      fontFamily: state == const Locale("en") ? 'sf' : null,
                      textTheme: state == const Locale("ar")
                          ? GoogleFonts.almaraiTextTheme()
                          : null,
                      dividerColor: Palette.primaryLightColor,
                      primaryColor: Palette.primaryColor,
                      colorScheme: const ColorScheme.light()
                          .copyWith(primary: Palette.primaryColor),
                      scaffoldBackgroundColor: Palette.whiteColor,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
