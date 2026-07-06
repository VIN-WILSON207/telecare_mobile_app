import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Represents a TeleCare user profile stored in the Firestore database.
class UserModel {
  /// The unique user ID from Firebase Authentication.
  final String uid;

  /// The user's full name.
  final String fullName;

  /// The user's email address.
  final String email;

  /// The user's phone number.
  final String phone;

  /// The user's role (patient, doctor, or admin).
  final UserRole role;

  /// The user's date of birth.
  final DateTime? dateOfBirth;

  /// The user's gender.
  final String? gender;

  /// Status of healthcare professional verification.
  final String verificationStatus;

  /// URL to the user's profile picture.
  final String? profileImage;

  /// Time when this user record was first created.
  final DateTime createdAt;

  /// Doctor's medical specialty (only for doctors).
  final String? specialty;

  /// Doctor's medical license number (only for doctors).
  final String? licenseNumber;

  /// Doctor's primary clinic or hospital (only for doctors).
  final String? hospital;

  /// Flag indicating if the account is currently active.
  final bool isActive;

  /// HP prefix or title (e.g. 'Dr.', 'Nurse', 'Pharm.')
  final String? prefix;

  /// HP specific sub-type (e.g. 'doctor', 'nurse', 'pharmacist', 'physiotherapist')
  final String? hpType;

  /// Tracks if the HP is currently active/online for consultation
  final bool? isOnline;

  /// Tracks if the HP is currently in an active consultation call
  final bool? inCall;

  /// Weekly availability schedules for the professional
  final Map<String, dynamic>? availability;

  /// Patient's recorded blood pressure (only for patients).
  final String? bloodPressure;

  /// Patient's recorded body weight (only for patients).
  final double? weight;

  /// Patient's recorded height (only for patients).
  final double? height;

  /// Patient's recorded blood group (only for patients).
  final String? bloodGroup;

  /// Patient's recorded pulse rate (only for patients).
  final int? pulse;

  /// Patient's recorded body temperature (only for patients).
  final double? temperature;

