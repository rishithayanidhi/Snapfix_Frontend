import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'complaint_service.dart';

class HistoryDialog {
  static void showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const _ComplaintHistoryDialog();
      },
    );
  }
}

class _ComplaintHistoryDialog extends StatefulWidget {
  const _ComplaintHistoryDialog();

  @override
  State<_ComplaintHistoryDialog> createState() =>
      _ComplaintHistoryDialogState();
}

class _ComplaintHistoryDialogState extends State<_ComplaintHistoryDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Complaint> _complaints = [];

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to get user email from secure storage
      final secureStorage = const FlutterSecureStorage();
      final userEmail = await secureStorage.read(key: 'user_email');

      ApiResponse<List<Complaint>> response;

      if (userEmail != null && userEmail.isNotEmpty) {
        // Fetch by email (works for both authenticated and unauthenticated users)
        debugPrint('📧 Fetching complaints for email: $userEmail');
        response = await ComplaintService.getComplaintsByEmail(userEmail);
      } else {
        // Fallback to authenticated endpoint
        debugPrint('🔒 Fetching authenticated user complaints');
        response = await ComplaintService.getUserComplaints();
      }

      if (response.success && response.data != null) {
        setState(() {
          _complaints = response.data!;
          _isLoading = false;
        });
        debugPrint('✅ Loaded ${_complaints.length} complaints');
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to fetch complaints.';
          _isLoading = false;
        });
        debugPrint('❌ Error: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('❌ Exception: $e');
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'in progress':
        return Icons.pending_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Complaint History',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorView()
                  : _complaints.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _fetchComplaints,
                      color: const Color(0xFF6366F1),
                      child: ListView.builder(
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) =>
                            _buildComplaintCard(_complaints[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final color = _statusColor(complaint.status);
    final icon = _statusIcon(complaint.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Row
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                complaint.status,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(complaint.createdAt),
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            complaint.title ?? complaint.category,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            complaint.description,
            style: GoogleFonts.inter(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (complaint.urgency != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _urgencyColor(complaint.urgency!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _urgencyColor(complaint.urgency!).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high_rounded,
                    size: 14,
                    color: _urgencyColor(complaint.urgency!),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complaint.urgency!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _urgencyColor(complaint.urgency!),
                    ),
                  ),
                ],
              ),
            ),
          if (complaint.urgency != null) const SizedBox(height: 8),
          if (complaint.locationAddress != null)
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    complaint.locationAddress!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Something went wrong.',
            style: GoogleFonts.inter(color: Colors.red.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _fetchComplaints,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, color: Colors.grey, size: 60),
          const SizedBox(height: 12),
          Text(
            'No complaints yet',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your complaint history will appear here.',
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }
}
