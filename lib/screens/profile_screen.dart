// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'package:zovetica/services/pet_service.dart';
import 'package:zovetica/services/storage_service.dart';
import 'package:zovetica/services/post_service.dart';
import 'package:zovetica/services/friend_service.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../widgets/enterprise_header.dart';
import '../utils/app_notifications.dart';
import '../utils/image_picker_helper.dart'; // import the new helper
import 'pet_details_screen.dart';
import 'add_pet_screen.dart';

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
  
  Map<String, dynamic> _userInfo = {};
  List<Pet> _pets = [];
  List<Post> _userPosts = [];
  File? _profileImage;
  bool _editingProfile = false;
  bool _loadingSave = false;
  bool _isCurrentUser = true;
  String _friendshipStatus = 'none'; // 'none', 'pending_sent', 'pending_received', 'accepted', 'blocked'

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchPets();
    _fetchUserPosts();
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
            };
            if (_isCurrentUser) {
              _nameController.text = _userInfo['name'] ?? '';
              _emailController.text = _userInfo['email'] ?? '';
              _phoneController.text = _userInfo['phone'] ?? '';
            }
          });
          
          if (!_isCurrentUser) {
             _checkFriendshipStatus(targetUserId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      AppNotifications.showWarning(context, 'Please fill all fields');
      return;
    }
    
    setState(() => _loadingSave = true);

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
        if (imageUrl != null && imageUrl.isNotEmpty)
          _userInfo['imageUrl'] = imageUrl;
        _editingProfile = false;
        _profileImage = null;
      });

      AppNotifications.showSuccess(context, 'Profile updated successfully');
    } catch (e) {
      debugPrint('Save profile error: $e');
    } finally {
      setState(() => _loadingSave = false);
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

  final Map<String, String> _userStats = {

    'Pets': '2',
    'Appointments': '1',
    'Reviews': '4',
  };

  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

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
                color: isDestructive ? AppColors.error.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
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
    setState(() => _loadingSave = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
          await _userService.updateUser(
            userId: user.id,
            profileImage: null, // or empty string depending on DB
          );
          
          setState(() {
            _profileImage = null;
            _userInfo['imageUrl'] = '';
          });
          
          AppNotifications.showSuccess(context, 'Profile photo removed');
      }
    } catch (e) {
        debugPrint("Error removing photo: $e");
         AppNotifications.showError(context, 'Failed to remove photo');
    } finally {
        setState(() => _loadingSave = false);
    }
  }

  Future<void> _saveProfilePhoto() async {
    if (_profileImage == null) return;

    setState(() => _loadingSave = true);
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

             AppNotifications.showSuccess(context, 'Profile photo updated');
        }
      }
    } catch (e) {
      debugPrint('Error saving photo: $e');
      AppNotifications.showError(context, 'Failed to update photo');
    } finally {
      setState(() => _loadingSave = false);
    }
  }

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
                color: Colors.white.withOpacity(0.9),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeaderCard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                   const SizedBox(height: AppSpacing.xl),
                  _buildStatsRow(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Pets', action: _isCurrentUser ? _addNewPet : null),
                  const SizedBox(height: AppSpacing.md),
                  _buildMyPetsList(),
                  const SizedBox(height: AppSpacing.xl),
                  // Posts Section - Facebook-inspired timeline
                  _buildSectionHeader('Posts'),
                  const SizedBox(height: AppSpacing.md),
                  _buildUserPostsList(),
                  const SizedBox(height: AppSpacing.xl),
                  if (_isCurrentUser) ...[
                    _buildSectionHeader('Account'),
                    const SizedBox(height: AppSpacing.md),
                    _buildSettingsList(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildLogoutButton(),
                    const SizedBox(height: 100),
                  ] else ...[
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final imageProvider = _buildProfileImageProvider();
    
    return Transform.translate(
      offset: const Offset(0, -40), // Pull up to overlap header
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Enforce centering
          children: [
            // Avatar with Teal Ring
            GestureDetector(
              onTap: _isCurrentUser ? _showProfilePhotoOptions : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary, // Teal ring
                        width: 3
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: imageProvider,
                      backgroundColor: AppColors.secondary.withOpacity(0.1),
                      child: imageProvider == null
                          ? Text(
                              (_userInfo['name'] ?? 'U').toString()[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary),
                            )
                          : null,
                    ),
                  ),
                  if (_isCurrentUser)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Name & Subtitle (Centered)
            Text(
              _userInfo['name'] ?? 'User',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),

            
            // Action Buttons
            const SizedBox(height: 24),
            if (!_isCurrentUser) 
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Connect / Friend Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleFriendAction,
                      icon: Icon(_getFriendshipIcon(), size: 18),
                      label: Text(_getFriendshipLabel()), // Connect / Requested
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary, // Teal from image
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Message Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement Message
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary, // Teal text
                        side: const BorderSide(color: AppColors.secondary), // Teal border
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildStatsRow() {
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
          _buildStatItem('${_pets.length}', 'PETS'),
          Container(height: 40, width: 1, color: AppColors.borderLight),
          _buildStatItem('14', 'BOOKINGS'),
          Container(height: 40, width: 1, color: AppColors.borderLight),
          _buildStatItem('9', 'REVIEWS'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
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
                color: AppColors.secondary.withOpacity(0.1),
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
            Icon(Icons.pets, size: 48, color: AppColors.slate.withOpacity(0.3)),
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
     final imageUrl = (pet.imageUrl ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                 Container(
                   width: 60,
                   height: 60,
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(12),
                     color: AppColors.cloud,
                     image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                   ),
                   child: imageUrl.isEmpty ? Center(child: Text(pet.emoji, style: const TextStyle(fontSize: 28))) : null,
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         pet.name,
                         style: const TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 16,
                           color: AppColors.charcoal,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           _buildTag(pet.type, Colors.blue),
                           const SizedBox(width: 8),
                           Text(
                             pet.age,
                             style: TextStyle(fontSize: 13, color: AppColors.slate),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
                 Icon(Icons.chevron_right_rounded, color: AppColors.slate.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Widget _buildUserPostsList() {
    if (_userPosts.isEmpty) {
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
            Icon(Icons.article_outlined, size: 48, color: AppColors.slate.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              _isCurrentUser ? 'Share your first post!' : 'No posts yet',
              style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: _userPosts.map((post) => _buildProfilePostCard(post)).toList(),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(post: post, postService: _postService),
    ).then((_) {
      _fetchUserPosts(); // Refresh to get updated counts
    });
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

  Widget _buildProfilePostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0), // Clean card look
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                 CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: (post.author.profileImage.isNotEmpty)
                        ? NetworkImage(post.author.profileImage)
                        : null,
                    child: post.author.profileImage.isEmpty
                        ? Text(post.author.name.isNotEmpty ? post.author.name[0] : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                        : null,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.charcoal,
                        ),
                      ),
                      Text(
                        _formatPostTime(post.timestamp),
                        style: TextStyle(fontSize: 12, color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz_rounded, color: AppColors.slate),
              ],
            ),
          ),
          // Post Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 15, color: AppColors.charcoal, height: 1.4),
              ),
            ),
          // Post Image
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Image.network(
              post.imageUrl!,
              width: double.infinity,
              height: 250, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          // Engagement Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (post.likesCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary, 
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.thumb_up_rounded, color: Colors.white, size: 10),
                  ),
                  const SizedBox(width: 6),
                  Text('${post.likesCount}', style: TextStyle(fontSize: 13, color: AppColors.slate)),
                ],
                const Spacer(),
                if (post.commentsCount > 0)
                  Text('${post.commentsCount} comments', style: TextStyle(fontSize: 13, color: AppColors.slate)),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight.withOpacity(0.5)),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: _buildPostActionButton(
                  post.isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_off_alt_rounded, 
                  'Like', 
                  onTap: () => _toggleLike(post),
                  isActive: post.isLiked
                )),
                Expanded(child: _buildPostActionButton(
                  Icons.chat_bubble_outline_rounded, 
                  'Comment',
                  onTap: () => _showCommentsSheet(post),
                )),
                Expanded(child: _buildPostActionButton(
                  Icons.share_outlined, 
                  'Share',
                  onTap: () => _handleShare(post),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostActionButton(IconData icon, String label, {VoidCallback? onTap, bool isActive = false}) {
    final color = isActive ? AppColors.primary : AppColors.slate;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  String _formatPostTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingsTile(Icons.notifications_rounded, 'Notifications', null),
        _buildSettingsTile(Icons.lock_rounded, 'Privacy & Security', null),
        _buildSettingsTile(Icons.data_usage_rounded, 'Data Privacy', null),
        _buildSettingsTile(Icons.help_rounded, 'Help & Support', null),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.charcoal, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.charcoal)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.slate.withOpacity(0.5), size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildLogoutButton() {
     return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.logout_rounded, color: AppColors.error, size: 20)),
        title: Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.error)),
        onTap: _logout,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.charcoal),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.slate, size: 20),
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: AppColors.slate),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final Post post;
  final PostService postService;

  const _CommentsSheet({required this.post, required this.postService});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final comments = await widget.postService.fetchComments(widget.post.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _loading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newComment = await widget.postService.addComment(widget.post.id, text);
    if (newComment != null && mounted) {
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Sheet Header
          Container(
            padding: const EdgeInsets.all(16),
             decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
               children: [
                 const Spacer(),
                 const Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                 const Spacer(),
                 IconButton(
                   icon: const Icon(Icons.close),
                   onPressed: () => Navigator.pop(context),
                 )
               ] 
            ),
          ),
          // Comments List
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty 
                  ? const Center(child: Text('No comments yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: comment.author.profileImage.isNotEmpty 
                                    ? NetworkImage(comment.author.profileImage) 
                                    : null,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: comment.author.profileImage.isEmpty 
                                    ? Text(comment.author.name.isNotEmpty ? comment.author.name[0] : 'U', style: const TextStyle(fontSize: 12)) 
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cloud,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.author.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        filled: true,
                        fillColor: AppColors.cloud,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

