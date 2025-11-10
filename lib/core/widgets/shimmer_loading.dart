// المسار: lib/core/widgets/shimmer_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../resources/manager_colors.dart';
import '../resources/manager_height.dart';
import '../resources/manager_width.dart';

class ShimmerLoading {
  // ================================
  // ✅ 1. CHAT LIST SHIMMER
  // ================================
  static Widget chatListShimmer(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(ManagerWidth.w16),
      itemCount: 8,
      separatorBuilder: (_, __) => SizedBox(height: ManagerHeight.h12),
      itemBuilder: (context, index) => _chatItemShimmer(),
    );
  }

  static Widget _chatItemShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: EdgeInsets.all(ManagerWidth.w12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: ManagerWidth.w12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  SizedBox(height: ManagerHeight.h8),
                  Container(
                    width: 200,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 50,
                  height: 12,
                  color: Colors.white,
                ),
                SizedBox(height: ManagerHeight.h8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // ✅ 2. MESSAGE LIST SHIMMER
  // ================================
  static Widget messageListShimmer(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(ManagerWidth.w16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isMine = index % 3 == 0;
        return _messageItemShimmer(isMine);
      },
    );
  }

  static Widget _messageItemShimmer(bool isMine) {
    return Padding(
      padding: EdgeInsets.only(bottom: ManagerHeight.h12),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 200,
            padding: EdgeInsets.all(ManagerWidth.w12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
                SizedBox(height: ManagerHeight.h6),
                Container(
                  width: 150,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================
  // ✅ 3. GROUP MEMBERS SHIMMER
  // ================================
  static Widget groupMembersShimmer() {
    return ListView.separated(
      padding: EdgeInsets.all(ManagerWidth.w16),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: ManagerHeight.h12),
      itemBuilder: (context, index) => _memberItemShimmer(),
    );
  }

  static Widget _memberItemShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ManagerWidth.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
                SizedBox(height: ManagerHeight.h6),
                Container(
                  width: 120,
                  height: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================
  // ✅ 4. IMAGE SHIMMER
  // ================================
  static Widget imageShimmer({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ================================
  // ✅ 5. CIRCULAR SHIMMER
  // ================================
  static Widget circularShimmer({double size = 50}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ================================
  // ✅ 6. TEXT SHIMMER
  // ================================
  static Widget textShimmer({
    double width = 100,
    double height = 16,
    BorderRadius? borderRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  // ================================
  // ✅ 7. CARD SHIMMER
  // ================================
  static Widget cardShimmer({
    double? width,
    double? height,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}