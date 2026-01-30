import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/database_service.dart';

class AdminShopSettingsScreen extends StatefulWidget {
  const AdminShopSettingsScreen({super.key});

  @override
  State<AdminShopSettingsScreen> createState() =>
      _AdminShopSettingsScreenState();
}

class _AdminShopSettingsScreenState extends State<AdminShopSettingsScreen> {
  final TextEditingController _beneficiaryNameCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _upiIdCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _boutiqueNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _qrUrlCtrl = TextEditingController();
  final TextEditingController _instagramCtrl = TextEditingController();
  final TextEditingController _facebookCtrl = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await context.read<DatabaseService>().getSettings();
      setState(() {
        _beneficiaryNameCtrl.text = settings['upi_name'] ?? '';
        _bankNameCtrl.text = settings['upi_bank'] ?? '';
        _upiIdCtrl.text = settings['upi_id'] ?? '';
        _phoneCtrl.text = settings['shop_phone'] ?? '';
        _boutiqueNameCtrl.text = settings['shop_name'] ?? 'RKJ Fashions';
        _emailCtrl.text = settings['shop_email'] ?? '';
        _qrUrlCtrl.text =
            settings['qr_code_url'] ??
            'https://placehold.co/400x400/png?text=QR+Code';
        _instagramCtrl.text = settings['shop_instagram'] ?? '';
        _facebookCtrl.text = settings['shop_facebook'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings(Map<String, String> updates) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await context.read<DatabaseService>().updateSettings(updates);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _beneficiaryNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _upiIdCtrl.dispose();
    _phoneCtrl.dispose();
    _boutiqueNameCtrl.dispose();
    _emailCtrl.dispose();
    _qrUrlCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundUser,
      appBar: AppBar(
        title: const Text(
          'Shop & UPI Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textUser,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textUser),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // UPI Details Section
            _buildSection(
              title: 'UPI Payment Details',
              icon: Icons.payments,
              children: [
                _buildTextField(
                  'Beneficiary Name',
                  'e.g. Anjali Sharma',
                  _beneficiaryNameCtrl,
                ),
                const SizedBox(height: 16),
                _buildTextField('Bank Name', 'e.g. HDFC Bank', _bankNameCtrl),
                const SizedBox(height: 16),
                _buildTextField('UPI ID', 'username@bank', _upiIdCtrl),
                const SizedBox(height: 16),
                _buildTextField(
                  'Phone Number',
                  '98765 43210',
                  _phoneCtrl,
                  prefixText: '+91 ',
                ),
                const SizedBox(height: 24),
                _buildActionButton('UPDATE UPI DETAILS', Icons.save, () {
                  _updateSettings({
                    'upi_name': _beneficiaryNameCtrl.text,
                    'upi_bank': _bankNameCtrl.text,
                    'upi_id': _upiIdCtrl.text,
                    'shop_phone': _phoneCtrl.text,
                  });
                }),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code Section
            _buildSection(
              title: 'Shop QR Code',
              icon: Icons.qr_code_scanner,
              children: [
                _buildTextField('QR Code URL', 'https://...', _qrUrlCtrl),
                const SizedBox(height: 24),

                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.none,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        _qrUrlCtrl.text.isNotEmpty
                            ? _qrUrlCtrl.text
                            : 'https://placehold.co/400x400/png?text=QR+Code',
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildActionButton('UPDATE QR URL', Icons.link, () {
                  _updateSettings({'qr_code_url': _qrUrlCtrl.text});
                }, isOutlined: true),
              ],
            ),
            const SizedBox(height: 24),

            // Shop Profile Section
            _buildSection(
              title: 'Shop Profile',
              icon: Icons.storefront,
              children: [
                _buildTextField(
                  'Boutique Name',
                  'e.g. RKJ Fashions',
                  _boutiqueNameCtrl,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Contact Email',
                  'admin@boutique.com',
                  _emailCtrl,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Instagram Handle',
                  '@rkj_fashions',
                  _instagramCtrl,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Facebook URL',
                  'https://facebook.com/rkjfashions',
                  _facebookCtrl,
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  'UPDATE PROFILE',
                  Icons.edit_calendar_rounded,
                  () {
                    _updateSettings({
                      'shop_name': _boutiqueNameCtrl.text,
                      'shop_email': _emailCtrl.text,
                      'shop_instagram': _instagramCtrl.text,
                      'shop_facebook': _facebookCtrl.text,
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryUser.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryUser),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textUser,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String placeholder,
    TextEditingController controller, {
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixText: prefixText,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryUser),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primaryUser, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: AppColors.primaryUser,
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryUser,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: AppColors.primaryUser.withValues(alpha: 0.4),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
