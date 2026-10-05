/// Represents an emergency contact record for SafeRoute Emergency SOS.
class EmergencyContact {
  final String id;
  final String userId;
  final String contactName;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.phoneNumber,
    this.relationship = 'Parent',
    this.isPrimary = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Alias getter for backwards compatibility
  String get name => contactName;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      contactName: json['contactName']?.toString() ?? json['contact_name']?.toString() ?? json['name']?.toString() ?? 'Emergency Contact',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone_number']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? 'Parent',
      isPrimary: json['isPrimary'] == true || json['is_primary'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'contact_name': contactName,
        'phone_number': phoneNumber,
        'relationship': relationship,
        'is_primary': isPrimary,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Validate phone number has at least 10 digits
  bool get isValidPhoneNumber {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  /// Mask phone number for UI display (+91 ******3210)
  String get maskedPhoneNumber {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '********';
    final last4 = digits.substring(digits.length - 4);
    String prefix = '+91';
    if (phoneNumber.startsWith('+')) {
      final parts = phoneNumber.split(' ');
      if (parts.isNotEmpty && parts.first.startsWith('+')) {
        prefix = parts.first;
      }
    }
    return '$prefix ******$last4';
  }

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? contactName,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
