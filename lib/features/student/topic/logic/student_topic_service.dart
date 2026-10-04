import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/model/user_model.dart';
import '../model/thesis_topic_model.dart';

class StudentTopicService {
  static final StudentTopicService _instance = StudentTopicService._internal();
  factory StudentTopicService() => _instance;
  StudentTopicService._internal();

  // Danh sách đề tài chuẩn thực tế theo thiết kế trong ảnh
  final List<ThesisTopicModel> _mockTopics = [
    ThesisTopicModel(
      id: '26',
      topicCode: 'CNTT-KLCN026',
      title: 'Nghiên cứu mô hình phân tích xu hướng cảm xúc của báo điện tử đối với thực thể bằng mô hình ngôn ngữ lớn',
      titleEn: 'Research on sentiment trend analysis model of online newspapers towards entities using large language models',
      description: 'Nghiên cứu bài toán phân tích xu hướng cảm xúc của báo điện tử tiếng Việt theo thực thể (người, địa điểm, tổ chức hoặc sự kiện) bằng các phương pháp xử lý ngôn ngữ tự nhiên hiện đại (Transformer, LLMs, RAG,...); xây dựng và đánh giá mô hình, đồng thời đề xuất hướng cải tiến nhằm nâng cao độ chính xác, khả năng tổng quát hóa và khả năng giải thích kết quả.',
      requirements: '- Nghiên cứu cơ sở lý thuyết về phân tích cảm xúc theo thực thể, nhận dạng thực thể (NER), xử lý ngôn ngữ tự nhiên và các mô hình Transformer, LLMs, RAG.\n- Thu thập hoặc xây dựng bộ dữ liệu báo điện tử tiếng Việt, thực hiện tiền xử lý văn bản, nhận dạng thực thể và gán nhãn.\n- Xây dựng mô hình phân tích xu hướng cảm xúc theo thực thể.',
      major: 'Khoa học dữ liệu',
      lecturerName: 'Huỳnh Thị Cẩm Dung',
      lecturerTitle: 'ThS.',
      lecturerEmail: 'dunghtc@huit.edu.vn',
      lecturerPhone: '0908 556 789',
      maxStudents: 0,
      currentStudents: 0,
      status: 'open',
      periodName: 'Đợt 1 - KLCN - CNTT',
      researchDirection: 'Nghiên cứu',
      targetOutput: 'Mô hình phân tích cảm xúc tiếng Việt và Website / Dashboard trực quan hóa xu hướng.',
    ),
    ThesisTopicModel(
      id: '1',
      topicCode: 'CNTT-KLCN001',
      title: 'Hỗ trợ quản lý hồ sơ khoa học công nghệ bằng phương pháp phân loại tự động',
      titleEn: 'Supporting scientific and technological document management using automatic classification methods',
      description: 'Nghiên cứu các mô hình xử lý ngôn ngữ tự nhiên (NLP, BERT, LLM) và Vector Database để tự động trích xuất, phân loại và số hóa hồ sơ công trình khoa học công nghệ của trường.',
      requirements: 'Python, FastAPI, PyTorch, LangChain, PostgreSQL (pgvector), Flutter.',
      major: 'Công nghệ phần mềm',
      lecturerName: 'Bùi Công Danh',
      lecturerTitle: 'ThS.',
      lecturerEmail: 'danhbc@huit.edu.vn',
      lecturerPhone: '0908 112 233',
      maxStudents: 0,
      currentStudents: 0,
      status: 'open',
      periodName: 'Đợt 1 - KLCN - CNTT',
      researchDirection: 'Tích hợp',
      targetOutput: 'Hệ thống website quản lý hồ sơ và module AI phân loại tài liệu tự động.',
    ),
    ThesisTopicModel(
      id: '2',
      topicCode: 'CNTT-KLCN002',
      title: 'Ứng dụng Variational Graph Autoencoder trong phát hiện cộng đồng mạng xã hội',
      titleEn: 'Application of Variational Graph Autoencoder in social network community detection',
      description: 'Nghiên cứu cấu trúc đồ thị mạng xã hội lớn, ứng dụng mạng Graph Neural Network (GNN) và Variational Graph Autoencoder (VGAE) để phân cụm và phát hiện các nhóm cộng đồng ẩn.',
      requirements: 'Python, PyTorch Geometric, NetworkX, DGL, Graph Mining.',
      major: 'Khoa học dữ liệu',
      lecturerName: 'Bùi Công Danh',
      lecturerTitle: 'ThS.',
      lecturerEmail: 'danhbc@huit.edu.vn',
      lecturerPhone: '0908 112 233',
      maxStudents: 0,
      currentStudents: 0,
      status: 'open',
      periodName: 'Đợt 1 - KLCN - CNTT',
      researchDirection: 'Nghiên cứu',
      targetOutput: 'Mô hình VGAE huấn luyện trên đồ thị thực tế và công cụ visualize cụm cộng đồng.',
    ),
    ThesisTopicModel(
      id: '3',
      topicCode: 'CNTT-KLCN003',
      title: 'Nghiên cứu bài toán lan truyền thông tin tối ưu trên mạng xã hội sử dụng phát hiện cụm',
      titleEn: 'Research on optimal information diffusion problem in social networks using cluster detection',
      description: 'Xây dựng thuật toán xác định tập nút nguồn có ảnh hưởng lớn nhất (Influence Maximization) kết hợp mô hình phân tích cụm để tối ưu hóa chiến dịch truyền thông.',
      requirements: 'Python, Scikit-learn, Graph Algorithms, Web Dashboard Dash/Streamlit.',
      major: 'Khoa học dữ liệu',
      lecturerName: 'Bùi Công Danh',
      lecturerTitle: 'ThS.',
      lecturerEmail: 'danhbc@huit.edu.vn',
      lecturerPhone: '0908 112 233',
      maxStudents: 0,
      currentStudents: 0,
      status: 'open',
      periodName: 'Đợt 1 - KLCN - CNTT',
      researchDirection: 'Nghiên cứu',
      targetOutput: 'Thuật toán tìm nút ảnh hưởng cao và báo cáo đánh giá thực nghiệm.',
    ),
    ThesisTopicModel(
      id: '4',
      topicCode: 'CNTT-KLCN004',
      title: 'Xây dựng ứng dụng di động hỗ trợ Quản lý Khóa luận tốt nghiệp đa nền tảng (Flutter & ASP.NET Core)',
      titleEn: 'Cross-platform Graduation Thesis Management Mobile Application',
      description: 'Phát triển ứng dụng di động Flutter kết nối API ASP.NET Core, theo dõi tiến độ nộp báo cáo tuần, đăng ký đề tài và chấm điểm hội đồng.',
      requirements: 'Flutter (Dart), Provider/Riverpod, RESTful API ASP.NET Core, SQL Server.',
      major: 'Công nghệ phần mềm',
      lecturerName: 'Nguyễn Văn Toàn',
      lecturerTitle: 'TS.',
      lecturerEmail: 'toannv@huit.edu.vn',
      lecturerPhone: '0903 456 789',
      maxStudents: 3,
      currentStudents: 2,
      status: 'open',
      periodName: 'Đợt 1 - KLCN - CNTT',
      researchDirection: 'Ứng dụng',
      targetOutput: 'Ứng dụng di động Flutter và API Backend ASP.NET Core hoàn chỉnh.',
    ),
    ThesisTopicModel(
      id: '5',
      topicCode: 'CNTT-KLCN005',
      title: 'Hệ thống Giám sát và Cảnh báo Tấn công Mạng sử dụng Deep Learning và Phân tích nhật ký SIEM',
      titleEn: 'Network Attack Monitoring and Warning System using Deep Learning and SIEM Log Analysis',
      description: 'Thu thập và phân tích log hệ thống từ tường lửa, phát hiện bất thường và các cuộc tấn công Brute-force, DDoS, Injection theo thời gian thực.',
      requirements: 'Python, ELK Stack (Elasticsearch, Logstash, Kibana), CNN-LSTM, Docker.',
      major: 'An toàn thông tin',
      lecturerName: 'Vũ Đức Nam',
      lecturerTitle: 'ThS.',
      lecturerEmail: 'namvd@huit.edu.vn',
      lecturerPhone: '0988 667 788',
      maxStudents: 2,
      currentStudents: 1,
      status: 'open',
      periodName: 'Đợt 1 - KLCN - CNTT',
      researchDirection: 'Tích hợp',
      targetOutput: 'Hệ thống SIEM giám sát log và dashboard cảnh báo sự cố an toàn thông tin.',
    ),
    ThesisTopicModel(
      id: '6',
      topicCode: 'CNTT-KLCN006',
      title: 'Xây dựng Hệ thống Điểm danh Tự động bằng Nhận diện Khuôn mặt đa luồng trên thiết bị Edge AI',
      titleEn: 'Automated Multi-Stream Face Recognition Attendance System on Edge AI Devices',
      description: 'Triển khai mô hình YOLOv8 và ArcFace trên vi xử lý nhúng Jetson Nano nhận diện cùng lúc nhiều sinh viên khi vào phòng học.',
      requirements: 'Python, OpenCV, TensorRT, Jetson Nano, MQTT, Flutter.',
      major: 'Hệ thống thông tin',
      lecturerName: 'Lê Hoàng Phúc',
      lecturerTitle: 'PGS.TS.',
      lecturerEmail: 'phuclh@huit.edu.vn',
      lecturerPhone: '0903 789 101',
      maxStudents: 3,
      currentStudents: 3,
      status: 'closed',
      periodName: 'Đợt 1 - KLCN - CNTT',
      researchDirection: 'Ứng dụng',
      targetOutput: 'Thiết bị nhúng chạy AI nhận diện và phần mềm quản lý điểm danh.',
    ),
  ];

