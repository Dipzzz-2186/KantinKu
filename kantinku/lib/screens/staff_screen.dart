// file: screens/staff_screen.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';
import 'staff_product_management_view.dart';
import 'staff_order_inbox_view.dart';

class StaffScreen extends StatelessWidget {
  final User staffUser;
  final VoidCallback onLogout; // Callback untuk logout

  const StaffScreen({
    super.key,
    required this.staffUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dashboard Staff (${staffUser.namaPengguna})'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                onLogout();
                Navigator.pop(context); // Kembali ke ProductScreen
              },
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store), text: 'Kelola Produk'),
              Tab(icon: Icon(Icons.notifications), text: 'Pesanan Baru'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Manajemen Produk (CRUD)
            StaffProductManagementView(staffId: staffUser.id),
            
            // Tab 2: Pesanan Masuk (Realtime Inbox)
            StaffOrderInboxView(staffId: staffUser.id),
          ],
        ),
      ),
    );
  }
}
