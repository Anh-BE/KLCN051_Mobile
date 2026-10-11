import 'package:flutter/material.dart';
import '../../auth/model/user_model.dart';
import '../model/manager_stats_model.dart';

class ManagerDetailedStatsScreen extends StatefulWidget {
  final UserModel user;

  const ManagerDetailedStatsScreen({super.key, required this.user});

  @override
  State<ManagerDetailedStatsScreen> createState() => _ManagerDetailedStatsScreenState();
}

class _ManagerDetailedStatsScreenState extends State<ManagerDetailedStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<DepartmentStat> _deptStats = [
    DepartmentStat(
      departmentName: 'Công nghệ Phần mềm',
      totalTheses: 46,
      approvedTheses: 42,
      pendingTheses: 4,
      studentCount: 92,
      lecturerCount: 14,
    ),
    DepartmentStat(
      departmentName: 'An toàn Thông tin',
      totalTheses: 32,
      approvedTheses: 30,
      pendingTheses: 2,
      studentCount: 64,
      lecturerCount: 9,
    ),
    DepartmentStat(
      departmentName: 'Hệ thống Thông tin',
      totalTheses: 28,
      approvedTheses: 26,
      pendingTheses: 2,
      studentCount: 56,
      lecturerCount: 8,
    ),
    DepartmentStat(
      departmentName: 'Khoa học Dữ liệu & TTNT',
      totalTheses: 18,
      approvedTheses: 16,
      pendingTheses: 2,
      studentCount: 36,
      lecturerCount: 6,
    ),
  ];

  final List<LateSubmissionItem> _lateSubmissions = [
    LateSubmissionItem(
      studentCode: '2001230848',
      studentName: 'Nguyễn Văn C',
      groupName: 'Nhóm KLCN-14 (AI Detection)',
      taskName: 'Báo cáo Tuần 4: Thiết kế CSDL',
      deadlineStr: '07/10/2026 23:59',
      submittedTimeStr: '08/10/2026 03:15',
      lateHours: 4,
      reason: 'Cần sửa đổi quan hệ bảng khóa ngoại và kiểm thử dữ liệu',
    ),
    LateSubmissionItem(
      studentCode: '2001230852',
      studentName: 'Vũ Văn G',
      groupName: 'Nhóm KLCN-08 (Flutter IoT)',
      taskName: 'Báo cáo Tuần 3: Tài liệu kiến trúc',
      deadlineStr: '30/09/2026 23:59',
      submittedTimeStr: '01/10/2026 08:30',
      lateHours: 9,
      reason: 'Bổ sung sơ đồ deployment vật lý',
    ),
    LateSubmissionItem(
      studentCode: '2001230855',
      studentName: 'Đỗ Thị K',
      groupName: 'Nhóm KLCN-21 (Blockchain Cert)',
      taskName: 'Đề cương chi tiết khóa luận',
      deadlineStr: '23/09/2026 23:59',
      submittedTimeStr: '24/09/2026 01:45',
      lateHours: 2,
      reason: 'Gặp sự cố kết nối mạng lúc tải file',
    ),
  ];

  final List<CommitteeStat> _committees = [
    CommitteeStat(
      committeeCode: 'HD-CNPM-01',
      name: 'Hội đồng Bảo vệ CNPM 01',
      president: 'TS. Phùng Thế Bảo',
      secretary: 'ThS. Nguyễn Hải Yến',
      reviewer: 'ThS. Vũ Văn Vinh',
      assignedGroups: 6,
      room: 'Phòng B.402',
      defenseDate: '02/12/2026',
    ),
    CommitteeStat(
      committeeCode: 'HD-ATTT-01',
      name: 'Hội đồng Bảo vệ ATTT 01',
      president: 'ThS. Ngô Dương Hà',
      secretary: 'ThS. Trần Việt Anh',
      reviewer: 'ThS. Đinh Thị Mận',
      assignedGroups: 5,
      room: 'Phòng B.403',
      defenseDate: '03/12/2026',
    ),
    CommitteeStat(
      committeeCode: 'HD-KHDL-01',
      name: 'Hội đồng Bảo vệ KHDL 01',
      president: 'TS. Đặng Thị Hồng Nhung',
      secretary: 'ThS. Nguyễn Minh Tú',
      reviewer: 'ThS. Ngô Đức Huy',
      assignedGroups: 4,
      room: 'Phòng B.405',
      defenseDate: '04/12/2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SỐ LIỆU TỔNG HỢP CHI TIẾT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Khoa Công Nghệ Thông Tin • HUIT',
              style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Bộ Môn & Đề Tài'),
            Tab(text: 'Tiến Độ & Nộp Trễ'),
            Tab(text: 'Hội Đồng Bảo Vệ'),
            Tab(text: 'Xuất Báo Cáo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepartmentTab(),
          _buildProgressLateTab(),
          _buildCommitteeTab(),
          _buildExportReportTab(),
        ],
      ),
    );
  }

  // TAB 1: SỐ LIỆU THEO BỘ MÔN
  Widget _buildDepartmentTab() {
    int sumTotal = _deptStats.fold(0, (sum, item) => sum + item.totalTheses);
    int sumApproved = _deptStats.fold(0, (sum, item) => sum + item.approvedTheses);
    int sumPending = _deptStats.fold(0, (sum, item) => sum + item.pendingTheses);
    int sumStudents = _deptStats.fold(0, (sum, item) => sum + item.studentCount);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ tóm tắt toàn khoa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'TỔNG KHOA CÔNG NGHỆ THÔNG TIN',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryMini('Tổng đề tài', sumTotal.toString()),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSummaryMini('Đã duyệt', sumApproved.toString()),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSummaryMini('Chờ duyệt', sumPending.toString()),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSummaryMini('Sinh viên', sumStudents.toString()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Chi Tiết Theo Từng Bộ Môn Chuyên Ngành',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          ..._deptStats.map((dept) => _buildDeptCard(dept)),
        ],
      ),
    );
  }

  Widget _buildSummaryMini(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDeptCard(DepartmentStat dept) {
    final double approvalRate = dept.totalTheses > 0 ? (dept.approvedTheses / dept.totalTheses) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dept.departmentName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dept.pendingTheses > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dept.pendingTheses > 0 ? '${dept.pendingTheses} chờ duyệt' : 'Đã duyệt hết',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dept.pendingTheses > 0 ? const Color(0xFFB45309) : const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDeptStatInfo('Tổng đề tài', '${dept.totalTheses}')),
              Expanded(child: _buildDeptStatInfo('Sinh viên', '${dept.studentCount}')),
              Expanded(child: _buildDeptStatInfo('Giảng viên HD', '${dept.lecturerCount}')),
              Expanded(child: _buildDeptStatInfo('Tỷ lệ duyệt', '${(approvalRate * 100).toInt()}%')),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: approvalRate,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptStatInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  // TAB 2: TIẾN ĐỘ & DANH SÁCH NỘP TRỄ
  Widget _buildProgressLateTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ cảnh báo nộp trễ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.assignment_late_rounded, color: Color(0xFFEA580C), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theo dõi Tác phong & Tiến độ (Cờ Nộp Trễ):',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF9A3412)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hệ thống ghi nhận ${_lateSubmissions.length} lượt nộp báo cáo quá mốc 23:59 trong tuần này. Các dữ liệu này được lưu trữ để Giảng viên và Ban chủ nhiệm đánh giá điểm chuyên cần và thái độ làm việc của sinh viên.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7C2D12), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Tỷ lệ nộp bài toàn khoa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tỷ Lệ Báo Cáo Tiến Độ Tuần Toàn Khoa',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressStatTile('82%', 'Đúng hạn (< 23:59)', const Color(0xFF10B981), const Color(0xFFD1FAE5)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildProgressStatTile('14%', 'Nộp trễ (> 23:59)', const Color(0xFFEA580C), const Color(0xFFFFEDD5)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildProgressStatTile('4%', 'Chưa nộp', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Chi Tiết Các Báo Cáo Nộp Trễ Gần Đây',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          ..._lateSubmissions.map((item) => _buildLateItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildProgressStatTile(String percent, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(percent, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildLateItemCard(LateSubmissionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.studentName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              Text('(${item.studentCode})', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFB923C)),
                ),
                child: Text(
                  'Trễ ${item.lateHours} giờ',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFC2410C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.groupName, style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Nhiệm vụ: ${item.taskName}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.alarm_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text('Hạn 23:59: ${item.deadlineStr}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const SizedBox(width: 12),
              const Icon(Icons.history_rounded, size: 14, color: Color(0xFFEA580C)),
              const SizedBox(width: 4),
              Text('Nộp lúc: ${item.submittedTimeStr}', style: const TextStyle(fontSize: 11.5, color: Color(0xFFEA580C), fontWeight: FontWeight.w700)),
            ],
          ),
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Lý do sinh viên: "${item.reason}"', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
          ],
        ],
      ),
    );
  }

  // TAB 3: HỘI ĐỒNG BẢO VỆ
  Widget _buildCommitteeTab() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _committees.length,
      itemBuilder: (context, index) {
        final c = _committees[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.committeeCode,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.assignedGroups} Nhóm SV',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              _buildCouncilMemberRow('Chủ tịch Hội đồng:', c.president),
              _buildCouncilMemberRow('Thư ký:', c.secretary),
              _buildCouncilMemberRow('Ủy viên / Phản biện:', c.reviewer),
              const Divider(height: 18),
              Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(c.room, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(c.defenseDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouncilMemberRow(String role, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  // TAB 4: XUẤT BÁO CÁO THỐNG KÊ
  Widget _buildExportReportTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.print_rounded, color: Color(0xFF1E3A8A), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'BIỂU MẪU BÁO CÁO TỔNG HỢP (HUIT)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hệ thống tự động kết xuất dữ liệu và biểu mẫu thống kê theo đúng quy chuẩn báo cáo của Ban Chủ Nhiệm Khoa Công Nghệ Thông Tin - Trường ĐH Công Thương TP.HCM.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 18),
                _buildReportOptionItem(
                  title: 'Báo cáo 01: Danh sách Đề tài & Giảng viên Hướng dẫn',
                  subtitle: 'Định dạng PDF & Excel • 124 đề tài • Đã duyệt 114',
                  onTap: () => _showExportSuccessDialog('Báo cáo 01: Danh sách Đề tài & GVHD'),
                ),
                const SizedBox(height: 10),
                _buildReportOptionItem(
                  title: 'Báo cáo 02: Tình hình Tiến độ Tuần & Thống kê Nộp trễ',
                  subtitle: 'Theo dõi mốc 23:59 • Ghi nhận 82% đúng hạn, 14% nộp trễ',
                  onTap: () => _showExportSuccessDialog('Báo cáo 02: Tiến độ & Thống kê Nộp trễ'),
                ),
                const SizedBox(height: 10),
                _buildReportOptionItem(
                  title: 'Báo cáo 03: Quyết định Phân công Hội đồng Bảo vệ',
                  subtitle: '15 Hội đồng • Lịch phản biện từ 01/12/2026',
                  onTap: () => _showExportSuccessDialog('Báo cáo 03: Quyết định Hội đồng Bảo vệ'),
                ),
                const SizedBox(height: 10),
                _buildReportOptionItem(
                  title: 'Báo cáo 04: Thống kê Điểm số & Xếp loại Khóa luận',
                  subtitle: 'Phổ điểm theo CĐR • Xuất mẫu biểu phòng Đào tạo',
                  onTap: () => _showExportSuccessDialog('Báo cáo 04: Bảng điểm & Xếp loại Khóa luận'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptionItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: onTap,
          child: const Text('KẾT XUẤT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  void _showExportSuccessDialog(String reportName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 26),
            SizedBox(width: 8),
            Text('Kết Xuất Thành Công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          ],
        ),
        content: Text(
          'Đã xử lý và kết xuất thành công "$reportName" theo mẫu biểu Trường ĐH Công Thương TP.HCM.\n\nFile báo cáo sẵn sàng để lưu trữ hoặc in ấn.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
