import 'package:flutter/material.dart';

class UIUtils {
  static Color parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.tryParse('0x$hexColor') ?? 0xFF000000);
  }

  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'local_hospital': return Icons.local_hospital;
      case 'fastfood': return Icons.fastfood;
      case 'checkroom': return Icons.checkroom;
      case 'directions_bus': return Icons.directions_bus;
      case 'directions_car': return Icons.directions_car;
      case 'store': return Icons.store;
      case 'home': return Icons.home;
      case 'clean_hands': return Icons.clean_hands;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'restaurant': return Icons.restaurant;
      case 'movie': return Icons.movie;
      default: return Icons.category;
    }
  }
}