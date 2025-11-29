import 'package:flutter/material.dart';

class SchemeShimmerList extends StatelessWidget {
  const SchemeShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => const SchemeShimmerCard(),
    );
  }
}

class SchemeShimmerCard extends StatefulWidget {
  const SchemeShimmerCard({super.key});

  @override
  State<SchemeShimmerCard> createState() => _SchemeShimmerCardState();
}

class _SchemeShimmerCardState extends State<SchemeShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top badges row
              Row(
                children: [
                  _buildShimmerBox(width: 60, height: 24),
                  const SizedBox(width: 8),
                  _buildShimmerBox(width: 70, height: 24),
                  const Spacer(),
                  _buildShimmerBox(width: 50, height: 20),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              _buildShimmerBox(width: double.infinity, height: 20),
              const SizedBox(height: 8),
              _buildShimmerBox(width: 150, height: 14),

              const SizedBox(height: 16),

              // Description
              _buildShimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: 6),
              _buildShimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: 6),
              _buildShimmerBox(width: 200, height: 14),

              const SizedBox(height: 16),

              // Info row
              Row(
                children: [
                  _buildShimmerBox(width: 100, height: 14),
                  const SizedBox(width: 16),
                  _buildShimmerBox(width: 120, height: 14),
                ],
              ),

              const SizedBox(height: 16),

              // Tags
              Row(
                children: [
                  _buildShimmerBox(width: 60, height: 22),
                  const SizedBox(width: 8),
                  _buildShimmerBox(width: 80, height: 22),
                  const SizedBox(width: 8),
                  _buildShimmerBox(width: 50, height: 22),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerBox(width: 80, height: 14),
                    _buildShimmerBox(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: [
            0.0,
            (_animation.value + 2) / 4,
            1.0,
          ],
        ).createShader(bounds);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