  /// Creates a new [UserModel] instance.
  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.dateOfBirth,
    this.gender,
    this.verificationStatus = 'unverified',
    this.profileImage,
    required this.createdAt,
    this.specialty,
    this.licenseNumber,
    this.hospital,
    this.isActive = true,
    this.prefix,
    this.hpType,
    this.isOnline = false,
    this.inCall = false,
    this.availability,
    this.bloodPressure,
    this.weight,
    this.height,
    this.bloodGroup,
    this.pulse,
    this.temperature,
  });

  /// Creates a copy of this [UserModel] with replacement values.
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? dateOfBirth,
    String? gender,
    String? verificationStatus,
    String? profileImage,
    DateTime? createdAt,
    String? specialty,
    String? licenseNumber,
    String? hospital,
    bool? isActive,
    String? prefix,
    String? hpType,
    bool? isOnline,
    bool? inCall,
    Map<String, dynamic>? availability,
    String? bloodPressure,
    double? weight,
    double? height,
    String? bloodGroup,
    int? pulse,
    double? temperature,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      specialty: specialty ?? this.specialty,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      hospital: hospital ?? this.hospital,
      isActive: isActive ?? this.isActive,
      prefix: prefix ?? this.prefix,
      hpType: hpType ?? this.hpType,
      isOnline: isOnline ?? this.isOnline,
      inCall: inCall ?? this.inCall,
      availability: availability ?? this.availability,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      pulse: pulse ?? this.pulse,
      temperature: temperature ?? this.temperature,
    );
  }

  /// Converts this [UserModel] into a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'verificationStatus': verificationStatus,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'hospital': hospital,
      'isActive': isActive,
      'prefix': prefix,
      'hpType': hpType,
      'isOnline': isOnline,
      'inCall': inCall,
      'availability': availability,
      'bloodPressure': bloodPressure,
      'weight': weight,
      'height': height,
      'bloodGroup': bloodGroup,
      'pulse': pulse,
      'temperature': temperature,
    };
  }

  /// Creates a [UserModel] from a Firestore Document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'patient'),
      dateOfBirth: _parseNullableDateTime(data['dateOfBirth']),
      gender: data['gender'] as String?,
      verificationStatus: data['verificationStatus'] as String? ?? 'unverified',
      profileImage: data['profileImage'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specialty: data['specialty'] as String?,
      licenseNumber: data['licenseNumber'] as String?,
      hospital: data['hospital'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      prefix: data['prefix'] as String?,
      hpType: data['hpType'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      inCall: data['inCall'] as bool? ?? false,
      availability: data['availability'] as Map<String, dynamic>?,
      bloodPressure: _parseString(data['bloodPressure']),
      weight: _parseDouble(data['weight']),
      height: _parseDouble(data['height']),
      bloodGroup: _parseString(data['bloodGroup']),
      pulse: _parseInt(data['pulse']),
      temperature: _parseDouble(data['temperature']),
    );
  }

  /// Creates a [UserModel] from a Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'patient'),
      dateOfBirth: _parseNullableDateTime(map['dateOfBirth']),
      gender: map['gender'] as String?,
      verificationStatus: map['verificationStatus'] as String? ?? 'unverified',
      profileImage: map['profileImage'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      specialty: map['specialty'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      hospital: map['hospital'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      prefix: map['prefix'] as String?,
      hpType: map['hpType'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      inCall: map['inCall'] as bool? ?? false,
      availability: map['availability'] as Map<String, dynamic>?,
      bloodPressure: _parseString(map['bloodPressure']),
      weight: _parseDouble(map['weight']),
      height: _parseDouble(map['height']),
      bloodGroup: _parseString(map['bloodGroup']),
      pulse: _parseInt(map['pulse']),
      temperature: _parseDouble(map['temperature']),
    );
  }

  /// Converts this [UserModel] into a JSON String.
  String toJson() => json.encode(toJsonMap());

  /// Creates a [UserModel] from a JSON String.
  factory UserModel.fromJson(String source) =>
      UserModel.fromJsonMap(json.decode(source) as Map<String, dynamic>);

  /// Converts this [UserModel] into a JSON-safe Map.
  Map<String, dynamic> toJsonMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'verificationStatus': verificationStatus,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'hospital': hospital,
      'isActive': isActive,
      'prefix': prefix,
      'hpType': hpType,
      'isOnline': isOnline,
      'inCall': inCall,
      'availability': availability,
      'bloodPressure': bloodPressure,
      'weight': weight,
      'height': height,
      'bloodGroup': bloodGroup,
      'pulse': pulse,
      'temperature': temperature,
    };
  }

  /// Creates a [UserModel] from a JSON-safe Map.
  factory UserModel.fromJsonMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'patient'),
      dateOfBirth: _parseNullableDateTime(map['dateOfBirth']),
      gender: map['gender'] as String?,
      verificationStatus: map['verificationStatus'] as String? ?? 'unverified',
      profileImage: map['profileImage'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      specialty: map['specialty'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      hospital: map['hospital'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      prefix: map['prefix'] as String?,
      hpType: map['hpType'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      inCall: map['inCall'] as bool? ?? false,
      availability: map['availability'] as Map<String, dynamic>?,
      bloodPressure: _parseString(map['bloodPressure']),
      weight: _parseDouble(map['weight']),
      height: _parseDouble(map['height']),
      bloodGroup: _parseString(map['bloodGroup']),
      pulse: _parseInt(map['pulse']),
      temperature: _parseDouble(map['temperature']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.fullName == fullName &&
        other.email == email &&
        other.phone == phone &&
        other.role == role &&
        other.dateOfBirth == dateOfBirth &&
        other.gender == gender &&
        other.verificationStatus == verificationStatus &&
        other.profileImage == profileImage &&
        other.createdAt == createdAt &&
        other.specialty == specialty &&
        other.licenseNumber == licenseNumber &&
        other.hospital == hospital &&
        other.isActive == isActive &&
        other.prefix == prefix &&
        other.hpType == hpType &&
        other.isOnline == isOnline &&
        other.inCall == inCall &&
        other.bloodPressure == bloodPressure &&
        other.weight == weight &&
        other.height == height &&
        other.bloodGroup == bloodGroup &&
        other.pulse == pulse &&
        other.temperature == temperature;
  }

  @override
  int get hashCode => Object.hashAll([
        uid,
        fullName,
        email,
        phone,
        role,
        dateOfBirth,
        gender,
        verificationStatus,
        profileImage,
        createdAt,
        specialty,
        licenseNumber,
        hospital,
        isActive,
        prefix,
        hpType,
        isOnline,
        inCall,
        bloodPressure,
        weight,
        height,
        bloodGroup,
        pulse,
        temperature,
      ]);

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, '
        'phone: $phone, role: ${role.value}, '
        'dateOfBirth: $dateOfBirth, gender: $gender, '
        'verificationStatus: $verificationStatus, '
        'profileImage: $profileImage, createdAt: $createdAt, '
        'specialty: $specialty, licenseNumber: $licenseNumber, '
        'hospital: $hospital, isActive: $isActive, prefix: $prefix, hpType: $hpType, '
        'isOnline: $isOnline, inCall: $inCall, '
        'bloodPressure: $bloodPressure, weight: $weight, height: $height, '
        'bloodGroup: $bloodGroup, pulse: $pulse, temperature: $temperature)';
  }

  /// Parses a value into a DateTime object, defaulting to current time if parsing fails.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  /// Parses a nullable value into a nullable DateTime object.
  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return null;
      return double.tryParse(value);
    }
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }
}
