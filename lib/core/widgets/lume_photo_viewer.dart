import 'dart:io';

import 'package:flutter/material.dart';

/// Opens a private, local photo without exposing the Storage URL or loading
/// the original image into a collection row.
Future<void> showLumePhotoViewer(
  BuildContext context, {
  required String path,
  required String semanticLabel,
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .92),
  builder: (context) => Dialog.fullscreen(
    backgroundColor: Colors.transparent,
    child: SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: InteractiveViewer(
              minScale: .8,
              maxScale: 4,
              child: Semantics(
                image: true,
                label: semanticLabel,
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Esta imagem não está disponível neste dispositivo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: 'Fechar imagem',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: .45),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  ),
);
