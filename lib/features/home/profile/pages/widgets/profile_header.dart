import 'package:flutter/material.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/features/home/add_chat/presentation/pages/cloudinary_image_avatar.dart';
import '../../domain/models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;

  const ProfileHeader({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ManagerWidth.w20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ManagerColors.primaryColor,
            ManagerColors.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          CloudinaryAvatar(
            imageUrl: profile.imageUrl,
            fallbackText: profile.name,
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            textColor: Colors.white,
          ),
          SizedBox(height: ManagerHeight.h16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.name,
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s20,
                  color: Colors.white,
                ),
              ),
              if (profile.isVerified) ...[
                SizedBox(width: ManagerWidth.w8),
                Icon(Icons.verified, color: Colors.white, size: 20),
              ],
            ],
          ),
          SizedBox(height: ManagerHeight.h8),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Text(
              profile.bio!,
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ManagerHeight.h8),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ManagerWidth.w12,
              vertical: ManagerHeight.h6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: profile.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: ManagerWidth.w6),
                Text(
                  profile.isOnline ? 'متصل الآن' : 'غير متصل',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}