// المسار: lib/core/widgets/shimmer_widget.dart

import 'package:flutter/material.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          // Base background
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          // Shimmer effect
          Positioned.fill(
            child: ShimmerEffect(borderRadius: borderRadius),
          ),
        ],
      ),
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final double borderRadius;

  const ShimmerEffect({super.key, this.borderRadius = 8});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;

  _SlidingGradientTransform(this.percent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * 2 * (percent - 0.5);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

// Shimmer for chat list items
class ChatShimmerItem extends StatelessWidget {
  const ChatShimmerItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar shimmer
          const ShimmerWidget(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 12),
          // Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget(width: 120, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                const ShimmerWidget(width: 200, height: 14, borderRadius: 4),
                const SizedBox(height: 6),
                ShimmerWidget(
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                  margin: const EdgeInsets.only(top: 4),
                ),
              ],
            ),
          ),
          // Time shimmer
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerWidget(width: 40, height: 12, borderRadius: 4),
              SizedBox(height: 8),
              ShimmerWidget(width: 20, height: 20, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

// Shimmer for multiple chat items
class ChatListShimmer extends StatelessWidget {
  final int itemCount;

  const ChatListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: const ChatShimmerItem(),
        );
      },
    );
  }
}