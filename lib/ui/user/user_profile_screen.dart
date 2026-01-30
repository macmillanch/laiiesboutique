import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/models/user_model.dart';
import 'coupons_screen.dart';
import 'my_orders_screen.dart';
import 'notifications_screen.dart';
import 'referral_screen.dart';
import 'static_screens.dart';
import 'personal_details_screen.dart';
import 'my_addresses_screen.dart';
import 'wishlist_screen.dart';
import '../../main.dart';

class UserProfileScreen extends StatefulWidget {
  final bool showAppBar;
  const UserProfileScreen({super.key, this.showAppBar = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // We'll manage upload state locally if needed, but for now we just wait async
  bool _isUploading = false;
  bool _isAdminLoading = false;

  Future<void> _pickAndUploadImage(User user) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _isUploading = true);
      try {
        final storage = StorageService();
        final url = await storage.uploadImage(file, 'user_profiles');

        if (!mounted) return;
        await context.read<AuthService>().updateProfile(profileImageUrl: url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Auth Service for user changes
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundUser,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textUser),
              titleTextStyle: const TextStyle(
                color: AppColors.textUser,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Profile Header
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: user == null
                        ? null
                        : () => _pickAndUploadImage(user),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.primaryUser,
                              width: 2,
                            ),
                            image: user?.profileImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(user!.profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator()
                              : (user?.profileImageUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppColors.primaryUser,
                                      )
                                    : null),
                        ),
                        if (user != null && !_isUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryUser,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Guest User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textUser,
                    ),
                  ),
                  Text(
                    user?.email ?? user?.phone ?? 'Sign in to sync your data',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user != null)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User ID Copied!')),
                        );
                      },
                      child: Text(
                        'ID: ${user.displayId} (Tap to copy)',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Menu Items
            _buildSection(context, 'Account', [
              _buildMenuItem(
                context,
                Icons.person_outline,
                'Personal Details',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonalDetailsScreen(),
                  ),
                ),
              ),
              _buildMenuItem(
                context,
                Icons.location_on_outlined,
                'My Addresses',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
                ),
              ),
              _buildMenuItem(
                context,
                Icons.notifications_outlined,
                'Notifications',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              _buildMenuItem(
                context,
                Icons.card_giftcard,
                'Refer & Earn',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferralScreen()),
                ),
              ),
            ]),

            _buildSection(context, 'Orders & Shopping', [
              _buildMenuItem(
                context,
                Icons.local_shipping_outlined,
                'My Orders',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
              ),
              _buildMenuItem(context, Icons.favorite_border, 'Wishlist', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                );
              }),
              _buildMenuItem(
                context,
                Icons.local_offer_outlined,
                'My Coupons',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CouponsScreen()),
                ),
              ),
            ]),

            _buildSection(context, 'Support & Information', [
              _buildMenuItem(
                context,
                Icons.info_outline,
                'About Us',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              _buildMenuItem(
                context,
                Icons.contact_support_outlined,
                'Contact Us',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactScreen()),
                ),
              ),
              _buildMenuItem(
                context,
                Icons.help_outline,
                'Help & Support',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              _buildMenuItem(context, Icons.logout, 'Log Out', () async {
                await context.read<AuthService>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              }, isRed: true),
            ]),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textUser,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isRed = false,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRed
              ? Colors.red.withValues(alpha: 0.1)
              : AppColors.secondaryUser.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isRed ? Colors.red : AppColors.primaryUser,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isRed ? Colors.red : AppColors.textUser,
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textMuted,
          ),
      onTap: onTap,
    );
  }
}
