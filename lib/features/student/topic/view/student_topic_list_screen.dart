import 'package:flutter/material.dart';
import '../../../../core/localization/app_language_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../../group/logic/student_group_service.dart';
import '../../group/model/student_group_model.dart';
import '../logic/student_topic_service.dart';
import '../model/thesis_topic_model.dart';
import 'widgets/student_topic_card.dart';
import 'widgets/topic_detail_sheet.dart';
import 'widgets/topic_filter_bar.dart';

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
  String _selectedStatus = 'Trạng thái';
  List<ThesisTopicModel> _allTopics = [];
  List<ThesisTopicModel> _topics = [];
  bool _isLoading = true;
  StudentGroupModel? _myGroup;
  bool _isLeader = false;

  late List<String> _lecturers;
  late List<String> _directions;
  final List<String> _statuses = const [
    'Trạng thái',
    'Mở đăng ký',
    'Đã đóng',
    'Đã có nhóm',
  ];

  AppColors get _colors => AppColors.of(context);
  static const Color _primaryBlue = Color(0xFF1A73E8);

  @override
  void initState() {
    super.initState();
    _lecturers = ['Giảng viên'];
    _directions = ['Hướng đề tài'];
    _fetchTopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    List<ThesisTopicModel> filtered = List.from(_allTopics);

    // 1. Lọc theo Giảng viên
    if (_selectedLecturer != 'Giảng viên' && _selectedLecturer != 'Tất cả') {
      filtered = filtered.where((t) {
        return t.lecturerName.toLowerCase().contains(_selectedLecturer.toLowerCase());
      }).toList();
    }

    // 2. Lọc theo Hướng đề tài
    if (_selectedDirection != 'Hướng đề tài' && _selectedDirection != 'Tất cả') {
      filtered = filtered.where((t) {
        return t.researchDirection.toLowerCase() == _selectedDirection.toLowerCase();
      }).toList();
    }

    // 3. Lọc theo Trạng thái đề tài (Mở đăng ký / Đã đóng / Đã có nhóm)
    if (_selectedStatus != 'Trạng thái' && _selectedStatus != 'Tất cả') {
      final myGroupId = _myGroup?.id;
      if (_selectedStatus == 'Mở đăng ký') {
        filtered = filtered.where((t) {
          final isMy = t.isRegisteredByMyGroup(myGroupId);
          final isTakenByOther = t.isRegisteredByOther(myGroupId);
          return t.isOpen && !isTakenByOther && !isMy && !t.isMyTopic;
        }).toList();
      } else if (_selectedStatus == 'Đã đóng') {
        filtered = filtered.where((t) {
          final isMy = t.isRegisteredByMyGroup(myGroupId);
          final isTakenByOther = t.isRegisteredByOther(myGroupId);
          return !t.isOpen || isTakenByOther || isMy || t.isMyTopic;
        }).toList();
      } else if (_selectedStatus == 'Đã có nhóm') {
        filtered = filtered.where((t) {
          final isMy = t.isRegisteredByMyGroup(myGroupId);
          final isTakenByOther = t.isRegisteredByOther(myGroupId);
          return isTakenByOther || isMy || t.isMyTopic;
        }).toList();
      }
    }

    // 4. Tìm kiếm từ khóa theo tên đề tài, mã, GV, hướng...
    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.topicCode.toLowerCase().contains(query) ||
            t.lecturerName.toLowerCase().contains(query) ||
            t.researchDirection.toLowerCase().contains(query) ||
            t.periodName.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _topics = filtered;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedLecturer = 'Giảng viên';
      _selectedDirection = 'Hướng đề tài';
      _selectedStatus = 'Trạng thái';
    });
    _applyFilter();
  }

  Future<void> _fetchTopics() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _topicService.getTopics(
      currentUser: widget.user,
    );

    StudentGroupModel? myGroup;
    bool isLeader = false;
    try {
      myGroup = await StudentGroupService().getMyGroup(widget.user);
      if (myGroup != null) {
        isLeader = myGroup.isUserLeader(widget.user);
      }
    } catch (_) {}

    final rawLecturers = _topicService.getLecturers(fromTopics: data);
    final rawDirections = _topicService.getDirections(fromTopics: data);

    if (mounted) {
      setState(() {
        _allTopics = data;
        _myGroup = myGroup;
        _isLeader = isLeader;
        _lecturers = ['Giảng viên', ...rawLecturers.where((l) => l != 'Tất cả')];
        _directions = ['Hướng đề tài', ...rawDirections.where((d) => d != 'Tất cả')];
        if (!_lecturers.contains(_selectedLecturer)) {
          _selectedLecturer = 'Giảng viên';
        }
        if (!_directions.contains(_selectedDirection)) {
          _selectedDirection = 'Hướng đề tài';
        }
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  void _showTopicDetailModal(ThesisTopicModel topic) {
    final hasRegistered = (_myGroup != null && _myGroup!.hasRegisteredTopic) ||
        _allTopics.any((t) => t.isMyTopic);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TopicDetailSheet(
        topic: topic,
        myGroup: _myGroup,
        isLeader: _isLeader,
        hasRegisteredTopic: hasRegistered,
        onRegisterPressed: () => _handleTopicAction(topic),
      ),
    );
  }

  Future<void> _handleTopicAction(ThesisTopicModel topic) async {
    final hasRegistered = (_myGroup != null && _myGroup!.hasRegisteredTopic) ||
        _allTopics.any((t) => t.isMyTopic);

    if (hasRegistered) {
      _showRegistrationErrorDialog(
        'Nhóm của bạn đã đăng ký đề tài khóa luận trong đợt này rồi. Không thể đăng ký thêm đề tài khác!',
      );
      return;
    }

    final memberCount = _myGroup != null
        ? (_myGroup!.currentMembers > 0
            ? _myGroup!.currentMembers
            : _myGroup!.members.length)
        : 0;

    if (_myGroup != null && !_myGroup!.isFull) {
      _showRegistrationErrorDialog(
        'Nhóm "${_myGroup!.name}" chưa đủ số lượng thành viên (${_myGroup!.currentMembers}/${_myGroup!.maxMembers} sinh viên).\n\nVui lòng mời đủ thành viên trước khi đăng ký đề tài!',
      );
      return;
    }

    if (_myGroup != null && topic.maxStudents > 0 && memberCount > topic.maxStudents) {
      _showRegistrationErrorDialog(
        'Nhóm "${_myGroup!.name}" hiện có $memberCount thành viên, vượt quá giới hạn tối đa của đề tài (${topic.maxStudents} sinh viên).\n\nVui lòng chọn đề tài khác phù hợp với số lượng thành viên trong nhóm.',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xác nhận đăng ký đề tài',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: _colors.textPrimary),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng ký đề tài "${topic.title}" cho nhóm "${_myGroup?.name ?? ''}" không?\n\n(Lưu ý: Sau khi đăng ký, đề tài sẽ được chuyển sang trạng thái chờ Giảng viên hướng dẫn phê duyệt).',
          style: TextStyle(fontSize: 13.5, height: 1.4, color: _colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: _colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('confirm'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _topicService.registerTopic(
        topicId: topic.id,
        user: widget.user,
      );
      if (mounted) {
        _showSnackBar(
          success
              ? 'Đăng ký đề tài thành công! Vui lòng chờ Giảng viên hướng dẫn duyệt.'
              : 'Đăng ký đề tài thất bại.',
          isError: !success,
        );
        StudentGroupService().invalidateGroupCache();
        _fetchTopics();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showRegistrationErrorDialog(errorMsg);
      }
    }
  }

  void _showRegistrationErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chưa đủ điều kiện đăng ký',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _colors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 13.5, color: _colors.textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _colors.isDark
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _colors.pageGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/bg_main.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: _colors.scaffoldBg,
                    ),
                  ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. Header
                _buildHeader(),

                // 2. Ô tìm kiếm & Dropdowns bộ lọc
                TopicFilterBar(
                  searchController: _searchController,
                  onSearchChanged: (_) => _applyFilter(),
                  onClearSearch: () {
                    _searchController.clear();
                    _applyFilter();
                  },
                  lecturers: _lecturers,
                  selectedLecturer: _selectedLecturer,
                  onLecturerChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLecturer = val);
                      _applyFilter();
                    }
                  },
                  directions: _directions,
                  selectedDirection: _selectedDirection,
                  onDirectionChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDirection = val);
                      _applyFilter();
                    }
                  },
                  statuses: _statuses,
                  selectedStatus: _selectedStatus,
                  onStatusChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                      _applyFilter();
                    }
                  },
                  onResetFilters: _resetFilters,
                  topicCount: _topics.length,
                ),

                // 3. Danh sách đề tài
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
                                itemBuilder: (ctx, idx) {
                                  final topic = _topics[idx];
                                  return StudentTopicCard(
                                    topic: topic,
                                    myGroupId: _myGroup?.id,
                                    onTap: () => _showTopicDetailModal(topic),
                                  );
                                },
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

  Widget _buildEmptyState() {
    final bool isFiltered = _searchController.text.trim().isNotEmpty ||
        _selectedLecturer != 'Giảng viên' ||
        _selectedDirection != 'Hướng đề tài' ||
        _selectedStatus != 'Trạng thái';

    final String titleText;
    final String subText;
    final IconData emptyIcon;

    if (isFiltered) {
      titleText = 'Không tìm thấy đề tài phù hợp';
      subText = 'Vui lòng thử thay đổi từ khóa tìm kiếm hoặc bộ lọc giảng viên / hướng đề tài / trạng thái.';
      emptyIcon = Icons.search_off_rounded;
    } else {
      titleText = 'Chưa thể đăng kí đề tài';
      subText = 'Hiện tại chưa có đề tài khóa luận nào được mở trong hệ thống.';
      emptyIcon = Icons.folder_off_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _colors.subCardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                emptyIcon,
                size: 48,
                color: _colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: _colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _colors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
