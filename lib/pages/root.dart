import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siga/providers/api_provider.dart';
import 'package:siga/utils/android_permission.dart';
import 'package:siga/utils/block_ui.dart';
import 'package:siga/utils/versioning.dart';
import 'package:siga/vars.dart' show accessibilityGuide;
import "package:supabase_flutter/supabase_flutter.dart";

final pageControllerProvider = Provider((ref) => PageController());

class RootPage extends ConsumerStatefulWidget {
  const RootPage({super.key});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}


class _RootPageState extends ConsumerState<RootPage> {  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          return PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: ref.read(pageControllerProvider),
            children: [
              PermitScreen(),
              UpdateScreen(),
            ],
          );
        }
      )
    );
  }
}

class PermitScreen extends ConsumerStatefulWidget {
  const PermitScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => PermitScreenState();
}

class PermitScreenState extends ConsumerState<PermitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => checkPermit());
  }

  Future<void> checkPermit() async {
    final isBound = await AccessibilityHelper.check();
    if (isBound) {
      return ref.read(pageControllerProvider).nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInCubic
      );
    }

    if (mounted) {
      showAdaptiveDialog(
        context: context,
        barrierDismissible: false, // Disable tap outside
        builder: (BuildContext context) {
          return PopScope(
            canPop: false, // Disable back button
            child: AlertDialog.adaptive(
              insetPadding: EdgeInsets.symmetric(vertical: 22, horizontal: 14),
              icon: Icon(Icons.bolt),
              iconColor: Colors.amber,
              title: const Text("Aktifkan Accessibility"),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                  maxWidth: MediaQuery.of(context).size.width - 28, // match padding
                ),
                child: Markdown(
                  padding: EdgeInsets.all(2),
                  data: accessibilityGuide,
                ),
              ),
              actions: [
                FilledButton(
                  style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.tertiaryContainer.withAlpha(32))),
                  onPressed: () {
                    requestAccessibility();
                  },
                  child: Text("Buka Pengaturan", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void requestAccessibility() async {
    final result = await AccessibilityHelper.request();
    final api = ref.read(apiProvider);

    if (result) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      api.showSuccess("Accessibility aktif!");
      ref.read(pageControllerProvider).nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInCubic);
    } else {
      api.showError("Accessibility belum diaktifkan");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {

  Future<Map<String, dynamic>?> checkForUpdate() async {
    final api = ref.read(apiProvider);
    api.showLoading(context: context, message: "Checking for updates");
    await Future.delayed(Duration(seconds: 1));
    final supabase = Supabase.instance.client;
    String platform = Platform.operatingSystem;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    Map<String, dynamic>? response;

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

      api.dismiss();
      
      return {
        "isOutdated": isOutdated(currentVersion, latestVersion),
        "downloadUrl": downloadUrl,
      };
    } else {
      return null;
    }
  }

  void runAfterInit () async {
    final updateInfo = await checkForUpdate();

    if ((updateInfo?["isOutdated"] ?? false) && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text("Update Available"),
            content: Text("A new version is available. Please update."),
            actions: [
              TextButton(
                child: Text("Update!"),
                onPressed: () {
                  Navigator.of(context).pop();
                  startDownload(ref.read(downloadUrlProvider));
                }
              ),
            ],
          ),
        ),
      );
    } else if (mounted) {
      // widget.api.showSuccess('App is up to date!');
      Navigator.of(context).popAndPushNamed('/login');
    }
  }

  void startDownload (String url) async {
    final api = ref.read(apiProvider);

    Dio dio = Dio();
    final filename = Uri.parse(url).pathSegments.last;
    final filePath = "${(await getTemporaryDirectory()).path}/$filename";
    api.showProgress(0, "0%\nDownloading Updates");

    try {
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            api.showProgress(progress, "${(progress * 100).toStringAsFixed(1)}%\nDownloading Updates");
          }
        },
      );

      api.dismiss();

      if (mounted) {
        blockUI(context);
        api.showLoading(message: "Installing Updates", context: context);
        await Future.delayed(Duration(seconds: 1));
      }

      if (Platform.isAndroid) {
        bool lesgo = true;
        while (lesgo) {
          await Permission.requestInstallPackages.isDenied.then((value) async {
            if (value) {
              PermissionStatus status = await Permission.requestInstallPackages.request();

              if (status.isGranted) {
                lesgo = false;
              }
            } else {
              lesgo = false;
            }
          });

          await Future.delayed(Duration(seconds: 1));
        }
      }
    } on DioException catch (e) {
      print(e);
    }

    if (mounted) {
      api.dismiss();
      unblockUI(context);
    }
    
    await OpenFile.open(filePath);
    
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runAfterInit();
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}