import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';

class NearbyUsersSheet extends StatefulWidget {
  final String roomCode;
  final String authToken;
  final String baseUrl;

  const NearbyUsersSheet({
    super.key,
    required this.roomCode,
    required this.authToken,
    required this.baseUrl,
  });

  @override
  State<NearbyUsersSheet> createState() => _NearbyUsersSheetState();
}

class _NearbyUsersSheetState extends State<NearbyUsersSheet> {
  List<_NearbyUser> _users = [];
  bool _loading = true;
  String? _error;

  // Tracks which userIds have been invited (to show INVITED state)
  final Set<String> _invitedIds = {};
  // Tracks which userIds are currently being invited (loading state)
  final Set<String> _invitingIds = {};
  // Tracks which userIds have been rejected locally
  final Set<String> _rejectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchNearbyUsers();
  }

  Future<void> _fetchNearbyUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/peers/same-network'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );
      if (response.statusCode == 200) {
        final List raw = jsonDecode(response.body) is List
            ? jsonDecode(response.body)
            : (jsonDecode(response.body)['users'] ?? []);
        setState(() {
          _users = raw
              .map((u) => _NearbyUser(
                    userId: (u['userId'] ?? u['id'] ?? '').toString(),
                    name: (u['name'] ?? u['username'] ?? 'Unknown').toString(),
                  ))
              .where((u) => u.userId.isNotEmpty)
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch nearby users (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _inviteUser(String userId) async {
    setState(() => _invitingIds.add(userId));
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/rooms/${widget.roomCode}/invite/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _invitedIds.add(userId));
      } else {
        _showError('Failed to invite user (${response.statusCode})');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      setState(() => _invitingIds.remove(userId));
    }
  }

  void _rejectUser(String userId) {
    setState(() => _rejectedIds.add(userId));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers =
        _users.where((u) => !_rejectedIds.contains(u.userId)).toList();

    return Container(
      decoration: const BoxDecoration(
        color: kDarkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kCyan.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NEARBY USERS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kCyan,
                    letterSpacing: 3,
                  ),
                ),
                GestureDetector(
                  onTap: _fetchNearbyUsers,
                  child: Icon(Icons.refresh_rounded,
                      color: kCyan.withOpacity(0.7), size: 18),
                ),
              ],
            ),
          ),

          Container(height: 1, color: kBorderDim),

          // Content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: _buildContent(visibleUsers),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContent(List<_NearbyUser> visibleUsers) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: kCyan,
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: kCyan.withOpacity(0.4), size: 32),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: kCyan.withOpacity(0.5),
                  letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchNearbyUsers,
              child: Text(
                'RETRY',
                style: TextStyle(
                  fontSize: 11,
                  color: kCyan,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (visibleUsers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.sensors_off_rounded,
                color: kCyan.withOpacity(0.3), size: 36),
            const SizedBox(height: 12),
            Text(
              'NO NEARBY USERS FOUND',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: kCyan.withOpacity(0.45),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: visibleUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _UserTile(
        user: visibleUsers[i],
        isInvited: _invitedIds.contains(visibleUsers[i].userId),
        isInviting: _invitingIds.contains(visibleUsers[i].userId),
        onAllow: () => _inviteUser(visibleUsers[i].userId),
        onReject: () => _rejectUser(visibleUsers[i].userId),
      ),
    );
  }
}

// ─── Data model ─────────────────────────────────────────
class _NearbyUser {
  final String userId;
  final String name;
  const _NearbyUser({required this.userId, required this.name});
}

// ─── User tile widget ────────────────────────────────────
class _UserTile extends StatelessWidget {
  final _NearbyUser user;
  final bool isInvited;
  final bool isInviting;
  final VoidCallback onAllow;
  final VoidCallback onReject;

  const _UserTile({
    required this.user,
    required this.isInvited,
    required this.isInviting,
    required this.onAllow,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderDim),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kCyan.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kCyan,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + id
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.userId.length > 12
                      ? '${user.userId.substring(0, 12)}...'
                      : user.userId,
                  style: TextStyle(
                    fontSize: 9,
                    color: kCyan.withOpacity(0.45),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          if (isInvited)
            _PillButton(
              label: 'INVITED ✓',
              color: kCyan.withOpacity(0.15),
              textColor: kCyan.withOpacity(0.6),
              enabled: false,
              onTap: null,
            )
          else if (isInviting)
            SizedBox(
              width: 70,
              height: 30,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: kCyan.withOpacity(0.7),
                  ),
                ),
              ),
            )
          else ...[
            _PillButton(
              label: 'REJECT',
              color: Colors.transparent,
              textColor: Colors.redAccent.withOpacity(0.7),
              borderColor: Colors.redAccent.withOpacity(0.3),
              enabled: true,
              onTap: onReject,
            ),
            const SizedBox(width: 6),
            _PillButton(
              label: 'ALLOW',
              color: kCyan.withOpacity(0.15),
              textColor: kCyan,
              borderColor: kCyan.withOpacity(0.5),
              enabled: true,
              onTap: onAllow,
            ),
          ],
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final bool enabled;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.borderColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor ?? Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
