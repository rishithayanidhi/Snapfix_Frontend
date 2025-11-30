import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth.dart';
import 'location_service.dart';
import 'history.dart';
import 'complaint_service.dart';

final _secureStorage = const FlutterSecureStorage();

// Full-Featured ComplaintFormScreen
class ComplaintFormScreen extends StatefulWidget {
  final String category;
  final Map<String, dynamic> userData;

  const ComplaintFormScreen({
    super.key,
    required this.category,
    required this.userData,
  });

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  LocationData? _locationData;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String _urgency = 'Medium';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = await LocationService.getCurrentLocationWithAddress();
      if (mounted) {
        setState(() {
          _locationData = location;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (photo != null) {
        setState(() => _selectedImage = File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _submitComplaint() async {
    // Form validation
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fill in all required fields correctly'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Image validation
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📷 Please select an image of the issue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Location validation
    if (_locationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '📍 Location not available. Please enable GPS and try again.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get user data from secure storage
      String userName = widget.userData['full_name'] ?? 'Anonymous';
      String userEmail = widget.userData['email'] ?? '';

      // If not available from widget, try secure storage
      if (userName == 'Anonymous' || userEmail.isEmpty) {
        userName = await _secureStorage.read(key: 'user_name') ?? 'Anonymous';
        userEmail = await _secureStorage.read(key: 'user_email') ?? '';
      }

      print('📤 Submitting complaint:');
      print('  Name: $userName');
      print('  Email: $userEmail');
      print('  Category: ${widget.category}');
      print('  Title: ${_titleController.text.trim()}');
      print('  Urgency: $_urgency');
      print('  Location: ${_locationData!.address}');

      final response = await ComplaintService.submitComplaint(
        name: userName,
        email: userEmail,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: widget.category,
        urgency: _urgency,
        imageFile: _selectedImage!,
        latitude: _locationData!.latitude,
        longitude: _locationData!.longitude,
        address: _locationData!.address,
      );

      // Check response success
      if (!response.success || response.data == null) {
        throw Exception(response.error ?? 'Unknown error occurred');
      }

      print('✅ Complaint submitted successfully: ${response.data!.id}');

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complaint submitted successfully!\nID: ${response.data!.id.substring(0, 8)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on Exception catch (e) {
      print('❌ Submission error: $e');
      if (mounted) {
        String errorMessage = 'Failed to submit complaint';

        // Parse error message for user-friendly display
        final errorStr = e.toString();
        if (errorStr.contains('Network')) {
          errorMessage = '🌐 Network error. Please check your connection.';
        } else if (errorStr.contains('timeout')) {
          errorMessage = '⏱️ Request timeout. Please try again.';
        } else if (errorStr.contains('Invalid')) {
          errorMessage = '⚠️ Invalid data. Please check all fields.';
        } else if (errorStr.contains('401') || errorStr.contains('403')) {
          errorMessage = '🔒 Authentication error. Please login again.';
        } else if (errorStr.contains('500')) {
          errorMessage = '⚠️ Server error. Please try again later.';
        } else {
          errorMessage = '❌ $errorStr';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitComplaint,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: ComplaintFormScreen building for ${widget.category}');
    print('🔍 DEBUG: Location data: ${_locationData?.address ?? "null"}');
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Complaint'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Brief description of the issue',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Urgency Selector
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Urgency Level',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Low', 'Medium', 'High', 'Critical']
                          .map(
                            (level) => ChoiceChip(
                              label: Text(level),
                              selected: _urgency == level,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _urgency = level);
                                }
                              },
                              selectedColor: const Color(0xFF6366F1),
                              labelStyle: TextStyle(
                                color: _urgency == level
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedImage = null),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text('Add Photo Evidence'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: _isLoadingLocation
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Getting location...'),
                        ],
                      )
                    : _locationData != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Location',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _locationData!.address,
                            style: const TextStyle(fontSize: 13),
                            maxLines: null, // Allow unlimited lines
                            overflow: TextOverflow.visible, // Show full text
                            softWrap: true, // Wrap to new lines
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.location_off, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Location unavailable')),
                          TextButton(
                            onPressed: _getLocation,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Complaint',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _totalComplaints = 0;
  int _resolvedComplaints = 0;
  int _pendingComplaints = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final response = await ComplaintService.getPublicStats();
      if (response.success && response.data != null) {
        setState(() {
          _totalComplaints = response.data!['total']!;
          _resolvedComplaints = response.data!['resolved']!;
          _pendingComplaints = response.data!['pending']!;
          _isLoadingStats = false;
        });
        debugPrint(
          '📊 Stats loaded: $_totalComplaints total, $_resolvedComplaints resolved, $_pendingComplaints pending',
        );
      } else {
        setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStatistics,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildMainContent(context)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --------------------------------------------------------------
  // Header Section
  // --------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    final name = widget.userData['full_name'] ?? 'User';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name 👋',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Let’s make our city better!',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => HistoryDialog.showHistoryDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Main Content
  // --------------------------------------------------------------
  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCategoryGrid(context),
          const SizedBox(height: 20),
          _buildCommunityStats(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Categories (Static UI)
  // --------------------------------------------------------------
  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {
        'title': 'Roads',
        'icon': Icons.construction_rounded,
        'color': 0xFF3B82F6,
      },
      {
        'title': 'Garbage',
        'icon': Icons.delete_sweep_rounded,
        'color': 0xFF10B981,
      },
      {
        'title': 'Electricity',
        'icon': Icons.flash_on_rounded,
        'color': 0xFFF59E0B,
      },
      {'title': 'Water', 'icon': Icons.water_drop_rounded, 'color': 0xFF06B6D4},
      {
        'title': 'Others',
        'icon': Icons.more_horiz_rounded,
        'color': 0xFF8B5CF6,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final c = categories[i];
        return GestureDetector(
          onTap: () async {
            print('🔍 DEBUG: Category tapped: ${c['title']}');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  print(
                    '🔍 DEBUG: Building ComplaintFormScreen for ${c['title']}',
                  );
                  return ComplaintFormScreen(
                    category: c['title'] as String,
                    userData: widget.userData,
                  );
                },
              ),
            );
            // Refresh stats if complaint was successfully submitted
            if (result == true) {
              debugPrint('✅ Complaint submitted, refreshing stats...');
              _fetchStatistics();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(c['color'] as int),
                  Color(c['color'] as int).withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(c['color'] as int).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c['icon'] as IconData, color: Colors.white, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    c['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------
  // Dynamic Stats from Database
  // --------------------------------------------------------------
  Widget _buildCommunityStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _isLoadingStats
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  label: "Total",
                  count: _totalComplaints.toString(),
                  color: const Color(0xFF3B82F6),
                ),
                _StatCard(
                  label: "Resolved",
                  count: _resolvedComplaints.toString(),
                  color: const Color(0xFF10B981),
                ),
                _StatCard(
                  label: "Pending",
                  count: _pendingComplaints.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
    );
  }

  // --------------------------------------------------------------
  // Report Issue Container (Static Display)
  // --------------------------------------------------------------
  Widget _buildFab(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            'Report Issue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Logout Logic
  // --------------------------------------------------------------
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _secureStorage.deleteAll();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------
// Small Widgets
// --------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(height: 6),
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// --------------------------------------------------------------
// --------------------------------------------------------------
// (Report Options widget removed - button is now static display only)
// --------------------------------------------------------------
