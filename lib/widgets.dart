import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:universal_html/html.dart' as html;

import 'package:zapdart/colors.dart';

import 'config.dart' as cfg;

class SpacedVisibility extends StatelessWidget {
  // Visibility widget with VerticalSpacer placed above child Widget in Column
  // Intention is to space out BronzeFormInput widgets on certain pages
  final Widget child;
  final bool visible;
  SpacedVisibility(this.visible, this.child);

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: this.visible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[VerticalSpacer(), this.child],
      ),
    );
  }
}

class VerticalSpacer extends StatelessWidget {
  final double height;
  VerticalSpacer({this.height = 15});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class BronzeFormInput extends StatefulWidget {
  final TextEditingController? controller;
  final FormFieldValidator<dynamic>? validator;
  final String? labelText;
  final bool? obscureText;
  final bool? toggleObscure;
  final Icon? icon;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? suffixText;
  final void Function(String?)? onChanged;

  BronzeFormInput(this.controller,
      {this.validator,
      this.labelText,
      this.obscureText,
      this.toggleObscure,
      this.icon,
      this.keyboardType,
      this.suffixIcon,
      this.suffixText,
      this.onChanged})
      : super();

  @override
  State<BronzeFormInput> createState() => _BronzeFormInputState();
}

class _BronzeFormInputState extends State<BronzeFormInput> {
  bool obscureText = false;
  Widget? suffixIcon;

  @override
  void initState() {
    super.initState();

    if (widget.toggleObscure == true &&
        (widget.suffixIcon != null || widget.suffixText != null))
      throw Exception(
          'if "toggleObscureBtn" we cannot have a "suffixIcon" or "suffixText"');
    if (widget.obscureText == true) obscureText = true;
    if (widget.suffixIcon != null) suffixIcon = widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.toggleObscure == true)
      suffixIcon = IconButton(
          onPressed: () {
            setState(() {
              obscureText = !obscureText;
            });
          },
          icon: Icon(
              obscureText == true ? Icons.visibility : Icons.visibility_off),
          tooltip: 'Show text');
    return TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          prefixIcon: widget.icon == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: widget.icon,
                ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 25.0),
          fillColor: Color(0xFFFFFFFF).withOpacity(0.1),
          filled: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelText: widget.labelText ?? null,
          suffixText: widget.suffixText,
          constraints: BoxConstraints(
              minWidth: cfg.ButtonWidth, maxWidth: cfg.ButtonWidth),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(
              width: 0,
              style: BorderStyle.none,
            ),
          ),
        ),
        keyboardType: widget.keyboardType,
        obscureText: obscureText,
        validator: widget.validator,
        onChanged: widget.onChanged);
  }
}

class BronzeValueInput extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<dynamic>? validator;
  final String? labelText;
  final String? suffixText;
  final bool? readOnly;
  final Function(String)? onChanged;

  BronzeValueInput(
      {this.controller,
      this.labelText,
      this.keyboardType,
      this.validator,
      this.readOnly,
      this.suffixText,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return RoundedEdgeBox(
        borderColor: Colors.white,
        dottedBorder: true,
        color: ZapSurface,
        child: TextFormField(
          controller: this.controller,
          readOnly: this.readOnly ?? false,
          decoration: InputDecoration(
              suffixText: this.suffixText,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              labelText: this.labelText),
          keyboardType: this.keyboardType,
          validator: this.validator,
          onChanged: onChanged,
        ));
  }
}

class BackgroundWebImage extends StatelessWidget {
  final Widget? child;
  late final String? imageSrc;

  BackgroundWebImage({this.child}) {
    imageSrc = extractUrl();
  }

  String? extractUrl() {
    // extract url from parent page. if we are an app we would need to do this differently
    if (UniversalPlatform.isWeb) {
      var backgroundDiv = html.document.getElementById('background');
      if (backgroundDiv != null) {
        var backgroundImage = backgroundDiv.style.backgroundImage;
        var res = RegExp(r'url\(\"(.*)\"\)').firstMatch(backgroundImage);
        if (res != null) {
          var path = html.window.location.pathname ?? '/';
          if (path.endsWith('/')) // if only '/' or breaks the spec '/path/'
            path = path.substring(0, path.length - 1); // remove last character
          return '${html.window.location.origin}${path}/${res.group(1)}';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (imageSrc == null) return Container(child: child);
    return Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
            image: DecorationImage(
                image: NetworkImage(imageSrc!), fit: BoxFit.cover)),
        child: Container(
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(color: ZapBackground.withAlpha(220)),
            child: child));
  }
}

class ColumnView extends StatelessWidget {
  final Widget? child;
  final bool scrollChild;
  ColumnView({this.child, this.scrollChild = false});

  @override
  Widget build(BuildContext context) {
    var center = Center(
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cfg.MaxColumnWidth),
            child: child));
    if (scrollChild) return SingleChildScrollView(child: center);
    return center;
  }
}

class BiforgePage extends StatelessWidget {
  final Widget? child;
  final bool scrollChild;
  final bool showDebugInfo;
  BiforgePage(
      {this.child, this.scrollChild = false, this.showDebugInfo = false});

  @override
  Widget build(BuildContext context) {
    Widget column;
    if (showDebugInfo)
      column = Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            ColumnView(child: child),
            Align(alignment: Alignment.bottomRight, child: DebugInfo())
          ]);
    else
      column = ColumnView(child: child);
    return BackgroundWebImage(
        child: scrollChild
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: column)))
            : column);
  }
}

