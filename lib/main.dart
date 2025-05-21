import "dart:io";
import "dart:ui";

import 'package:flutter/material.dart';
import "package:flutter_easyloading/flutter_easyloading.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:siga/pages/about.dart";
import "package:siga/pages/anggota/anggota.dart";
import "package:siga/pages/form_r1.dart";
import "package:siga/pages/home.dart";
import "package:siga/pages/listing.dart";
import "package:siga/pages/login.dart";
import "package:siga/pages/register.dart";
import "package:siga/pages/reports/reports.dart";
import "package:siga/pages/root.dart";
import "package:siga/pages/setting.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/providers/listing_provider.dart" show listingKeyProvider;
import "package:siga/providers/setting_provider.dart";
import "package:siga/providers/theme_provider.dart";
import "package:siga/utils/versioning.dart";
import "package:siga/vars.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:flutter/services.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ByteData cert = await PlatformAssetBundle().load("assets/ca/lets-encrypt-r3.pem");
  SecurityContext.defaultContext.setTrustedCertificatesBytes(cert.buffer.asInt8List());
  
  await Supabase.initialize(
    url: const String.fromEnvironment("SUPABASE_PROJ"),
    anonKey: const String.fromEnvironment("SUPABASE_KEY"),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> {
  late ScreenUtilInit app;
  late Map routes;
  late String _currentVersion;
  String interceptedText = "No input detected";
  bool isCheckingUpdate = true;

  @override
  void initState() {
    super.initState();
    EasyLoading.instance.loadingStyle = EasyLoadingStyle.custom;
    EasyLoading.instance.indicatorColor = Colors.white;
    EasyLoading.instance.backgroundColor = Color.fromARGB(90, 2, 56, 125);
    EasyLoading.instance.progressColor = Colors.amber;
    EasyLoading.instance.indicatorWidget = SizedBox(
      height: 50,
      width: 50,
      child: CircularProgressIndicator(color: Colors.white),
    );
    EasyLoading.instance.textColor = Colors.white;
    EasyLoading.instance.boxShadow = <BoxShadow>[];
    EasyLoading.instance.radius = 16;

    routes = {
      '/': RootPage(),
      '/home': HomePage(),
      '/login': LoginPage(),
      '/setting': SettingPage(),
      '/about': AboutPage(),
      '/reports': ReportsPage(),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkForUpdate();
      final setting = ref.read(settingProvider);
      await setting.isFinalized;
      final themeState = ref.read(appThemeStateNotifier);
      if (setting.theme["dark"]) {
        themeState.setDarkTheme();
      }
      if (setting.theme["zenith"]) {
        themeState.zenith();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkForUpdate() async {
    final supabase = Supabase.instance.client;
    String platform = Platform.operatingSystem;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;

    Map<String, dynamic>? response;

    final api = ref.read(apiProvider);

    try {
      response =
          await supabase
              .from('app_updates')
              .select()
              .eq('platform', platform)
              .single();
    } on PostgrestException {
      response = null;
      api.dismiss();
      api.showError('Cant check update');
    }

    if (response != null) {
      String latestVersion = response['latest_version'];
      String downloadUrl = response['download_url'];

      if (platform == 'android') {
        try {
          ProcessResult result = await Process.run('getprop', [
            'ro.product.cpu.abi',
          ]);
          String abi = result.stdout.toString().trim();
          if (abi == 'x86' || abi == 'x86_64') {
            abi = 'x86_64';
          }
          downloadUrl = downloadUrl.replaceAll('{abi}', abi);
        } catch (e) {
          print('Error getting CPU ABI: $e');
        }
      }
      // bool forceUpdate = response['force_update'] ?? false;

      if (isOutdated(_currentVersion, latestVersion)) {
        ref.read(downloadUrlProvider.notifier).state = downloadUrl;
        ref.read(isOutdatedProvider.notifier).state = true;
      } else {
        ref.read(isOutdatedProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(appThemeStateNotifier);

    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      locale: Locale('id', 'ID'),
      supportedLocales: appLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Siga Automator',
      theme: appTheme.isZenith ? appTheme.theme.lightPink : appTheme.theme.lightBlue,
      darkTheme: appTheme.isZenith ? appTheme.theme.darkPink : appTheme.theme.darkBlue,
      themeMode:
          appTheme.isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page = AboutPage();
        final List<String> mode = ['view', 'edit', 'new'];

        if (routes.keys.contains(settings.name)) {
          page = routes[settings.name];
        } else {
          var route = (settings.name ?? '').split('/');
          if (settings.name!.endsWith('register')) {
            page = RegisterPage(
              index: settings.arguments,
              menu: route[1],
              jenis: route[2],
            );
          } else if (mode.contains(route[route.length - 1])) {
            page = R1Page(
              options: settings.arguments,
              menu: route[1],
              jenis: route[2],
              mode: route[route.length - 1],
            );
          } else if (settings.name!.endsWith("anggota")) {
            page = AnggotaPage(
              index: settings.arguments,
              menu: route[1],
              jenis: route[2],
            );
          } else {
            ref.read(listingKeyProvider.notifier).state = "${route[1]}/${route[2]}".toLowerCase();
            page = ListingPage(menu: route[1], jenis: route[2]);
          }
        }

        return SlideRightRoute(widget: page);
      },
      builder: EasyLoading.init(),
    );
  }
}

class RootLayout extends StatefulWidget {
  const RootLayout({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RootLayoutState createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  String pageName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Center(
          child: Text(
            pageName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: "Plus!",
        child: Icon(Icons.add),
      ),
    );
  }
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget widget;
  SlideRightRoute({required this.widget})
    : super(
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return widget;
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      );
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
