import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/translation_controller.dart';

class TranslatedTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showTranslationIndicator;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const TranslatedTextWidget({
    Key? key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.showTranslationIndicator = true,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<TranslatedTextWidget> createState() => _TranslatedTextWidgetState();
}

class _TranslatedTextWidgetState extends State<TranslatedTextWidget> {
  String? _translatedText;
  bool _isTranslating = false;
  bool _translationError = false;

  @override
  void initState() {
    super.initState();
    _translateText();
  }

  @override
  void didUpdateWidget(TranslatedTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translateText();
    }
  }

  Future<void> _translateText() async {
    if (!mounted || widget.text.trim().isEmpty) return;

    final translationController = context.read<TranslationController>();
    
    // Check if auto-translate is enabled
    if (!translationController.autoTranslate) {
      setState(() {
        _translatedText = null;
        _isTranslating = false;
        _translationError = false;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _translationError = false;
    });

    try {
      final translated = await translationController.autoTranslateIfNeeded(widget.text);
      if (mounted) {
        setState(() {
          _translatedText = translated != widget.text ? translated : null;
          _isTranslating = false;
          _translationError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translationError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationController>(
      builder: (context, translationController, child) {
        // If auto-translate is disabled, show original text
        if (!translationController.autoTranslate) {
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          );
        }

        // Show loading state
        if (_isTranslating) {
          return widget.loadingWidget ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.style?.color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: widget.style?.copyWith(
                        color: (widget.style?.color ?? Theme.of(context).textTheme.bodyLarge?.color)
                            ?.withOpacity(0.6),
                      ),
                      textAlign: widget.textAlign,
                      maxLines: widget.maxLines,
                      overflow: widget.overflow,
                    ),
                  ),
                ],
              );
        }

        // Show error state
        if (_translationError) {
          return widget.errorWidget ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: widget.style,
                      textAlign: widget.textAlign,
                      maxLines: widget.maxLines,
                      overflow: widget.overflow,
                    ),
                  ),
                ],
              );
        }

        // Show translated text
        final displayText = _translatedText ?? widget.text;
        final isTranslated = _translatedText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayText,
              style: widget.style?.copyWith(
                color: isTranslated && widget.showTranslationIndicator
                    ? (widget.style?.color ?? Theme.of(context).textTheme.bodyLarge?.color)
                        ?.withOpacity(0.8)
                    : widget.style?.color,
                fontStyle: isTranslated && widget.showTranslationIndicator
                    ? FontStyle.italic
                    : widget.style?.fontStyle,
              ),
              textAlign: widget.textAlign,
              maxLines: widget.maxLines,
              overflow: widget.overflow,
            ),
            if (isTranslated && widget.showTranslationIndicator) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.translate,
                    size: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Translated',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _translatedText = null;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Simple translated text widget without indicators
class SimpleTranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SimpleTranslatedText({
    Key? key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationController>(
      builder: (context, translationController, child) {
        return FutureBuilder<String>(
          future: translationController.autoTranslateIfNeeded(text),
          builder: (context, snapshot) {
            final displayText = snapshot.data ?? text;
            final isTranslated = snapshot.hasData && snapshot.data != text;

            return Text(
              displayText,
              style: style?.copyWith(
                fontStyle: isTranslated ? FontStyle.italic : style?.fontStyle,
              ),
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
            );
          },
        );
      },
    );
  }
}