import 'package:flutter/material.dart';
import '../../../../core/localization/app_language_service.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/student_topic_service.dart';
import '../model/thesis_topic_model.dart';

class StudentTopicListScreen extends StatefulWidget {
  final UserModel user;

  const StudentTopicListScreen({super.key, required this.user});

  @override
  State<StudentTopicListScreen> createState() => _StudentTopicListScreenState();
}

class _StudentTopicListScreenState extends State<StudentTopicListScreen> {
  final StudentTopicService _topicService = StudentTopicService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedLecturer = 'Giảng viên';
  String _selectedDirection = 'Hướng đề tài';
  List<ThesisTopicModel> _topics = [];
  bool _isLoading = true;

  late List<String> _lecturers;
  late List<String> _directions;

  // Design Tokens trích xuất trực tiếp từ ảnh mẫu
  static const Color _bgScreen = Color(0xFFF5F6F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _sectionBoxBg = Color(0xFFF8FAFC);
  static const Color _primaryBlue = Color(0xFF1A73E8);
  static const Color _tagBgBlue = Color(0xFFEEF5FE);
  static const Color _tagBgGreen = Color(0xFFEBF8F2);
  static const Color _textGreen = Color(0xFF10B981);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9EAAAF);
  static const Color _borderSubtle = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _lecturers = ['Giảng viên', ..._topicService.getLecturers().where((l) => l != 'Tất cả')];
    _directions = ['Hướng đề tài', ..._topicService.getDirections().where((d) => d != 'Tất cả')];
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _topicService.getTopics(
      query: _searchController.text,
      lecturerFilter: _selectedLecturer == 'Giảng viên' ? null : _selectedLecturer,
      directionFilter: _selectedDirection == 'Hướng đề tài' ? null : _selectedDirection,
      currentUser: widget.user,
    );

