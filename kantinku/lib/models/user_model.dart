class User {
  final int id;
  final String namaPengguna;
  final String nomorTelepon;
  final String role;

  User({
    required this.id,
    required this.namaPengguna,
    required this.nomorTelepon,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      namaPengguna: json['nama_pengguna'],
      nomorTelepon: json['nomor_telepon'],
      role: json['role'],
    );
  }
}
