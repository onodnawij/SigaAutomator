import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:siga/providers/about_provider.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((timestamp) async {
      ref.read(aboutMarkdown.notifier).state = await DefaultAssetBundle.of(context).loadString('assets/about.md');
    });
    
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: SafeArea(
        child: Markdown(
          data: ref.watch(aboutMarkdown),
          padding: const EdgeInsets.all(10),
        )
      ),
    );
  }
}