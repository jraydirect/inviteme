import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartyInvitationsPage extends StatefulWidget {
  const PartyInvitationsPage({super.key});

  @override
  State<PartyInvitationsPage> createState() => _PartyInvitationsPageState();
}

class _PartyInvitationsPageState extends State<PartyInvitationsPage> {
  Stream<List<Map<String, dynamic>>>? _invitationsStream;
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
    _setupInvitationsStream();
  }

  void _setupInvitationsStream() {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    _invitationsStream = Supabase.instance.client
        .from('party_invitations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    _invitationsStream?.listen((data) {
      _loadInvitations();
    });
  }

  Future<void> _loadInvitations() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
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

      if (!mounted) return;

      setState(() {
        _invitations = List<Map<String, dynamic>>.from(response);
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

  Future<void> _respondToInvitation(Map<String, dynamic> invitation, bool accept) async {
    try {
      // Start a transaction using RPC
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Party Invitations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadInvitations,
              child: Builder(
                builder: (context) {
                  final invitations = _invitations;

                  if (invitations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No invitations yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: invitations.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final invitation = invitations[index];
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
                },
              ),
            ),
    );
  }
}