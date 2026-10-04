class UserModel {
  final int userId;
  final String identifierCode;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final List<String> roles;

  UserModel({
    required this.userId,
    required this.identifierCode,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      identifierCode: json['identifierCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'identifierCode': identifierCode,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'roles': roles,
    };
  }

  bool get isStudent => roles.any((r) => r.toLowerCase().contains('student'));
  bool get isLecturer => roles.any((r) => r.toLowerCase().contains('lecturer'));
  bool get isDeanOrAdmin => roles.any((r) => r.toLowerCase().contains('dean') || r.toLowerCase().contains('admin') || r.toLowerCase().contains('head'));
}

class LoginResponseModel {
  final String token;
  final String tokenType;
  final String expiresAt;
  final UserModel user;

  LoginResponseModel({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      expiresAt: json['expiresAt']?.toString() ?? '',
      user: UserModel.fromJson(json['user'] is Map<String, dynamic> ? json['user'] : {}),
    );
  }
}
