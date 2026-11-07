// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildProviderEmbedView({
  Key? key,
  required String url,
  required String viewId,
  VoidCallback? onLoaded,
}) {
  final String viewType = 'provider-frame-$viewId';
  
  try {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int id) {
        final iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true
          ..setAttribute('allow', 'autoplay; fullscreen; encrypted-media');

        iframe.onLoad.listen((_) {
          onLoaded?.call();
        });

        return iframe;
      },
    );
  } catch (_) {
    // If already registered for this viewType, ignore
  }

  return HtmlElementView(key: key, viewType: viewType);
}
