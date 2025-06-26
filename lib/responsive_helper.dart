
import 'package:flutter/material.dart';

/// 画面幅とプラットフォームに応じてレスポンシブなフォントサイズを返す関数
///
/// context - BuildContext
/// baseFontSize - デザインの基準となる基本フォントサイズ
double getResponsiveFontSize(BuildContext context, {required double baseFontSize}) {

  // デザインの基準となる画面幅 (例: iPhone 13 Pro)
  const double baseScreenWidth = 390.0;

  // 現在のデバイスの画面幅
  final double screenWidth = MediaQuery.of(context).size.width;

  // 画面幅の比率からスケールファクターを計算
  final double scaleFactor = screenWidth / baseScreenWidth;

  // 基本フォントサイズにスケールを適用
  double responsiveFontSize = baseFontSize * scaleFactor;

  // プラットフォームによる微調整
  final TargetPlatform platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS) {
    // iOSの場合は少し小さく
    responsiveFontSize -= 2.0;
  }

  // フォントサイズが極端に大きくなったり小さくなったりするのを防ぐ
  // 例: 最小12px、最大20pxに制限
  return responsiveFontSize.clamp(12.0, 20.0);
}

double getResponsiveLogoPic(BuildContext context, {required double screenWidth}) {
  if (screenWidth * 0.4 < 180){
    return screenWidth * 0.4;
  }
  return 180;
}