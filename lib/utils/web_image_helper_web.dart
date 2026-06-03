// Implementação web — usa <div> com background-image CSS (sem CORS)
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Widget buildPlatformImage({
  required String url,
  required Widget placeholder,
  required double width,
  required double height,
}) {
  final viewId = 'web_img_${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
    return html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundImage = 'url("$url")'
      ..style.backgroundSize = 'cover'
      ..style.backgroundPosition = 'center'
      ..style.backgroundRepeat = 'no-repeat';
  });
  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewId),
  );
}
