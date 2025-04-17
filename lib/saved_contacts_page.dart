import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'business_card_parser.dart';
import 'database_helper.dart';
import 'business_card_result.dart';

class SavedContactsPage extends StatefulWidget {
  const SavedContactsPage({Key? key}) : super(key: key);

  @override
  State<SavedContactsPage> createState() => _SavedContactsPageState();
}

class _SavedContactsPageState extends State<SavedContactsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _savedContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    setState(() {
      _isLoading = true;
    });

    final contacts = await _dbHelper.getBusinessCards();

    setState(() {
      _savedContacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _deleteContact(int id, int index) async {
    await _dbHelper.deleteBusinessCard(id);
    setState(() {
      _savedContacts.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contact deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Contacts')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _savedContacts.isEmpty
              ? const Center(child: Text('No saved contacts'))
              : ListView.builder(
                itemCount: _savedContacts.length,
                itemBuilder: (context, index) {
                  final contact = _savedContacts[index];
                  final name = contact['name'] ?? 'Unnamed Contact';
                  final id = contact['id'] as int;

                  return Dismissible(
                    key: Key(id.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _deleteContact(id, index);
                    },
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        'Created on: ${DateTime.parse(contact['created_at']).toLocal().toString().split('.')[0]}',
                      ),
                      leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                      onTap: () async {
                        final businessCard = await _dbHelper
                            .businessCardFromMap(contact);
                        if (!mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => BusinessCardResultPage(
                                  parsedData: businessCard,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
