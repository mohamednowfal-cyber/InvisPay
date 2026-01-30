import 'package:flutter/material.dart';
import 'package:invispay/core/i18n/app_localizations.dart';
export 'package:invispay/core/i18n/app_localizations.dart';

/// A widget that automatically builds localized text with a smooth
/// cross-fade + micro-slide animation when the language changes.
class AnimatedLocalize extends StatelessWidget {
  final String Function(AppLocalizations) text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool animate;
  final bool useFittedBox;
  final bool? softWrap;

  const AnimatedLocalize({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.animate = true,
    this.useFittedBox = false,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    final localizedString = text(AppLocalizations.of(context));

    // Check for system "Reduce Motion" setting
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    final textWidget = Text(
      localizedString,
      key: ValueKey<String>(localizedString),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap ?? (useFittedBox ? false : null),
    );

    final finalWidget = useFittedBox
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: _getAlignment(textAlign),
            child: textWidget,
          )
        : textWidget;

    if (!animate || reduceMotion) {
      return finalWidget;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: _getAlignment(textAlign),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isEntering = child.key == ValueKey<String>(localizedString);

          final slideAnimation = Tween<Offset>(
            begin:
                isEntering ? const Offset(0.0, 0.08) : const Offset(0.0, -0.04),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: _getAlignment(textAlign),
            children: <Widget>[
              ...previousChildren.map((child) => Opacity(
                  opacity: 0.0, child: child)), // Keep for layout stability
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: finalWidget,
      ),
    );
  }

  Alignment _getAlignment(TextAlign? textAlign) {
    if (textAlign == null) {
      return AlignmentDirectional.centerStart.resolve(TextDirection.ltr);
    }
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return Alignment.centerLeft;
    }
  }
}
