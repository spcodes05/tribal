import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../services/trusted_contacts_service.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoadingContacts = true;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final contacts = await TrustedContactsService.instance.getTrustedContacts();
      if (mounted) setState(() => _contacts = contacts);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load trusted contacts.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await TrustedContactsService.instance.searchUsers(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      // silent — keep previous results
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _addContact(int userId) async {
    try {
      await TrustedContactsService.instance.addTrustedContact(userId);
      setState(() {
        _showSearch = false;
        _searchController.clear();
        _searchResults = [];
      });
      await _fetchContacts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trusted contact added.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to add contact.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _deleteContact(int id) async {
    try {
      await TrustedContactsService.instance.deleteTrustedContact(id);
      await _fetchContacts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trusted contact removed.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to remove contact.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trusted Contacts',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primary),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showSearch) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
                    prefixIcon: const Icon(Icons.search, color: Colors.black45),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CircularProgressIndicator(),
                )
              else if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final fullName = user['full_name'] as String? ?? 'Unknown';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD9D9D9),
                          child: Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(color: Colors.black87),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          user['email'] as String? ?? '',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.person_add, color: AppColors.primary),
                          onPressed: () => _addContact(user['id'] as int),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(height: 1),
            ],
            Expanded(
              child: _isLoadingContacts
                  ? const Center(child: CircularProgressIndicator())
                  : _contacts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _fetchContacts,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final detail = contact['trusted_user_detail'] as Map<String, dynamic>?;
                    final name = detail?['full_name'] as String? ?? 'Unknown';
                    final email = detail?['email'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFD9D9D9),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(color: Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteContact(contact['id'] as int),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              'No trusted contacts yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add someone you trust to be notified in an emergency.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}