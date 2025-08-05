import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inviteme/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inviteme/pages/manage_invitations_page.dart';

class PartyCreatorPage extends StatefulWidget {
  const PartyCreatorPage({super.key});

  @override
  State<PartyCreatorPage> createState() => _PartyCreatorPageState();
}

class _PartyCreatorPageState extends State<PartyCreatorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Stream<List<Map<String, dynamic>>>? _partiesStream;
  final _formKey = GlobalKey<FormState>();
  final _partyNameController = TextEditingController();
  final _partyDateController = TextEditingController();
  final _partyLocationController = TextEditingController();
  final _partyDescriptionController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPartiesStream();
  }

  void _initPartiesStream() {
    _partiesStream = Supabase.instance.client
        .from('parties')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _partyNameController.dispose();
    _partyDateController.dispose();
    _partyLocationController.dispose();
    _partyDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _partyDateController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  Future<void> _createParty() async {
    if (_formKey.currentState!.validate()) {
      try {
        final supabase = SupabaseService();
        
        await Supabase.instance.client.from('parties').insert({
          'name': _partyNameController.text,
          'date': _partyDateController.text,
          'location': _partyLocationController.text,
          'description': _partyDescriptionController.text,
          'created_by': supabase.currentUser!.id,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Party created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _partyNameController.clear();
        _partyDateController.clear();
        _partyLocationController.clear();
        _partyDescriptionController.clear();
        setState(() {
          _selectedDate = null;
        });
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create party: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteParty(String partyId) async {
    try {
      await Supabase.instance.client
          .from('parties')
          .delete()
          .eq('id', partyId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Party deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete party: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editParty(Map<String, dynamic> party) {
    _partyNameController.text = party['name'];
    _partyDateController.text = party['date'];
    _partyLocationController.text = party['location'];
    _partyDescriptionController.text = party['description'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Party',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPartyForm(
                  onSubmit: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await Supabase.instance.client
                            .from('parties')
                            .update({
                              'name': _partyNameController.text,
                              'date': _partyDateController.text,
                              'location': _partyLocationController.text,
                              'description': _partyDescriptionController.text,
                            })
                            .eq('id', party['id']);

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Party updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update party: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  buttonText: 'Update Party',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _manageMembers(Map<String, dynamic> party) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageInvitationsPage(party: party),
      ),
    );
  }

  Widget _buildPartyList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _partiesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final parties = snapshot.data!;
        
        if (parties.isEmpty) {
          return Center(
            child: Text(
              'No parties created yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: parties.length,
          itemBuilder: (context, index) {
            final party = parties[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: ListTile(
                title: Text(
                  party['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${party['date']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Location: ${party['location']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'members',
                      child: Row(
                        children: [
                          Icon(Icons.people),
                          SizedBox(width: 8),
                          Text('Manage Members'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editParty(party);
                        break;
                      case 'members':
                        _manageMembers(party);
                        break;
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Party'),
                            content: const Text(
                              'Are you sure you want to delete this party? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteParty(party['id']);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        break;
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPartyForm({
    required VoidCallback onSubmit,
    required String buttonText,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _partyNameController,
            decoration: const InputDecoration(
              labelText: 'Party Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a party name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _partyDateController,
            decoration: InputDecoration(
              labelText: 'Party Date',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a date';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _partyLocationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _partyDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Party Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Parties'),
            Tab(text: 'Create Party'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPartyList(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildPartyForm(
              onSubmit: _createParty,
              buttonText: 'Create Party',
            ),
          ),
        ],
      ),
    );
  }
}