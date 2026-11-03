import 'package:flutter/material.dart';

abstract final class AppColors {
  // Northfield V2 Light Tokens
  static const primary = Color(0xFF5452C8);
  static const primarySoft = Color(0xFFEDEEFC);
  static const bg = Color(0xFFF7F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFF0F1F6);
  static const border = Color(0xFFE6E7F0);
  static const ink = Color(0xFF1E1D2E);
  static const muted = Color(0xFF626078);

  // Northfield V2 Dark Tokens
  static const darkPrimary = Color(0xFF7C7BF2);
  static const darkPrimarySoft = Color(0xFF262445);
  static const darkBg = Color(0xFF17161F);
  static const darkSurface = Color(0xFF201F2C);
  static const darkSunken = Color(0xFF282638);
  static const darkBorder = Color(0x14FFFFFF);
  static const darkInk = Color(0xFFF2F1F8);
  static const darkMuted = Color(0xFF9E9CB6);

  // Module Pastels (Light / Dark)
  static const lav = Color(0xFFF2EFFD);
  static const lavInk = Color(0xFF6B5ECC);
  static const darkLav = Color(0xFF2E294A);
  static const darkLavInk = Color(0xFFD5CCFF);

  static const mint = Color(0xFFE8F8F2);
  static const mintInk = Color(0xFF1A8E63);
  static const darkMint = Color(0xFF19382B);
  static const darkMintInk = Color(0xFF9DE3C4);

  static const peach = Color(0xFFFFEDE5);
  static const peachInk = Color(0xFFD9653B);
  static const darkPeach = Color(0xFF3D241C);
  static const darkPeachInk = Color(0xFFFFBDA6);

  static const butter = Color(0xFFFEF5DB);
  static const butterInk = Color(0xFFB8860B);
  static const darkButter = Color(0xFF3B3218);
  static const darkButterInk = Color(0xFFFFE599);

  static const rose = Color(0xFFFDEBEE);
  static const roseInk = Color(0xFFD83A52);
  static const darkRose = Color(0xFF3D1B24);
  static const darkRoseInk = Color(0xFFFFB3BE);

  static const sky = Color(0xFFE7F3FC);
  static const skyInk = Color(0xFF258BD2);
  static const darkSky = Color(0xFF192E40);
  static const darkSkyInk = Color(0xFFA5D8FF);

  // Status tokens
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFEAF7F0);
  static const successInk = Color(0xFF13795B);

  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF6E4);
  static const warningInk = Color(0xFFA16207);

  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFDEBED);
  static const dangerInk = Color(0xFFB91C1C);

  // Status text aliases
  static const successText = successInk;
  static const warningText = warningInk;
  static const dangerText = dangerInk;

  // Info tokens
  static const info = Color(0xFF0EA5E9);
  static const infoBg = sky;
  static const infoText = skyInk;

  // Convenience & Backward-compatible aliases
  static const accent = primary;
  static const primaryAlt = Color(0xFF6B5ECC);
  static const text = ink;
  static const textMuted = muted;
  static const surfaceAlt = sunken;
  static const darkText = darkInk;
  static const darkTextMuted = darkMuted;
  static const darkSurfaceAlt = darkSunken;
  static const dangerBorder = Color(0xFFFCA5A5);

  // Gradients
  static const auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5452C8), Color(0xFF6B5ECC), Color(0xFF7C7BF2)],
  );

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5452C8), Color(0xFF7C7BF2)],
  );

  static const teacherHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1D2E), Color(0xFF383556)],
  );

  static const adminHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B2844), Color(0xFF5452C8)],
  );

  static const accountantHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF19382B), Color(0xFF1A8E63)],
  );

  static const parentHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5452C8), Color(0xFF6B5ECC)],
  );
}
