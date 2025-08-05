import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageInvitationsPage extends StatefulWidget {
  final Map<String, dynamic> party;

  const ManageInvitationsPage({
    super.key,
    required this.party,
  });

  @override
  State<ManageInvitationsPage> createState() => _ManageInvitationsPageState();
}

class _ManageInvitationsPageState extends State<ManageInvitationsPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _invitedUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get invitations without user details first
      final invitationsResponse = await Supabase.instance.client
          .from('party_invitations')
          .select('id, party_id, status, created_at, user_id')
          .eq('party_id', widget.party['id']);

      // Get members without user details first
      final membersResponse = await Supabase.instance.client
          .from('party_members')
          .select('id, party_id, user_id, joined_at')
          .eq('party_id', widget.party['id']);

      final invitations = List<Map<String, dynamic>>.from(invitationsResponse);
      final members = List<Map<String, dynamic>>.from(membersResponse);

      // Get all unique user IDs
      final userIds = <String>{};
      for (var invitation in invitations) {
        userIds.add(invitation['user_id']);
      }
      for (var member in members) {
        userIds.add(member['user_id']);
      }

      // Fetch user details for all user IDs
      Map<String, Map<String, dynamic>> userDetails = {};
      if (userIds.isNotEmpty) {
        final userResponse = await Supabase.instance.client
            .from('user_profiles')
            .select('id, email')
            .inFilter('id', userIds.toList());
        
        final users = List<Map<String, dynamic>>.from(userResponse);
        for (var user in users) {
          userDetails[user['id']] = user;
        }
      }

      // Add user details to invitations
      for (var invitation in invitations) {
        final userId = invitation['user_id'];
        invitation['user_profiles'] = userDetails[userId] ?? {'email': 'Unknown'};
        invitation['is_member'] = members.any(
          (member) => member['user_id'] == invitation['user_id'],
        );
      }

      setState(() {
        _invitedUsers = invitations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading invitations: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search for users by email using RPC function
      final response = await Supabase.instance.client
          .rpc('search_users_by_email', params: {'search_query': query});

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching users: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _inviteUser(Map<String, dynamic> user) async {
    try {
      // Check if user is already invited
      final alreadyInvited = _invitedUsers.any(
        (invited) => invited['user_id'] == user['id'],
      );

      if (alreadyInvited) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User is already invited to this party'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await Supabase.instance.client.from('party_invitations').insert({
        'party_id': widget.party['id'],
        'user_id': user['id'],
      });

      // Clear search and reload invitations
      _searchController.clear();
      setState(() {
        _searchResults = [];
      });
      await _loadInvitations();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending invitation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeInvitation(Map<String, dynamic> invitation) async {
    try {
      await Supabase.instance.client
          .from('party_invitations')
          .delete()
          .eq('id', invitation['id']);

      await _loadInvitations();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing invitation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAttendeesList() {
    // Filter for accepted invitations/current members
    final attendees = _invitedUsers.where((inv) => inv['status'] == 'accepted').toList();

    if (attendees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No attendees yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: attendees.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final attendee = attendees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: Color(0xFF6C63FF),
              ),
            ),
            title: Text(
              attendee['user_profiles']['email'] as String,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Joined: ${DateTime.parse(attendee['created_at']).toLocal().toString().split('.')[0]}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeInvitation(attendee),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingInvitesList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Search Results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchResults.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    title: Text(
                      user['email'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.person_add,
                        color: Color(0xFF6C63FF),
                      ),
                      onPressed: () => _inviteUser(user),
                    ),
                  ),
                );
              },
            ),

          // Pending Invitations
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pending Invitations',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Pending Invites List
          Builder(
            builder: (context) {
              final pendingInvites = _invitedUsers
                  .where((inv) => inv['status'] == 'pending')
                  .toList();

              if (pendingInvites.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No pending invitations',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingInvites.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final invite = pendingInvites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: Icon(
                          Icons.schedule,
                          color: Colors.orange[800],
                        ),
                      ),
                      title: Text(
                        invite['user_profiles']['email'] as String,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Invited: ${DateTime.parse(invite['created_at']).toLocal().toString().split('.')[0]}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.person_remove,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeInvitation(invite),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Manage Party',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Invitations'),
              Tab(text: 'Attendees'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  _buildPendingInvitesList(),
                  _buildAttendeesList(),
                ],
              ),
      ),
    );
  }
}