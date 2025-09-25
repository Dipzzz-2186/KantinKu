class User {
  final int id;
  final String namaPengguna;
  final String? nomorTelepon;
  final String role;
  final String? password;

  User({
    required this.id,
    required this.namaPengguna,
    this.nomorTelepon,
    required this.role,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      namaPengguna: json['nama_pengguna'] ?? '',
      nomorTelepon: json['nomor_telepon'],
      role: json['role'] ?? '',
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nama_pengguna": namaPengguna,
      "nomor_telepon": nomorTelepon,
      "role": role,
      "password": password,
    };
  }
}