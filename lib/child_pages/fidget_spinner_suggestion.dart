import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';


class FidgetSpinnerHome extends StatefulWidget {
  @override
  _FidgetSpinnerHomeState createState() => _FidgetSpinnerHomeState();
}


class _FidgetSpinnerHomeState extends State<FidgetSpinnerHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  AudioPlayer player = AudioPlayer();
  double _rotationSpeed = 0;
  double _currentAngle = 0; // Keep track of the current rotation angle
  double _friction = 0.003;
  double _threshold = 0.00001;


  @override
  void initState() {
    super.initState();
    // player.play(AssetSource('sound_effects/spinning-fidget-spinner-23292.mp3'));
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16), // Faster updates
    )..addListener(() {
      setState(() {

        if (_rotationSpeed.abs() > _threshold){
          if (_rotationSpeed > 0) {
            _rotationSpeed -= _friction;
            if (_rotationSpeed < 0) _rotationSpeed = 0; // Stop at zero
          }
          if (_rotationSpeed < 0){
            _rotationSpeed += _friction;
            if (_rotationSpeed > 0){
              _rotationSpeed = 0;
            }; // Stop at zero
          }
        }
        print(_rotationSpeed);
        player.setPlaybackRate(_rotationSpeed);
        _currentAngle -= _rotationSpeed;
      });
    });
    _controller.repeat(); // Continuously update the animation
  }


  void playSound() {
    player.setPlaybackRate(_rotationSpeed);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Handle pointer (mouse) drag using Listener
  void _spinFidgetSpinnerPointer(PointerMoveEvent event) {
    setState(() {
      // Increase the spin speed based on the mouse or touch delta
      _rotationSpeed += sqrt(event.delta.dx * event.delta.dx + event.delta.dy * event.delta.dy) * 0.005; // Use dx for horizontal drag
      sqrt(event.delta.dx * event.delta.dx + event.delta.dy * event.delta.dy);
      if (_rotationSpeed > 1) _rotationSpeed = 1; // Cap the speed for control
    });
  }

  // Handle touch drag
  void _spinFidgetSpinnerTouch(DragUpdateDetails details) {
    setState(() {
      if (details.primaryDelta != null) {
        // Adjust the speed relative to the drag amount (fine-tune as needed)
        _rotationSpeed += sqrt(details.delta.dx * details.delta.dx + details.delta.dy * details.delta.dy) * 0.005;
        if (_rotationSpeed > 1) _rotationSpeed = 1; // Cap the speed for control
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fidget Spinner Simulator'),
        centerTitle: true,
      ),
      body: Center(
        child: GestureDetector(
          onPanUpdate: _spinFidgetSpinnerTouch, // Handle touch drag
          child: MouseRegion(
            onEnter: (_) {
              // Optional: Handle mouse enter to give visual feedback
            },
            child: Listener(
              onPointerMove: _spinFidgetSpinnerPointer, // Handle mouse drag
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _currentAngle,
                    child: child,
                  );
                },
                child: Container(
                  height: 350,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/imgs/final_spinner.png'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
