import 'package:flutter/material.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/pages/home/settings.dart';

class SettingsInputField extends StatefulWidget {
  const SettingsInputField({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.pref,
    this.afterChange,
    this.obscureText = false,
    this.hintText,
    this.warningText,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final IPref<String> pref;
  final ValueChanged<String>? afterChange;
  final bool obscureText;
  final String? hintText;
  final String? warningText;

  @override
  State<SettingsInputField> createState() => _SettingsInputFieldState();
}

class _SettingsInputFieldState extends State<SettingsInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.pref.value);
    widget.pref.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    if (_controller.text != widget.pref.value) {
      _controller.text = widget.pref.value;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onLongPress: () {
        SettingsPage.showResetDialog(
          context: context,
          pref: widget.pref,
          prefTitle: widget.title,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              widget.pref.value != widget.pref.defaultValue
                                  ? FontStyle.italic
                                  : null,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: widget.obscureText,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                widget.pref.value = value;
                widget.afterChange?.call(value);
              },
            ),
            if (widget.warningText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.warningText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.pref.removeListener(onChanged);
    super.dispose();
  }
}
