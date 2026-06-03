// Stub para plataformas não-web
import 'package:flutter/widgets.dart';

Widget buildPlatformImage({
  required String url,
  required Widget placeholder,
  required double width,
  required double height,
}) {
  return Image.network(
    url,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => placeholder,
  );
}
