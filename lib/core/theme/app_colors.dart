import 'package:flutter/material.dart';
import 'package:catppuccin_flutter/catppuccin_flutter.dart';

/// App color palette with both light and dark theme support
/// Designed for a friendly, accessible charity app experience
class AppColors {
  // ============ LIGHT THEME COLORS (Latte) ============
  
  // Backgrounds
  static Color lightBackground = catppuccin.latte.base; 
  static Color lightSurface = catppuccin.latte.surface0; 
  static Color lightCard = catppuccin.latte.surface1; 
  
  // Text
  static Color lightTextPrimary = catppuccin.latte.text; 
  static Color lightTextSecondary = catppuccin.latte.subtext0; 
  static Color lightTextTertiary = catppuccin.latte.overlay0; 
  
  // ============ DARK THEME COLORS (Mocha) ============
  
  // Backgrounds
  static Color deepCharcoal = catppuccin.mocha.base; 
  static Color lighterGraphite = catppuccin.mocha.surface0; 
  static Color darkCard = catppuccin.mocha.surface1; 
  
  // Text
  static Color white = catppuccin.mocha.text;
  static Color darkCharcoalText = catppuccin.latte.text; // Keep dark text for light cards if needed
  
  // ============ ACCENT COLORS (Theme-independent) ============
  
  // Primary accents - Mapped to Catppuccin colors
  static Color coralOrange = catppuccin.latte.peach; 
  static Color skyBlue = catppuccin.latte.blue; 
  static Color freshGreen = catppuccin.latte.green; 
  static Color sunshineYellow = catppuccin.latte.yellow; 
  
  // Legacy accent colors (kept for compatibility)
  static Color salmonOrange = coralOrange; // Alias
  static Color periwinkleBlue = skyBlue; // Alias
  static Color mintGreen = freshGreen; // Alias
  static Color mutedMustard = sunshineYellow; // Alias
  
  // Semantic colors
  static Color success = catppuccin.latte.green;
  static Color warning = catppuccin.latte.yellow;
  static Color error = catppuccin.latte.red;
  static Color info = catppuccin.latte.blue;
  
  // Special colors
  static const Color transparent = Colors.transparent;
  
  // ============ CONTEXT-AWARE GETTERS ============
  
  /// Get background color based on brightness
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? deepCharcoal
        : lightBackground;
  }
  
  /// Get surface/card color based on brightness
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? lighterGraphite
        : lightSurface;
  }
  
  /// Get card color based on brightness
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? lighterGraphite
        : lightCard;
  }
  
  /// Get primary text color based on brightness
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? white
        : lightTextPrimary;
  }
  
  /// Get secondary text color based on brightness
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? catppuccin.mocha.subtext0
        : lightTextSecondary;
  }
  
  /// Get tertiary text color based on brightness
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? catppuccin.mocha.overlay0
        : lightTextTertiary;
  }
  
  /// Get divider color based on brightness
  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? catppuccin.mocha.surface2
        : catppuccin.latte.surface2;
  }
  
  
  /// Get input background color based on brightness
  static Color getInputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? deepCharcoal
        : lightCard;
  }
  
  /// Get overlay color for hover/pressed states
  static Color getOverlay(BuildContext context, {double opacity = 0.05}) {
    return Theme.of(context).brightness == Brightness.dark
        ? white.withOpacity(opacity)
        : lightTextPrimary.withOpacity(opacity);
  }
}
