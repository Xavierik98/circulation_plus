import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class AnimatedCounter extends StatefulWidget {
  final int end;
  final int start;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.end,
    this.start = 0,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: widget.start.toDouble(),
      end: widget.end.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.round();
        String display;
        if (value >= 1000000) {
          display = '${(value / 1000000).toStringAsFixed(1)}M';
        } else if (value >= 1000) {
          display = '${(value / 1000).toStringAsFixed(0)}K';
        } else {
          display = value.toString();
        }
        return Text(
          '${widget.prefix ?? ''}$display${widget.suffix ?? ''}',
          style: widget.style ?? AppTextStyles.statNumber,
        );
      },
    );
  }
}
