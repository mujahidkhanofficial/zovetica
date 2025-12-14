import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/cached_avatar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<User> _users = [];
  String _filter = 'all'; // all, doctor, pet_owner

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    // Note: You might need to update AdminService to support simple role filtering
    // For now using the existing method
    final users = await _adminService.getAllUsers(
      roleFilter: _filter == 'all' ? null : _filter,
    );
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.cloud,
        appBar: AppBar(
          title: const Text(
            'User Management',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryDiagonal,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51), // Translucent white
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withAlpha(77)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26), // ~0.1 opacity
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent, // Remove default divider
                tabs: const [
                  Tab(text: "All Users"),
                  Tab(text: "Doctors"),
                  Tab(text: "Pet Owners"),
                ],
                onTap: null, 
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Disable swipe to keep simple
          children: [
            _buildUserList('all'),
            _buildUserList('doctor'),
            _buildUserList('pet_owner'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String filter) {
    // Filter the current list locally to avoid constant fetching if possible,
    // Or simpler: display loading if fetching specific list.
    // For now, let's keep the existing logic but optimized for TabBar.
    // Since _loadUsers fetches everything or filters on backend, 
    // we can either separate lists or just trigger load on tab change.
    // simpler approach: Call _loadUsers(filter) when tab changes? 
    // Better: Filter the local list _users if it contains all, OR use separate lists.
    // To match current architecture without big refactor: 
    // We will just filter the _users list locally for this UI since we don't have good backend pagination hooked up fully yet
    
    // NOTE: This assumes _loadUsers loads ALL users first. 
    // If not, we should probably fetch on init.
    // Actually, let's just use a FutureBuilder or helper.
    
    // Revised approach: The main build method uses TabBarView.
    // Each page needs to load its data.
    return _UserListTab(
      adminService: _adminService, 
      filter: filter,
    );
  }
}

class _UserListTab extends StatefulWidget {
  final AdminService adminService;
  final String filter;
  const _UserListTab({required this.adminService, required this.filter});

  @override
  State<_UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<_UserListTab> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final users = await widget.adminService.getAllUsers(
      roleFilter: widget.filter == 'all' ? null : widget.filter,
    );
    if(mounted) setState(() { _users = users; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_users.isEmpty) return const Center(child: Text("No users found"));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10), // Soft elegant shadow
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Optional: Navigate to user details
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CachedAvatar(
                      imageUrl: user.profileImage.isNotEmpty ? user.profileImage : null,
                      name: user.name,
                      radius: 26,
                      backgroundColor: AppColors.primary.withAlpha(26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slate,
                            ),
                          ),
                          if (user.isBanned)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withAlpha(26),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.block_rounded, size: 14, color: AppColors.error),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Banned: ${user.bannedReason ?? "Violation"}',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.slate),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) => _handleAction(value, user),
                      itemBuilder: (context) => [
                        if (!user.isBanned)
                          const PopupMenuItem(
                            value: 'ban',
                            child: Row(
                              children: [
                                Icon(Icons.block, color: AppColors.error, size: 20),
                                SizedBox(width: 10),
                                Text('Block User', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'unban',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                                SizedBox(width: 10),
                                Text('Unblock User', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAction(String action, User user) async {
    if (action == 'ban') {
      final reason = await _showBanDialog(context);
      if (reason != null) {
        await widget.adminService.banUser(user.id, reason);
        _load();
      }
    } else if (action == 'unban') {
      await widget.adminService.unbanUser(user.id);
      _load();
    }
  }

  Future<String?> _showBanDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Violation of guidelines...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}