  String? _myRegisteredTopicId;

  // Lấy danh sách đề tài
  Future<List<ThesisTopicModel>> getTopics({
    String? query,
    String? lecturerFilter,
    String? directionFilter,
    UserModel? currentUser,
  }) async {
    List<ThesisTopicModel> topics = [];

    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Theses');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final dynamic decoded = jsonDecode(utf8Body);
        if (decoded is List) {
          topics = decoded.map((item) => ThesisTopicModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('StudentTopicService: Backend API /Theses fallback to mock data.');
    }

    if (topics.isEmpty) {
      topics = List<ThesisTopicModel>.from(_mockTopics);
    }

    // Cập nhật trạng thái đề tài của sinh viên
    topics = topics.map((t) {
      final isMine = _myRegisteredTopicId != null && t.id == _myRegisteredTopicId;
      return t.copyWith(isMyTopic: isMine);
    }).toList();

    // Lọc theo Giảng viên
    if (lecturerFilter != null && lecturerFilter.isNotEmpty && lecturerFilter != 'Tất cả' && lecturerFilter != 'Giảng viên') {
      topics = topics.where((t) => t.lecturerName.toLowerCase().contains(lecturerFilter.toLowerCase())).toList();
    }

    // Lọc theo Hướng đề tài
    if (directionFilter != null && directionFilter.isNotEmpty && directionFilter != 'Tất cả' && directionFilter != 'Hướng đề tài') {
      topics = topics.where((t) => t.researchDirection.toLowerCase() == directionFilter.toLowerCase()).toList();
    }

    // Tìm kiếm theo tên hoặc mã đề tài
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      topics = topics.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.topicCode.toLowerCase().contains(q) ||
            t.lecturerName.toLowerCase().contains(q) ||
            t.researchDirection.toLowerCase().contains(q) ||
            t.periodName.toLowerCase().contains(q);
      }).toList();
    }

    return topics;
  }

  // Lấy danh sách giảng viên duy nhất
  List<String> getLecturers() {
    final list = _mockTopics.map((t) => t.lecturerName).toSet().toList();
    list.sort();
    return ['Tất cả', ...list];
  }

  // Lấy danh sách hướng đề tài duy nhất
  List<String> getDirections() {
    final list = _mockTopics.map((t) => t.researchDirection).toSet().toList();
    list.sort();
    return ['Tất cả', ...list];
  }

  // Lấy đề tài đã đăng ký của tôi
  Future<ThesisTopicModel?> getMyRegisteredTopic(UserModel user) async {
    final list = await getTopics(currentUser: user);
    for (final t in list) {
      if (t.isMyTopic || t.id == _myRegisteredTopicId) {
        return t;
      }
    }
    return null;
  }

  // Đăng ký đề tài
  Future<bool> registerTopic({
    required String topicId,
    required UserModel user,
    String? note,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Theses/$topicId/register');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'studentId': user.userId,
          'note': note ?? '',
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _myRegisteredTopicId = topicId;
        _updateLocalMockRegistration(topicId, true, user);
        return true;
      }
    } catch (e) {
      debugPrint('StudentTopicService: Register fallback.');
    }

    _myRegisteredTopicId = topicId;
    _updateLocalMockRegistration(topicId, true, user);
    return true;
  }

  // Hủy đăng ký đề tài
  Future<bool> cancelTopicRegistration({
    required String topicId,
    required UserModel user,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Theses/$topicId/cancel');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'studentId': user.userId}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        if (_myRegisteredTopicId == topicId) {
          _myRegisteredTopicId = null;
        }
        _updateLocalMockRegistration(topicId, false, user);
        return true;
      }
    } catch (e) {
      debugPrint('StudentTopicService: Cancel fallback.');
    }

    if (_myRegisteredTopicId == topicId) {
      _myRegisteredTopicId = null;
    }
    _updateLocalMockRegistration(topicId, false, user);
    return true;
  }

  void _updateLocalMockRegistration(String topicId, bool isRegistering, UserModel user) {
    final index = _mockTopics.indexWhere((t) => t.id == topicId);
    if (index != -1) {
      final current = _mockTopics[index];
      final newCount = isRegistering ? current.currentStudents + 1 : (current.currentStudents > 0 ? current.currentStudents - 1 : 0);
      _mockTopics[index] = current.copyWith(
        currentStudents: newCount,
        isMyTopic: isRegistering,
        registeredGroupName: isRegistering ? 'Nhóm của ${user.fullName}' : null,
      );
    }
  }
}
