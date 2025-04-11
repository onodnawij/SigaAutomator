import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:ms_undraw/ms_undraw.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/providers/setting_provider.dart";
import "package:siga/providers/theme_provider.dart";
import "package:siga/utils/block_ui.dart";


class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  final String title = 'login';
  
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  bool hidePassword = true;
  bool stayLoggedIn = false;
  Map<String, dynamic>? userData;
  String? errorText;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late final AnimationController _controller;
  
  int startOpac = 255;

  void hideShowPassword() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }
  

  void doLogin(context) async {
    final api = ref.read(apiProvider);
    final userRef = ref.read(userProvider);
    
    blockUI(context);
    bool loggedIn = await api.getUser(
      username: usernameController.text,
      password: passwordController.value.text,
      context: context,
      userData: userData,
    );
    unblockUI(context);
    if (loggedIn) {
      Map<String, dynamic> setting = {};
      setting["username"] = usernameController.text;
      setting["stayLoggedIn"] = stayLoggedIn;
      
      if (stayLoggedIn) {
        setting["userData"] = userRef.user?.toJson();
      }
      
      ref.read(settingProvider).login = setting;
      Navigator.popAndPushNamed(context, '/home');
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((timestamp) async {
      final setting = ref.read(settingProvider);
      await setting.isFinalized;

      if (mounted) {
        setState(() {
          stayLoggedIn = setting.login["stayLoggedIn"] ?? false;
          userData = setting.login["userData"];
          usernameController.text = setting.login["username"];
        });

        if (stayLoggedIn) {
          doLogin(context);
        }
      }
    });
    
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 320,
            height: 900,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  RichText(
                    text: TextSpan(
                      text: 'new',
                      style: GoogleFonts.lato().copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: TextTheme.of(context).displayMedium?.fontSize,
                      ),
                      children: [
                        TextSpan(
                          text: "siga",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.surfaceTint,
                            fontSize: TextTheme.of(context).displayLarge?.fontSize,
                            fontStyle: FontStyle.normal
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 100),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 8),
                          Text('Let\'s start!', style: TextStyle(fontSize: TextTheme.of(context).titleMedium?.fontSize, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: usernameController,
                        onChanged: (value) {
                          if (value == 'operator.357301') {
                            ref.read(appThemeStateNotifier).zenith();
                          } else {
                            ref.read(appThemeStateNotifier).unZenith();
                          }
                          setState(() {
                            errorText = null;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.account_circle_rounded, color: Theme.of(context).colorScheme.primary),
                          // filled: true,
                          // fillColor: widget.api.themeController.isDark.value?Colors.white.withAlpha(20):Colors.white,
                          // hoverColor: widget.api.themeController.isDark.value?Colors.white.withAlpha(30):Colors.grey.shade100,
                          labelText: "Username",
                          errorText: errorText,
                          errorStyle: TextStyle(fontSize: 0),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: passwordController,
                        onChanged: (value) {
                          setState(() {
                            errorText = null;
                          });
                        },
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.password_rounded, color: Theme.of(context).colorScheme.primary),
                          suffixIcon: IconButton(
                            onPressed: hideShowPassword,
                            icon: Icon(
                              hidePassword?Icons.visibility_outlined:Icons.visibility_off_outlined
                            )
                          ),
                          errorText: errorText,
                          labelText: "Password",
                        ),
                      ),
                      SizedBox(
                        height: 4
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 5, right: 5),
                        child:  Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: stayLoggedIn,
                                  onChanged: (value) {
                                    setState(() {
                                      stayLoggedIn = value!;
                                    });
                                  },
                                ),
                                Text('Stay logged in', style: TextTheme.of(context).labelMedium),
                              ],
                            ),
                            TextButton(
                              onPressed: (){}, 
                              child: Text('Forgot Password?',
                                style: TextStyle(fontSize: TextTheme.of(context).labelMedium?.fontSize)))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: 40,
                        child: FilledButton.icon(
                          label: Text('Login'),
                          icon: Icon(Icons.chevron_right),
                          onPressed: () {
                            doLogin(context);
                          },
                        ),
                      ),
                      SizedBox(
                        height: 330,
                        child: UnDraw(
                          errorWidget: Container(),
                          color: Theme.of(context).colorScheme.tertiary,
                          illustration: UnDrawIllustration.well_done
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}