import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavUtils {
  static int getCurrentIndex(String location) {
    if (location == '/' || location == '/home') return 0;
    if (location == '/search') return 1;
    if (location == '/create-article') return 2;
    if (location == '/list') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  static void onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.push('/search');
        break;
      case 2:
        context.push('/create-article');
        break;
      case 3:
        context.push('/list');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}