class RoundedEdgeBox extends StatelessWidget {
  final Widget? child;
  final Gradient? gradient;
  final Color? color;
  final double borderRadius;
  final bool dottedBorder;
  final double borderWidth;
  final Color? borderColor;
  final EdgeInsets padding;

  RoundedEdgeBox(
      {this.child,
      this.gradient,
      this.color,
      this.borderRadius = 10,
      this.dottedBorder = false,
      this.borderWidth = 2,
      this.borderColor,
      this.padding = const EdgeInsets.all(8)});

  Widget _dbox({bool drawBorder: false}) {
    return DecoratedBox(
        decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            border: drawBorder
                ? Border.all(
                    color: borderColor ?? Colors.black, width: borderWidth)
                : null,
            borderRadius: BorderRadius.circular(borderRadius)),
        child: Padding(padding: padding, child: child));
  }

  @override
  Widget build(BuildContext context) {
    if (dottedBorder)
      return DottedBorder(
          padding: EdgeInsets.zero,
          borderType: BorderType.RRect,
          strokeWidth: borderWidth,
          radius: Radius.circular(borderRadius),
          color: borderColor ?? Colors.black,
          child: _dbox(drawBorder: false));
    return _dbox(drawBorder: true);
  }
}

class BigLogoContainer extends StatelessWidget {
  final List<Widget>? children;
  BigLogoContainer({this.children});

  @override
  Widget build(BuildContext context) {
    var kids = List<Widget>.from(children ?? []);
    kids.insert(
        0,
        Padding(
            padding: EdgeInsets.all(50),
            child: Image.asset('assets/new-logo.png',
                filterQuality: FilterQuality.high)));
    return Container(
        padding: EdgeInsets.all(20),
        child: Center(child: Column(children: kids)));
  }
}

class DebugInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Visibility(
        visible: cfg.testnet(),
        child:
            Text('TESTNET', style: TextStyle(color: ZapWarning, fontSize: 8)),
      ),
      Text('Server: ${cfg.server()}',
          style: TextStyle(color: ZapOnBackgroundLight, fontSize: 8)),
      Visibility(
          visible: cfg.GitSha != 'GIT_SHA_REPLACE',
          child: Text('Build: ${cfg.GitSha.substring(0, 5)} - ${cfg.BuildDate}',
              style: TextStyle(color: ZapOnBackgroundLight, fontSize: 8)))
    ]);
  }
}

class WordDivider extends StatelessWidget {
  final String word;
  final Color color;
  final double lineLength;
  final double lineThickness;
  final double lineHeight;

  const WordDivider(
      {this.word = ' OR ',
      this.color = Colors.white,
      this.lineLength = 140,
      this.lineHeight = 4,
      this.lineThickness = 2});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
            width: lineLength,
            child: Divider(
                height: lineHeight, color: color, thickness: lineThickness)),
        Text(word, style: TextStyle(color: color)),
        SizedBox(
            width: lineLength,
            child: Divider(
                height: lineHeight, color: color, thickness: lineThickness))
      ],
    );
  }
}

class BronzeRoundedButton extends StatelessWidget {
  BronzeRoundedButton(this.onPressed, this.textColor, this.fillColor,
      this.fillGradient, this.title,
      {this.icon,
      this.borderColor,
      this.width = 88,
      this.height = 35,
      this.fwdArrow = false})
      : super();

  final VoidCallback onPressed;
  final Color textColor;
  final Color fillColor;
  final Gradient? fillGradient;
  final String title;
  final IconData? icon;
  final Color? borderColor;
  final double width;
  final double height;
  final bool fwdArrow;

  @override
  Widget build(BuildContext context) {
    var radius = BorderRadius.circular(40.0);
    var buttonStyle = ElevatedButton.styleFrom(
        primary: fillGradient == null ? fillColor : Colors.transparent,
        side: fillGradient == null
            ? BorderSide(color: borderColor != null ? borderColor! : fillColor)
            : null,
        shape: RoundedRectangleBorder(borderRadius: radius),
        shadowColor: Colors.transparent);
    var decoration = BoxDecoration(
      color: fillColor,
      border: borderColor != null ? Border.all(color: borderColor!) : null,
      gradient: fillGradient,
      borderRadius: radius,
      boxShadow: kElevationToShadow[3],
    );
    var text = Text(title, style: TextStyle(color: textColor, fontSize: 14));
    Widget btn;
    if (icon != null && fwdArrow)
      throw ArgumentError('Can only use "icon" parameter OR "fwdArrow"');
    if (icon != null) {
      var row = Row(
          children: [
            Icon(icon, color: textColor, size: 12),
            SizedBox(width: 8),
            text
          ],
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center);
      btn = Container(
          width: width,
          height: height,
          margin: EdgeInsets.all(5),
          child: DecoratedBox(
              decoration: decoration,
              child: ElevatedButton(
                  onPressed: onPressed, child: row, style: buttonStyle)));
    } else {
      btn = Container(
          width: width,
          height: height,
          margin: EdgeInsets.all(5),
          child: DecoratedBox(
              decoration: decoration,
              child: ElevatedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: fwdArrow
                      ? <Widget>[
                          text,
                          Icon(Icons.arrow_forward_ios, size: 15.0),
                        ]
                      : <Widget>[
                          text,
                        ],
                ),
              )));
    }
    return btn;
  }
}
