import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartiesPage extends StatefulWidget {
  const PartiesPage({super.key});

  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _invitations = [];
  List<Map<String, dynamic>> _availableParties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    
    // Listen for invitation changes
    Supabase.instance.client
        .from('party_invitations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          _loadData();
        });

    // Listen for party changes
    Supabase.instance.client
        .from('parties')
        .stream(primaryKey: ['id'])
        .listen((data) {
          _loadData();
        });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Load invitations with party details
      final invitationsResponse = await Supabase.instance.client
          .from('party_invitations')
          .select('''
            *,
            parties (
              id,
              name,
              date,
              location,
              description
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Load available parties (excluding ones user is already invited to)
      final partiesResponse = await Supabase.instance.client
          .from('parties')
          .select()
          .order('date', ascending: true);

      if (!mounted) return;

      setState(() {
        _invitations = List<Map<String, dynamic>>.from(invitationsResponse);
        _availableParties = List<Map<String, dynamic>>.from(partiesResponse);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _respondToInvitation(Map<String, dynamic> invitation, bool accept) async {
    try {
      await Supabase.instance.client.rpc(
        'handle_invitation_response',
        params: {
          'invitation_id': invitation['id'],
          'accept': accept,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Invitation accepted!' : 'Invitation declined'),
          backgroundColor: accept ? Colors.green : Colors.orange,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInvitationsList() {
    if (_invitations.isEmpty) {
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
                Icons.mail_outline,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No invitations yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone invites you to a party,\nit will appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _invitations.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final invitation = _invitations[index];
        final party = invitation['parties'];
        final isPending = invitation['status'] == 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.celebration),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        party['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${party['date']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Location: ${party['location']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (party['description'] != null && party['description'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    party['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (isPending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _respondToInvitation(invitation, false),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _respondToInvitation(invitation, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Accept',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: invitation['status'] == 'accepted'
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      invitation['status'] == 'accepted'
                          ? 'Accepted'
                          : 'Declined',
                      style: GoogleFonts.poppins(
                        color: invitation['status'] == 'accepted'
                            ? Colors.green[800]
                            : Colors.orange[800],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailablePartiesList() {
    if (_availableParties.isEmpty) {
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
                Icons.celebration_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to InviteMe!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover amazing parties in Miami,\nFort Lauderdale & Tampa',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎉 Party listings coming soon! 🎉',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _availableParties.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final party = _availableParties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(party['name']),
            subtitle: Text('${party['date']} - ${party['location']}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Parties',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Invitations'),
            Tab(text: 'Available'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInvitationsList(),
                _buildAvailablePartiesList(),
              ],
            ),
    );
  }
}