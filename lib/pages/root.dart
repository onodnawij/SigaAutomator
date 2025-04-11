import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siga/providers/api_provider.dart';
import 'package:siga/utils/android_permission.dart';
import 'package:siga/utils/block_ui.dart';
import 'package:siga/vars.dart' show accessibilityGuide;

final pageControllerProvider = ChangeNotifierProvider((ref) => PageProvider());

class PageProvider extends ChangeNotifier{
  PageController controller  = PageController();

  void refresh() {
    controllerDispose();
    controller = PageController();
    notifyListeners();
  }

  void controllerDispose() {
    controller.dispose();
  }
}

class RootPage extends ConsumerStatefulWidget {
  const RootPage({super.key});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}


class _RootPageState extends ConsumerState<RootPage> {
  bool isRefreshed = false;
  
  @override
  Widget build(BuildContext context) {
    final pageController = ref.read(pageControllerProvider);
    if (!isRefreshed) {
      pageController.refresh();
      isRefreshed = true;
    }

    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final controller = ref.watch(pageControllerProvider);
          return PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: controller.controller,
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

class PermitScreenState extends ConsumerState {

  void checkPermit() async {
    final isBound = await AccessibilityHelper.check();
    if (isBound) {
      ref.read(pageControllerProvider)
      .controller.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInCubic
      );
      return;
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
  
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => checkPermit());
    return Container();
  }

  void requestAccessibility() async {
    final result = await AccessibilityHelper.request();
    final api = ref.read(apiProvider);

    if (result) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      api.showSuccess("Accessibility aktif!");
      ref.read(pageControllerProvider).controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInCubic);
    } else {
      api.showError("Accessibility belum diaktifkan");
    }
  }
}

class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {

  void runAfterInit () async {
    final api = ref.read(apiProvider);
    
    blockUI(context);

    while (ref.read(isOutdatedProvider) == null) {
      if (ref.read(isOutdatedProvider) != null) {
        api.dismiss();
        break;
      }

      await Future.delayed(Duration(seconds: 1));
    }

    if (ref.read(isOutdatedProvider)! && mounted) {
      api.dismiss();
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
      unblockUI(context);
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
      unblockUI(context);
      api.dismiss();
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