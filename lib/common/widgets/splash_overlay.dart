import 'package:flutter/material.dart';

import '../constants/constant.dart';

class SplashOverlay extends StatelessWidget {
  const SplashOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Center(
          child: CircleAvatar(
            radius: SWSizes.s80,
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
