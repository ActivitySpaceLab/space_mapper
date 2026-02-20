import 'package:asm/models/route_generator.dart';
import 'package:asm/util/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:background_fetch/background_fetch.dart';

import 'models/app_localizations.dart';
import 'package:uuid/uuid.dart';

class GlobalData {
  static String userUUID = "";
  static bool user_active_projects = false;
  static bool user_available_projects = false;
}

class AppLanguage {
  static const String preferenceKey = 'app_language_code';
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('en'));

  static Locale localeForCode(String languageCode) {
    if (AppLocalizations.supportedLanguageCodes.contains(languageCode)) {
      return Locale(languageCode);
    }
    return const Locale('en');
  }

  static Future<void> setLocale(String languageCode) async {
    final locale = localeForCode(languageCode);
    if (localeNotifier.value.languageCode == locale.languageCode) {
      return;
    }
    localeNotifier.value = locale;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, locale.languageCode);
  }
}

/// Receive events from BackgroundGeolocation in Headless state.
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
  print('📬 --> $headlessEvent');

  switch (headlessEvent.name) {
    case bg.Event.TERMINATE:
      try {
        //bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(samples: 1);
        print('[getCurrentPosition] Headless: $headlessEvent');
      } catch (error) {
        print('[getCurrentPosition] Headless ERROR: $error');
      }
      break;
    case bg.Event.HEARTBEAT:
      /* DISABLED getCurrentPosition on heartbeat
      try {
        bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(samples: 1);
        print('[getCurrentPosition] Headless: $location');
      } catch (error) {
        print('[getCurrentPosition] Headless ERROR: $error');
      }
      */
      break;
    case bg.Event.LOCATION:
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.MOTIONCHANGE:
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.GEOFENCE:
      bg.GeofenceEvent geofenceEvent = headlessEvent.event;
      print(geofenceEvent);
      break;
    case bg.Event.GEOFENCESCHANGE:
      bg.GeofencesChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.SCHEDULE:
      bg.State state = headlessEvent.event;
      print(state);
      break;
    case bg.Event.ACTIVITYCHANGE:
      bg.ActivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.HTTP:
      bg.HttpEvent response = headlessEvent.event;
      print(response);
      break;
    case bg.Event.POWERSAVECHANGE:
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.CONNECTIVITYCHANGE:
      bg.ConnectivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.ENABLEDCHANGE:
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.AUTHORIZATION:
      bg.AuthorizationEvent event = headlessEvent.event;
      print(event);
      break;
  }
}

/// Receive events from BackgroundFetch in Headless state.
void backgroundFetchHeadlessTask(String taskId) async {
  // Get current-position from BackgroundGeolocation in headless mode.
  //bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(samples: 1);
  print("[BackgroundFetch] HeadlessTask: $taskId");

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int count = 0;
  if (prefs.get("fetch-count") != null) {
    count = prefs.getInt("fetch-count")!;
  }
  prefs.setInt("fetch-count", ++count);
  print('[BackgroundFetch] count: $count');

  BackgroundFetch.finish(taskId);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.getInstance().then((SharedPreferences prefs) {
    // create random user ID if not yet created
    String? sampleId = prefs.getString("sample_id");
    String? userUUID = prefs.getString("user_uuid");

    GlobalData.userUUID = userUUID ?? ""; // Set the global userUUID

    if (sampleId == null || userUUID == null) {
      prefs.setString("user_uuid", Uuid().v4());
      prefs.setString("sample_id", ENV.DEFAULT_SAMPLE_ID);

      GlobalData.userUUID =
          prefs.getString("user_uuid") ?? ""; // Set the global userUUID
    }

    String? languageCode = prefs.getString(AppLanguage.preferenceKey);
    if (languageCode != null) {
      AppLanguage.localeNotifier.value =
          AppLanguage.localeForCode(languageCode);
    }

    print('userUUID: $userUUID');
    print('sampleId: $sampleId');

    runApp(new MyApp());
  });

  /// Register BackgroundGeolocation headless-task.
  bg.BackgroundGeolocation.registerHeadlessTask(
      backgroundGeolocationHeadlessTask);

  /// Register BackgroundFetch headless-task.
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.localeNotifier,
      builder: (context, selectedLocale, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: selectedLocale,
          supportedLocales: AppLocalizations.supportedLanguageCodes
              .map((code) => Locale(code, ''))
              .toList(),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) {
              return supportedLocales.first;
            }
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          initialRoute: '/',
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }
}
