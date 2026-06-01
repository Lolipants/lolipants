import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/assets/catalog_image_uri.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';

/// Loads a catalogue image from bundled assets (preferred) or R2 when configured.
class CatalogImage extends StatefulWidget {
  const CatalogImage({
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorWidget,
    super.key,
  });

  /// Bundled `assets/images/...` path or remote URL.
  final String path;

  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? errorWidget;

  @override
  State<CatalogImage> createState() => _CatalogImageState();
}

class _CatalogImageState extends State<CatalogImage> {
  int _urlIndex = 0;
  late List<String> _networkUrls;

  @override
  void initState() {
    super.initState();
    _resetUrls(widget.path);
  }

  @override
  void didUpdateWidget(CatalogImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _resetUrls(widget.path);
    }
  }

  void _resetUrls(String path) {
    _urlIndex = 0;
    _networkUrls = _networkCandidatesFor(path);
  }

  /// Primary CDN URL plus optional `_look_` fallback when flat-lay 404s.
  static List<String> _networkCandidatesFor(String pathOrUrl) {
    if (!useRemoteCatalogAssets) return const [];

    final urls = <String>[];
    void addPath(String candidate) {
      final url = catalogImageNetworkUrl(candidate);
      if (url != null && !urls.contains(url)) {
        urls.add(url);
      }
    }

    addPath(pathOrUrl);
    final fallback = catalogLookRenderFallbackPath(pathOrUrl);
    if (fallback != null) {
      addPath(fallback);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final bundled = bundledCatalogAssetPath(widget.path);
    if (bundled != null && !useRemoteCatalogAssets) {
      return Image.asset(
        bundled,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (_, __, ___) => _buildRemoteOrLocal(widget.path),
      );
    }

    return _buildRemoteOrLocal(widget.path);
  }

  Widget _buildRemoteOrLocal(String originalPath) {
    if (_networkUrls.isNotEmpty) {
      final url = _networkUrls[_urlIndex.clamp(0, _networkUrls.length - 1)];
      return CachedNetworkImage(
        key: ValueKey<String>(url),
        imageUrl: url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) {
          if (_urlIndex + 1 < _networkUrls.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _urlIndex++);
            });
            return _placeholder();
          }
          return widget.errorWidget ?? _defaultError();
        },
      );
    }

    return _buildLocalFile(originalPath);
  }

  Widget _buildLocalFile(String localPath) {
    if (localPath.startsWith('/') || localPath.contains(':\\')) {
      return Image.file(
        File(localPath),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (_, __, ___) => widget.errorWidget ?? _defaultError(),
      );
    }

    return widget.errorWidget ?? _defaultError();
  }

  Widget _placeholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.stone.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.borderSubtle,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.gold),
    );
  }
}
