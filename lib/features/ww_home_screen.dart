import 'package:flutter/material.dart';
import 'package:ww_open_test/features/part_1/screen/draw_app_screen.dart';
import 'package:ww_open_test/features/part_2/screen/animation_example_screen.dart';

class WWHomeScreen extends StatelessWidget {
  const WWHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DrawAppScreen())),
              child: const Text("Part 1"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AnimationExampleScreen())),
                child: const Text("Part 2"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
