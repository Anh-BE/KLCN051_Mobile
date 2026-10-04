import 'package:flutter/material.dart';
import '../../auth/model/user_model.dart';

class StudentScheduleView extends StatelessWidget {
  final UserModel user;

  const StudentScheduleView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B66E4), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch & Tiến Độ Khóa Luận',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kế hoạch 12 tuần làm việc & Mốc thời gian quan trọng',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. TIMELINE CÁC TUẦN BÁO CÁO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kế Hoạch Báo Cáo Định Kỳ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 14),

                _buildTimelineItem(
                  week: 'Tuần 1 - 2',
                  title: 'Khởi động & Xác định yêu cầu đề tài',
                  time: '15/09 - 28/09/2026',
                  status: 'Đã hoàn thành',
                  statusColor: const Color(0xFF10B981),
                  statusBg: const Color(0xFFD1FAE5),
                  isPassed: true,
                ),
                _buildTimelineItem(
                  week: 'Tuần 3 - 4',
                  title: 'Phân tích thiết kế hệ thống & CSDL',
                  time: '29/09 - 12/10/2026',
                  status: 'Đã duyệt',
                  statusColor: const Color(0xFF10B981),
                  statusBg: const Color(0xFFD1FAE5),
                  isPassed: true,
                ),
                _buildTimelineItem(
                  week: 'Tuần 5 (Hiện tại)',
                  title: 'Xây dựng Mobile App & Kết nối API Backend',
                  time: '13/10 - 19/10/2026',
                  status: 'Đang thực hiện',
                  statusColor: const Color(0xFF0284C7),
                  statusBg: const Color(0xFFE0F2FE),
                  isCurrent: true,
                ),
                _buildTimelineItem(
                  week: 'Tuần 6 - 8',
                  title: 'Hoàn thiện chức năng & Kiểm thử',
                  time: '20/10 - 09/11/2026',
                  status: 'Sắp diễn ra',
                  statusColor: const Color(0xFF64748B),
                  statusBg: const Color(0xFFF1F5F9),
                ),
                _buildTimelineItem(
                  week: 'Tuần 12',
                  title: 'Bảo vệ Khóa Luận Tốt Nghiệp trước Hội Đồng',
                  time: '01/12 - 05/12/2026',
                  status: 'Mốc quyết định',
                  statusColor: const Color(0xFFDC2626),
                  statusBg: const Color(0xFFFEE2E2),
                  isMilestone: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String week,
    required String title,
    required String time,
    required String status,
    required Color statusColor,
    required Color statusBg,
    bool isPassed = false,
    bool isCurrent = false,
    bool isMilestone = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: const Color(0xFF0284C7), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                week,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isCurrent ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
