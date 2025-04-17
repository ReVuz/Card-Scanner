import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'business_card_parser.dart';
import 'database_helper.dart'; // Add this import

class BusinessCardResultPage extends StatefulWidget {
  // Change to StatefulWidget
  final BusinessCardEntity parsedData;
  final String originalText; // Add this field

  const BusinessCardResultPage({
    Key? key,
    required this.parsedData,
    this.originalText = '', // Make it optional with default value
  }) : super(key: key);

  @override
  _BusinessCardResultPageState createState() => _BusinessCardResultPageState();
}

class _BusinessCardResultPageState extends State<BusinessCardResultPage> {
  bool _isSaving = false;
  bool _isSaved = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> _saveContact() async {
    if (_isSaved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contact already saved')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _dbHelper.saveBusinessCard(widget.parsedData, widget.originalText);

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved successfully')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving contact: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: widget.parsedData.toJsonString()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCardDetails(),
      ),
    );
  }

  Widget _buildCardDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.parsedData.name != null) ...[
            _buildInfoSection('Name', [widget.parsedData.name!]),
            const SizedBox(height: 16),
          ],

          if (widget.parsedData.phoneNumbers.isNotEmpty) ...[
            _buildInfoSection('Phone Numbers', widget.parsedData.phoneNumbers),
            const SizedBox(height: 16),
          ],

          if (widget.parsedData.emails.isNotEmpty) ...[
            _buildInfoSection('Email Addresses', widget.parsedData.emails),
            const SizedBox(height: 16),
          ],

          if (widget.parsedData.urls.isNotEmpty) ...[
            _buildInfoSection('Websites/URLs', widget.parsedData.urls),
            const SizedBox(height: 16),
          ],

          if (widget.parsedData.address != null) ...[
            _buildInfoSection('Address', [widget.parsedData.address!]),
            const SizedBox(height: 16),
          ],

          const Divider(),

          ExpansionTile(
            title: const Text('JSON Data'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.parsedData.toJsonString(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.parsedData.toJsonString()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('JSON copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy JSON'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Center(
            child:
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                      onPressed: _isSaved ? null : _saveContact,
                      icon:
                          _isSaved
                              ? const Icon(Icons.check)
                              : const Icon(Icons.save),
                      label: Text(_isSaved ? 'Saved' : 'Save Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        ...items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item)),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$title copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
