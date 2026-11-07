import 'package:flutter/material.dart';

Widget buildProviderEmbedView({
  Key? key,
  required String url,
  required String viewId,
  VoidCallback? onLoaded,
}) {
  return Center(
    key: key,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.open_in_browser, size: 50, color: Color(0xFF21D6B5)),
        const SizedBox(height: 16),
        const Text(
          'Mobile Native Mode',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          url,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
