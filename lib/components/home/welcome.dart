import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  bool _showWebPopup = false;

  @override
  void initState() {
    super.initState();
    // Show popup only on web platform
    if (kIsWeb) {
      // Delay the popup to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showWebPopup = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/undraw_learning_sketching_nd4f.svg',
                  width: 300,
                  height: 188,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 64),
                Text(t.home.welcome, style: textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(t.home.createNewNote, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        // Web-only popup overlay
        if (_showWebPopup && kIsWeb) _buildWebPopup(context),
      ],
    );
  }

  Widget _buildWebPopup(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Web Version Notice',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SolveNote is meant to be used on mobile. The web version is meant to be a quick way to try out SolveNote. Many features such as saving, settings and even some UI elements may not work/render properly. \n\nYou can find the apk for SolveNote on the Github Repo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showWebPopup = false;
                        });
                      },
                      child: const Text('Got it'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final Uri url = Uri.parse(
                            'https://github.com/changkevin51/SolveNote');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                        setState(() {
                          _showWebPopup = false;
                        });
                      },
                      child: const Text('GitHub Repository'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
