import 'package:flutter/material.dart';

class AnimationExampleScreen extends StatefulWidget {
  const AnimationExampleScreen({super.key});

  @override
  State<AnimationExampleScreen> createState() => _AnimationExampleScreenState();
}

class _AnimationExampleScreenState extends State<AnimationExampleScreen> with SingleTickerProviderStateMixin{
  bool _showYellowContainer = false;

  @override
  void initState() {
    super.initState();
    // Set state after 3 seconds to show yellow container
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _showYellowContainer = true;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Red Container
            Container(
              height: MediaQuery.of(context).size.height /  2,
              color: Colors.red,
            ),
            // Yellow Container with AnimatedPositioned
            AnimatedPositioned(
              duration: Duration(seconds: 1),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: _showYellowContainer ? 0 : -100, // start from bottom and move up
              height: 300,
              child: Container(
                color: Colors.yellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