    if (mounted) {
      setState(() {
        _topics = data;
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // 1. MODAL CHI TIẾT ĐỀ TÀI (Ảnh 2)
  // ==========================================
  void _showTopicDetailModal(ThesisTopicModel topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Thanh gạt modal
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),

            // Header Modal: "Chi tiết đề tài" + Nút đóng X
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 14, 10),
              child: Row(
                children: [
                  const Text(
                    'Chi tiết đề tài',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _textSecondary, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: _borderSubtle),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên đề tài
                    Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Mã đề tài
                    Text(
                      topic.topicCode,
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Hàng Tag (Nghiên cứu, Đợt 1...)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildPillTag(topic.researchDirection),
                        _buildPillTag(topic.periodName),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Mục 1: Giảng viên hướng dẫn
                    _buildSectionHeader('Giảng viên hướng dẫn'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _sectionBoxBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _borderSubtle.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: _tagBgBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                topic.lecturerInitials,
                                style: const TextStyle(
                                  color: _primaryBlue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topic.lecturerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  topic.periodName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Mục 2: Số lượng SV tối đa
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _sectionBoxBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _borderSubtle.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: _primaryBlue, size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'Số lượng SV tối đa',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            topic.maxStudents > 0 ? '${topic.maxStudents} SV' : '—',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Mục 3: Nội dung yêu cầu
                    _buildSectionHeader('Nội dung yêu cầu'),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Mục tiêu: ',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                          ),
                          TextSpan(
                            text: '${topic.description}\n\n',
                            style: const TextStyle(color: Color(0xFF374151), height: 1.55),
                          ),
                          const TextSpan(
                            text: 'Yêu cầu nghiệp vụ/kỹ thuật:\n',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937), height: 1.6),
                          ),
                          TextSpan(
                            text: topic.requirements,
                            style: const TextStyle(color: Color(0xFF374151), height: 1.55),
                          ),
                          if (topic.targetOutput != null && topic.targetOutput!.isNotEmpty) ...[
                            const TextSpan(
                              text: '\n\nSản phẩm / Kết quả dự kiến:\n',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937), height: 1.6),
                            ),
                            TextSpan(
                              text: topic.targetOutput!,
                              style: const TextStyle(color: Color(0xFF374151), height: 1.55),
                            ),
                          ],
                        ],
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Nút Đăng ký ở dưới đáy Modal
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: topic.isMyTopic
                        ? const Color(0xFFEF4444)
                        : (topic.isOpen ? _primaryBlue : const Color(0xFF94A3B8)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: !topic.isOpen && !topic.isMyTopic
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _handleTopicAction(topic);
                        },
                  child: Text(
                    topic.isMyTopic ? 'HỦY ĐĂNG KÝ ĐỀ TÀI' : (topic.isOpen ? 'ĐĂNG KÝ ĐỀ TÀI NÀY' : 'ĐỀ TÀI ĐÃ ĐÓNG'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. MÀN HÌNH DANH SÁCH ĐỀ TÀI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh nền
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_main.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                color: _bgScreen,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. TOP APP BAR DẠNG FLOATING PILL
                _buildHeader(),

                // 2. Ô TÌM KIẾM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _fetchTopics(),
                      style: const TextStyle(fontSize: 14, color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc mã đề tài...',
                        hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8C9BA8), size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: _textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchTopics();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),

          const SizedBox(height: 10),

          // 2. Hai bộ lọc Dropdown: Giảng viên & Hướng đề tài
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Dropdown 1: Giảng viên
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _lecturers.contains(_selectedLecturer) ? _selectedLecturer : _lecturers.first,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _textSecondary),
                        items: _lecturers.map((l) {
                          return DropdownMenuItem(
                            value: l,
                            child: Text(l, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLecturer = val);
                            _fetchTopics();
                          }
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Dropdown 2: Hướng đề tài
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _directions.contains(_selectedDirection) ? _selectedDirection : _directions.first,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _textSecondary),
                        items: _directions.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(d, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDirection = val);
                            _fetchTopics();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Label số lượng đề tài
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '${_topics.length} đề tài',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),

          // 4. Danh sách thẻ đề tài
          Expanded(
            child: _isLoading
                ? const Center(child: HuitLoading(message: 'Đang tải danh sách đề tài...'))
                : _topics.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchTopics,
                        color: _primaryBlue,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                          itemCount: _topics.length,
                          itemBuilder: (ctx, idx) => _buildTopicCard(_topics[idx]),
                        ),
                      ),
          ),
        ],
      ),
    ),
  ],
),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0072E8), Color(0xFF0091FF), Color(0xFF00A2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Expanded(
              child: Text(
                'ĐĂNG KÝ ĐỀ TÀI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. THẺ ĐỀ TÀI (Topic Card)
  // ==========================================
  Widget _buildTopicCard(ThesisTopicModel topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showTopicDetailModal(topic),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Tiêu đề đề tài + Tag "Mở"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        topic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: topic.isOpen ? _tagBgGreen : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        topic.statusDisplay,
                        style: TextStyle(
                          color: topic.isOpen ? _textGreen : _textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Hàng 2: Mã đề tài
                Text(
                  topic.topicCode,
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 12),

                // Hàng 3: Giảng viên (Avatar tròn BD + Tên + Đợt)
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: _tagBgBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          topic.lecturerInitials,
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.lecturerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            topic.periodName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Hàng 4: Các Tag (Tích hợp, Đợt 1 - KLCN - CNTT)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPillTag(topic.researchDirection),
                    _buildPillTag(topic.periodName),
                  ],
                ),

                const SizedBox(height: 12),

                // Hàng 5: Chưa giới hạn SV + Chevron icon
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 17, color: _textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      topic.studentLimitDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _tagBgBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _handleTopicAction(ThesisTopicModel topic) async {
    if (topic.isMyTopic) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hủy đăng ký đề tài', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: Text('Bạn có chắc muốn hủy đăng ký đề tài "${topic.title}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('confirm'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await _topicService.cancelTopicRegistration(
          topicId: topic.id,
          user: widget.user,
        );
        if (mounted) {
          _showSnackBar(success ? 'Đã hủy đăng ký đề tài thành công!' : 'Hủy đăng ký thất bại.');
          _fetchTopics();
        }
      }
      return;
    }

    final success = await _topicService.registerTopic(
      topicId: topic.id,
      user: widget.user,
    );
    if (mounted) {
      _showSnackBar(success ? 'Đăng ký đề tài thành công!' : 'Đăng ký thất bại.', isError: !success);
      _fetchTopics();
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFEF4444) : _primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy đề tài phù hợp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vui lòng thử thay đổi từ khóa tìm kiếm hoặc bộ lọc giảng viên / hướng đề tài.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
