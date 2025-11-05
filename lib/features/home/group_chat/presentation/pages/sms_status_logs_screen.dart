import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class SmsLogsScreen extends StatelessWidget {
  final String groupId;
  const SmsLogsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Get.back();
        }, icon: Icon(Icons.arrow_back,color: ManagerColors.white,)),
        backgroundColor: ManagerColors.primaryColor,
        elevation: 0,
        title: Text(
          'سجل الرسائل المرسلة',
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s16,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("groups")
            .doc(groupId)
            .collection("sms_logs")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "لا يوجد سجلات بعد",
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(ManagerWidth.w16),
            separatorBuilder: (_, __) => SizedBox(height: ManagerHeight.h10),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'unknown';
              final color = status == 'success'
                  ? Colors.green
                  : status == 'failed'
                  ? Colors.red
                  : Colors.grey;

              final time = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedTime = time != null
                  ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} "
                  "${time.day}/${time.month}/${time.year}"
                  : '';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(ManagerWidth.w10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sms_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    data['phone'] ?? '',
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: ManagerColors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: ManagerHeight.h4),
                      Text(
                        data['message'] ?? '',
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (formattedTime.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: ManagerHeight.h4),
                          child: Text(
                            formattedTime,
                            style: getRegularTextStyle(
                              fontSize: ManagerFontSize.s11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ManagerWidth.w10,
                      vertical: ManagerHeight.h6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status == 'success'
                          ? 'ناجحة'
                          : status == 'failed'
                          ? 'فشلت'
                          : 'غير معروف',
                      style: getBoldTextStyle(
                        fontSize: ManagerFontSize.s12,
                        color: color,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
