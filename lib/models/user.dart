class Employee {
  final int id;
  final String name;
  final String email;
  final String barcode;
  final String password;
  final bool canClockOthers;
  final int businessId;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.barcode,
    required this.password,
    required this.canClockOthers,
    required this.businessId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    // API might use different fields for name; try common ones
    String name = '';
    if (json.containsKey('name') &&
        json['name'] != null &&
        json['name'].toString().trim().isNotEmpty) {
      name = json['name'];
    } else if (json.containsKey('full_name') && json['full_name'] != null) {
      name = json['full_name'];
    } else if (json.containsKey('first_name') ||
        json.containsKey('last_name')) {
      final first = json['first_name'] ?? '';
      final last = json['last_name'] ?? '';
      name = ('$first $last').trim();
    }

    // fall back to email if name isn't provided
    if (name.isEmpty && json.containsKey('email')) {
      name = json['email'];
    }

    return Employee(
      id: json['id'],
      name: name,
      email: json['email'],
      barcode: json['barcode'],
      password: json['password'],
      canClockOthers: json['can_clock_others'] ?? false,
      businessId: json['business_id'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'barcode': barcode,
      'password': password,
      'can_clock_others': canClockOthers,
      'business_id': businessId,
    };
  }
}
