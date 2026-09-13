import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../announcement/presentation/pages/announcement_image_view_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _sessionManager = SessionManager();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  bool _isUploading = false;
  String? _localCroppedPath;
  int _imageVersion = DateTime.now().millisecondsSinceEpoch;

  void _openProfileImageViewer(String imageUrl, String title) {
    if (_localCroppedPath != null) {
      // Local image preview if recently changed
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_localCroppedPath!),
                  fit: BoxFit.contain,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnnouncementImageViewPage(
          imageUrl: '$imageUrl&v=$_imageVersion',
          title: title,
        ),
      ),
    );
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _sessionManager.getUser();
    if (user == null || user.nim == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );

      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
        maxWidth: 1000,
        maxHeight: 1000,
        compressFormat: ImageCompressFormat.png,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n.changeProfilePhoto,
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.ratio4x3,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: l10n.changeProfilePhoto,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) return;

      if (!mounted) return;
      setState(() {
        _isUploading = true;
      });

      final file = File(croppedFile.path);
      final bytes = await file.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final tahunAngkatan = user.angkatan?.toString().substring(0, 4) ?? '2024';
      final response = await _apiService.uploadProfilePhoto(
        nim: user.nim!,
        angkatan: tahunAngkatan,
        imageBase64: imageBase64,
      );

      if (!mounted) return;

      final success = response['success'] == true;
      final message = response['message']?.toString() ??
          (success ? l10n.profilePhotoUpdated : l10n.profilePhotoFailed);

      if (success) {
        setState(() {
          _localCroppedPath = croppedFile.path;
          _imageVersion = DateTime.now().millisecondsSinceEpoch;
        });
      }

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor:
              success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l10n.profilePhotoFailed}: $e',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showComingSoonSnackBar(String featureName) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$featureName: ${l10n.featureUnderDevelopment}',
                style: const TextStyle(fontSize: 12.5, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPhotoOptionsSheet(
    BuildContext context,
    AppLocalizations l10n,
    String profileUrl,
    String userName,
  ) {
    if (_isUploading) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.changeProfilePhoto,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.viewFullPhoto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _openProfileImageViewer(profileUrl, userName);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_enhance_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.takePhoto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickAndCropImage(ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.chooseFromGallery,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickAndCropImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _sessionManager.getUser();

    final tahunAngkatan = user?.angkatan?.toString().substring(0, 4) ?? '2024';
    final nimOnlyNumber = user?.nim?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final profileUrl =
        'https://si-mona.uinsalatiga.ac.id/user_log/view_image?angkatan=$tahunAngkatan&nim=$nimOnlyNumber';
    final userName = user?.nama ?? l10n.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.profile,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Photo Card with Camera Logo Badge
                _buildProfilePhotoCard(
                  context,
                  l10n,
                  profileUrl,
                  userName,
                  user,
                ),
                const SizedBox(height: 24),

                // Sub Menu Section: Data Pribadi & Data Orang Tua
                _buildMenuSection(l10n.studentInfo, [
                  _buildMenuItem(
                    Icons.person_outline_rounded,
                    l10n.personalData,
                    l10n.personalDataSubtitle,
                    () => _showComingSoonSnackBar(l10n.personalData),
                  ),
                  _buildMenuItem(
                    Icons.family_restroom_rounded,
                    l10n.parentsData,
                    l10n.parentsDataSubtitle,
                    () => _showComingSoonSnackBar(l10n.parentsData),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoCard(
    BuildContext context,
    AppLocalizations l10n,
    String profileUrl,
    String userName,
    dynamic user,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Avatar with small floating camera icon underneath
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => _openProfileImageViewer(profileUrl, userName),
                  child: Container(
                    width: 104,
                    height: 104,
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_localCroppedPath != null)
                            Image.file(
                              File(_localCroppedPath!),
                              fit: BoxFit.cover,
                            )
                          else
                            Image.network(
                              '$profileUrl&v=$_imageVersion',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 54,
                                ),
                              ),
                            ),
                          if (_isUploading)
                            Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: const Center(
                                child: SpinKitRing(
                                  color: Colors.white,
                                  size: 32,
                                  lineWidth: 3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Small camera logo at the bottom
                Positioned(
                  bottom: 0,
                  right: 2,
                  child: Material(
                    color: _isUploading ? Colors.grey : AppColors.primary,
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    child: InkWell(
                      onTap: _isUploading
                          ? null
                          : () => _showPhotoOptionsSheet(
                                context,
                                l10n,
                                profileUrl,
                                userName,
                              ),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User Name & NIM
          Text(
            userName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.nim ?? '-',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${user?.jenjang ?? ''} • ${user?.programStudi ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 60,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      hoverColor: AppColors.primary.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
