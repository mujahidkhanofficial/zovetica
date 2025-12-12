// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'package:zovetica/services/pet_service.dart';
import 'package:zovetica/services/storage_service.dart';
import 'package:zovetica/services/post_service.dart';
import 'package:zovetica/services/friend_service.dart';
import 'package:zovetica/services/chat_service.dart';
import 'package:zovetica/services/appointment_service.dart';
import 'package:zovetica/services/review_service.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../utils/app_notifications.dart';
import '../utils/image_picker_helper.dart'; // import the new helper
import 'pet_details_screen.dart';
import 'add_pet_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/confirmation_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional: If null, show current user
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  final PostService _postService = PostService(); // Assuming we might need this later
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();
  final AppointmentService _appointmentService = AppointmentService();
  final ReviewService _reviewService = ReviewService();
  
  Map<String, dynamic> _userInfo = {};
  List<Pet> _pets = [];
  List<Post> _userPosts = [];
  File? _profileImage;
  bool _loadingSave = false;
  bool _isCurrentUser = true;
  String _friendshipStatus = 'none'; // 'none', 'pending_sent', 'pending_received', 'accepted', 'blocked'
  
  int _appointmentCount = 0;
  int _reviewCount = 0;
  
  Map<String, dynamic>? _myProfile; // Local cache of current user for comments
  


  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchPets();
    _fetchUserPosts();
    _fetchMyProfile();
  }

  Future<void> _fetchMyProfile() async {
    try {
      final profile = await _userService.getCurrentUser();
      if (mounted) {
        setState(() {
          _myProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error fetching my profile: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final currentUserId = _authService.currentUser?.id;
      final targetUserId = widget.userId ?? currentUserId;
      
      _isCurrentUser = (widget.userId == null || widget.userId == currentUserId);

      if (targetUserId != null) {
        final userData = await _userService.getUserById(targetUserId);

        if (userData != null) {
          setState(() {
            _userInfo = {
              'id': userData['id'], // Store ID
              'name': userData['name'] ?? 'No Name',
              'email': userData['email'] ?? '',
              'phone': userData['phone'] ?? '',
              'joinDate': userData['created_at'] ?? '',
              'imageUrl': userData['profile_image'] ?? '',
              'favorites': userData['favorites'] ?? [],
              'role': userData['role'] ?? 'petOwner',
              'username': userData['username'],
              'rating': userData['rating'], // Add real rating lookup
            };
            if (_isCurrentUser) {
              _nameController.text = _userInfo['name'] ?? '';
              _emailController.text = _userInfo['email'] ?? '';
              _phoneController.text = _userInfo['phone'] ?? '';
            }
          });
          
          _fetchStats(targetUserId);

          if (!_isCurrentUser) {
             _checkFriendshipStatus(targetUserId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchUserInfo(),
      _fetchPets(),
      _fetchUserPosts(),
    ]);
  }

  Future<void> _checkFriendshipStatus(String otherUserId) async {
     final status = await _friendService.getFriendshipStatus(otherUserId);
     if (mounted) {
       setState(() => _friendshipStatus = status);
     }
  }

  IconData _getFriendshipIcon() {
    switch (_friendshipStatus) {
      case 'accepted': return Icons.check_rounded;
      case 'pending_sent': return Icons.hourglass_top_rounded;
      case 'pending_received': return Icons.person_add_disabled_rounded;
      default: return Icons.person_add_rounded;
    }
  }

  String _formatRating(dynamic rating) {
    if (rating == null) return 'NEW';
    final val = (rating is num) ? rating.toDouble() : double.tryParse(rating.toString()) ?? 0.0;
    return val > 0 ? val.toStringAsFixed(1) : 'NEW';
  }

  String _getFriendshipLabel() {
    switch (_friendshipStatus) {
      case 'accepted': return 'Friends';
      case 'pending_sent': return 'Requested';
      case 'pending_received': return 'Respond';
      default: return 'Add Friend';
    }
  }
  
  Future<void> _handleFriendAction() async {
    final targetUserId = widget.userId;
    if (targetUserId == null) return;
    
    setState(() => _loadingSave = true);
    try {
      if (_friendshipStatus == 'none') {
        final success = await _friendService.sendFriendRequest(targetUserId);
        if (success) {
          setState(() => _friendshipStatus = 'pending_sent');
          AppNotifications.showSuccess(context, 'Friend request sent!');
        }
      } else if (_friendshipStatus == 'pending_received') {
        // Show dialog to accept or decline
        // For MVP quick action, let's just accept on click or show sheet
        // Ideally show a sheet.
        await _friendService.acceptFriendRequest(targetUserId);
        setState(() => _friendshipStatus = 'accepted');
         AppNotifications.showSuccess(context, 'Friend request accepted!');
      } else if (_friendshipStatus == 'accepted') {
         // Show options to unfriend
      }
    } catch (e) {
      AppNotifications.showError(context, 'Action failed');
    } finally {
      setState(() => _loadingSave = false);
    }
  }

  Future<void> _openChat() async {
    final targetUserId = widget.userId;
    if (targetUserId == null) return;

    try {
      final chatId = await _chatService.createChat(targetUserId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserName: _userInfo['name'] ?? 'User',
              otherUserImage: _userInfo['imageUrl'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      AppNotifications.showError(context, 'Could not open chat');
    }
  }
  Future<void> _fetchPets() async {
    try {
      final targetUserId = widget.userId ?? _authService.currentUser?.id;
      if (targetUserId != null) {
        final pets = await _petService.getPetsByUserId(targetUserId);
        setState(() {
          _pets = pets;
        });
      }
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final targetUserId = widget.userId ?? _authService.currentUser?.id;
      if (targetUserId != null) {
        final posts = await _postService.fetchPostsByUserId(targetUserId);
        setState(() {
          _userPosts = posts;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
    }
  }

  Future<void> _fetchStats(String userId) async {
    try {
      final appointments = await _appointmentService.getAppointmentCount(userId);
      final reviews = await _reviewService.getUserReviewCount(userId);
      if (mounted) {
        setState(() {
          _appointmentCount = appointments;
          _reviewCount = reviews;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<String?> uploadImageToStorage(File image, {String? folder}) async {
    try {
      final url = await _storageService.uploadImage(
        file: image,
        bucket: 'avatars',
        folder: folder,
      );
      return url;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // ignore: unused_element - Will be connected when profile editing is implemented
  Future<void> _pickImageFromGalleryForProfile() async {
    try {
      final pickedFile = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  // ignore: unused_element - Will be connected when profile editing is implemented  
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      AppNotifications.showWarning(context, 'Please fill all fields');
      return;
    }
    
    
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      String? imageUrl = _userInfo['imageUrl'] as String?;
      if (_profileImage != null) {
        imageUrl = await uploadImageToStorage(_profileImage!,
            folder: 'profile_images');
      }

      await _userService.updateUser(
        userId: user.id,
        name: name,
        phone: phone,
        profileImage: imageUrl,
      );

      setState(() {
        _userInfo['name'] = name;
        _userInfo['email'] = email;
        _userInfo['phone'] = phone;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _userInfo['imageUrl'] = imageUrl;
        }
        _profileImage = null;
      });

      if (mounted) AppNotifications.showSuccess(context, 'Profile updated successfully');
    } catch (e) {
      debugPrint('Save profile error: $e');
    } finally {
      await _fetchUserInfo();
    }
  }

  Future<void> _addNewPet() async {
     final result = await Navigator.push(
       context,
       MaterialPageRoute(builder: (_) => const AddPetScreen()),
     );
     
     if (result == true) {
       _fetchPets(); // Refresh list if added
     }
  }

  // ignore: unused_field - Stats display planned for future
  // final Map<String, String> _userStats = {
  //   'Pets': '2',
  //   'Appointments': '1',
  //   'Reviews': '4',
  // };



  ImageProvider? _buildProfileImageProvider() {
    if (_profileImage != null) return FileImage(_profileImage!);
    final imageUrl = (_userInfo['imageUrl'] ?? '').toString();
    if (imageUrl.isNotEmpty) return NetworkImage(imageUrl);
    return null;
  }

  Future<void> _showProfilePhotoOptions() async {
    ImagePickerHelper.showPickerModal(
      context,
      title: 'Profile Photo',
      onCamera: () => _pickImage(ImageSource.camera),
      onGallery: () => _pickImage(ImageSource.gallery),
      onRemove: (_profileImage != null || 
                 (_userInfo['imageUrl'] != null && _userInfo['imageUrl'].toString().isNotEmpty)) 
                 ? () => _removeProfilePhoto()
                 : null,
    );
  }

  // ignore: unused_element - Helper method preserved for future use
  Widget _buildPhotoOption(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive ? AppColors.error.withAlpha(26) : AppColors.secondary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? AppColors.error : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePickerHelper.pickAndCropImage(
      context,
      source: source,
      title: 'Crop Profile Photo',
    );
    
    if (file != null) {
      setState(() {
        _profileImage = file;
      });
      _saveProfilePhoto(); // Auto-save on selection
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
          await _userService.updateUser(
            userId: user.id,
            profileImage: null, // or empty string depending on DB
          );
          
          if (!mounted) return;
          setState(() {
            _profileImage = null;
            _userInfo['imageUrl'] = '';
          });
          
          AppNotifications.showSuccess(context, 'Profile photo removed');
      }
    } catch (e) {
        debugPrint("Error removing photo: $e");
         if (mounted) AppNotifications.showError(context, 'Failed to remove photo');
    }
  }

  Future<void> _saveProfilePhoto() async {
    if (_profileImage == null) return;

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Use the existing helper or service directly
        // We use a specific folder for profile images
        final imageUrl = await uploadImageToStorage(_profileImage!, folder: 'profile_images/${user.id}');
        
        if (imageUrl != null) {
             await _userService.updateUser(
                userId: user.id,
                profileImage: imageUrl,
             );
             
             setState(() {
                 _userInfo['imageUrl'] = imageUrl;
             });

             if (!mounted) return;
             AppNotifications.showSuccess(context, 'Profile photo updated');
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      if (mounted) AppNotifications.showError(context, 'Failed to upload photo');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        automaticallyImplyLeading: !_isCurrentUser,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isCurrentUser ? 'My Profile' : _userInfo['name'] ?? 'Profile',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _isCurrentUser ? 'Manage your account' : 'View profile',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(230),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
        ),
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
              SliverToBoxAdapter(
                child: _buildProfileHeaderCard(),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.xl),
                    _buildStatsRow(),
                    const SizedBox(height: AppSpacing.xl),
                    if (_userInfo['role'] != 'doctor') ...[
                      _buildSectionHeader('Pets', action: _isCurrentUser ? _addNewPet : null),
                      const SizedBox(height: AppSpacing.md),
                      _buildMyPetsList(),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    _buildSectionHeader('Posts'),
                    const SizedBox(height: AppSpacing.md),
                  ]),
                ),
              ),
              _userPosts.isEmpty 
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _buildEmptyPostsState(),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildPostItem(_userPosts[index]);
                          },
                          childCount: _userPosts.length,
                        ),
                      ),
                    ),
                  // Bottom spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          ),
          if (_loadingSave)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final imageProvider = _buildProfileImageProvider();
    
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.cloud,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top gradient banner
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryDiagonal,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
          
          // Avatar overlapping banner
          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                // Avatar with gradient ring
                GestureDetector(
                onTap: _isCurrentUser ? _showProfilePhotoOptions : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundImage: imageProvider,
                            backgroundColor: AppColors.cloud,
                            child: imageProvider == null
                                ? Text(
                                    (_userInfo['name'] ?? 'U').toString()[0].toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  )
                                : null,
                          ),
                          if (_isCurrentUser)
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primaryCta,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(50),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Name
                Text(
                  _userInfo['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                
                // Username
                if (_userInfo['username'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '@${_userInfo['username']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                
                
                // Role Badge
                if (_userInfo['role'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: _userInfo['role'] == 'doctor' 
                            ? AppGradients.primaryCta 
                            : AppGradients.warmHeader, // Distinct for Pet Owner
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (_userInfo['role'] == 'doctor' ? AppColors.primary : AppColors.accent).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _userInfo['role'] == 'doctor' ? Icons.medical_services_rounded : Icons.pets_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_userInfo['role'] == 'doctor' ? 'VETERINARIAN' : 'PET OWNER').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Action Buttons for visitors
                if (!_isCurrentUser) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Connect / Friend Button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryCta,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(50),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _handleFriendAction,
                              icon: Icon(_getFriendshipIcon(), size: 18),
                              label: Text(_getFriendshipLabel()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Message Button - Only enabled for accepted friends
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _friendshipStatus == 'accepted'
                                ? () => _openChat()
                                : () {
                                    AppNotifications.showInfo(context, 'Add friend first to send messages');
                                  },
                            icon: Icon(Icons.chat_bubble_outline_rounded, size: 18, 
                                color: _friendshipStatus == 'accepted' ? AppColors.primary : AppColors.slate),
                            label: Text('Message', 
                                style: TextStyle(color: _friendshipStatus == 'accepted' ? AppColors.primary : AppColors.slate)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _friendshipStatus == 'accepted' ? AppColors.primary : AppColors.slate,
                              side: BorderSide(
                                color: _friendshipStatus == 'accepted' 
                                    ? AppColors.primary.withAlpha(100) 
                                    : AppColors.slate.withAlpha(50), 
                                width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatsRow() {
    final isVet = _userInfo['role'] == 'doctor';
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isVet) ...[
             _buildStatItem(_formatRating(_userInfo['rating']), 'RATING'),
             Container(height: 40, width: 1, color: AppColors.borderLight),
             _buildStatItem('${_appointmentCount}', 'PATIENTS'), // 'Patients' or 'Bookings'
             Container(height: 40, width: 1, color: AppColors.borderLight),
             _buildStatItem('$_reviewCount', 'REVIEWS'), // Or Years Exp
          ] else ...[
             _buildStatItem('${_pets.length}', 'PETS'),
             Container(height: 40, width: 1, color: AppColors.borderLight),
             _buildStatItem('$_appointmentCount', 'BOOKINGS'),
             Container(height: 40, width: 1, color: AppColors.borderLight),
             _buildStatItem('$_reviewCount', 'REVIEWS'),
          ]
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        if (value == 'NEW')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: action,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.secondary),
            ),
          ),
      ],
    );
  }

  Widget _buildMyPetsList() {
    if (_pets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(Icons.pets, size: 48, color: AppColors.slate.withAlpha(77)),
            const SizedBox(height: 12),
            Text(
              'No pets added yet',
              style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _pets.map((pet) => _buildPetCard(pet)).toList(),
    );
  }
  
  // Reusing the pet card logic but with fresh styling
  Widget _buildPetCard(Pet pet) {
  final imageUrl = pet.imageUrl;
  final healthColor = pet.health.toLowerCase() == 'excellent' 
      ? AppColors.secondary 
      : pet.health.toLowerCase() == 'good' 
          ? Colors.blue 
          : AppColors.warning;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PetDetailsScreen(pet: pet),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Pet Image with gradient border
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryCta,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: AppColors.cloud,
                    image: imageUrl.isNotEmpty 
                        ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) 
                        : null,
                  ),
                  child: imageUrl.isEmpty 
                      ? Center(child: Text(pet.emoji, style: const TextStyle(fontSize: 32))) 
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Pet Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.charcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Type tag
                    Row(
                      children: [
                        _buildPetTag(pet.type, AppColors.primary),
                        if (pet.breed.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              pet.breed,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow with circle background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded, 
                  color: AppColors.primary, 
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildPetTag(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withAlpha(50), width: 1),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }



  Future<void> _toggleLike(Post post) async {
    final oldIsLiked = post.isLiked;
    final oldLikesCount = post.likesCount;

    // Optimistic Update
    setState(() {
      final index = _userPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _userPosts[index] = post.copyWith(
          isLiked: !oldIsLiked,
          likesCount: oldIsLiked ? oldLikesCount - 1 : oldLikesCount + 1,
        );
      }
    });

    final success = await _postService.toggleLike(post.id);
    if (!success) {
      // Revert if failed
      setState(() {
        final index = _userPosts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _userPosts[index] = post.copyWith(
            isLiked: oldIsLiked,
            likesCount: oldLikesCount,
          );
        }
      });
    }
  }

  void _showCommentsSheet(Post post) {
    CommentsSheet.show(
      context: context,
      post: post,
      postService: _postService,
      currentUserProfile: _isCurrentUser ? _userInfo : _myProfile,
      onCommentAdded: () {
        _fetchUserPosts(); // Refresh on comment
      },
    );
  }

  void _handleShare(Post post) {
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                AppNotifications.showSuccess(context, 'Link copied to clipboard');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(Post post) {
    return PostCard(
      post: post,
      onLike: () => _toggleLike(post),
      onComment: () => _showCommentsSheet(post),
      showHeartOverlay: false,
      onMoreOptions: _isCurrentUser ? () => _showPostOptionsMenu(post) : null,
    );
  }

  void _showPostOptionsMenu(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Post Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              // Edit Option
              _buildOptionTile(
                icon: Icons.edit_rounded,
                title: 'Edit Post',
                subtitle: 'Modify your post content',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _showEditPostDialog(post);
                },
              ),
              Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey[200]),
              // Delete Option
              _buildOptionTile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Post',
                subtitle: 'Remove permanently',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(post);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color == AppColors.error ? color : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPostDialog(Post post) {
    final editController = TextEditingController(text: post.content);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryCta,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Edit Post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      _performEditPost(post.id, editController.text.trim());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // User info row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    backgroundImage: post.author.profileImage.isNotEmpty
                        ? NetworkImage(post.author.profileImage)
                        : null,
                    child: post.author.profileImage.isEmpty
                        ? Text(post.author.name[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.charcoal,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.public, size: 12, color: AppColors.slate),
                          const SizedBox(width: 4),
                          Text(
                            'Public',
                            style: TextStyle(fontSize: 12, color: AppColors.slate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Text field
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: editController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: 18, color: AppColors.charcoal),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: TextStyle(color: AppColors.slate, fontSize: 18),
                    border: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performEditPost(int postId, String content) async {
    final success = await _postService.updatePost(
      postId: postId,
      content: content,
    );
    
    if (success) {
      _fetchUserPosts(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Post updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Failed to update post'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Post post) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Post?',
      message: 'This will permanently delete your post and all its comments. This action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_forever_rounded,
      isDestructive: true,
    );

    if (confirmed) {
      _performDeletePost(post.id);
    }
  }

  void _performDeletePost(int postId) async {
    final success = await _postService.deletePost(postId);
    
    if (success) {
      setState(() {
        _userPosts.removeWhere((p) => p.id == postId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Post deleted'),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Failed to delete post'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildEmptyPostsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.article_outlined, size: 48, color: AppColors.slate.withAlpha(77)),
          const SizedBox(height: 12),
          Text(
            _isCurrentUser ? 'Share your first post!' : 'No posts yet',
            style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

