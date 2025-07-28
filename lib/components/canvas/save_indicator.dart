import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/i18n/strings.g.dart';

/// Replaces the back button as the
/// [AppBar.leading] widget in the [AppBar]
/// to indicate the state of saving in the editor.
class SaveIndicator extends StatelessWidget {
  const SaveIndicator({
    super.key,
    required this.savingState,
    required this.triggerSave,
  });

  final ValueNotifier<SavingState> savingState;
  final VoidCallback triggerSave;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: savingState,
      builder: (context, isSaving, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            key: ValueKey(savingState.value),
            onPressed: () => _onPressed(context),
            icon: switch (savingState.value) {
              SavingState.waitingToSave => const Icon(Icons.save),
              SavingState.saving => const CircularProgressIndicator.adaptive(),
              SavingState.saved => const Icon(Icons.arrow_back),
            },
          ),
        );
      },
    );
  }

  void _onPressed(BuildContext context) {
    switch (savingState.value) {
      case SavingState.waitingToSave:
        if (kIsWeb) {
          _showWebSaveDialog(context);
        } else {
          triggerSave();
        }
      case SavingState.saving:
        break;
      case SavingState.saved:
        _back(context);
    }
  }

  void _showWebSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Saving Not Supported'),
          content: const Text(
            'Saving is not supported on the web version. Please download the app to have access to all features. Work will not be saved if you leave.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Go back to home - use a post-frame callback to ensure dialog is closed first
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Navigate from the parent context
                  context.go(HomeRoutes.getRoute(0));
                });
              },
              child: const Text('Go Back to Home'),
            ),
          ],
        );
      },
    );
  }

  void _back(BuildContext context) {
    final navigator = Navigator.of(context);
    final isWhiteboard = !navigator.canPop();
    if (isWhiteboard) {
      // if on whiteboard, go to "recents" tab of home screen
      context.go(HomeRoutes.getRoute(0));
    } else {
      navigator.pop();
    }
  }
}

enum SavingState {
  waitingToSave,
  saving,
  saved,
}
