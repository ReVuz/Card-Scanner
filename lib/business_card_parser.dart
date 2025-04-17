import 'dart:convert';

class BusinessCardEntity {
  final String? name;
  final List<String> phoneNumbers;
  final List<String> emails;
  final List<String> urls;
  final String? address;

  BusinessCardEntity({
    this.name,
    required this.phoneNumbers,
    required this.emails,
    required this.urls,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone_numbers': phoneNumbers,
    'emails': emails,
    'urls': urls,
    'address': address,
  };

  String toJsonString() => jsonEncode(toJson());
}

class BusinessCardParser {
  static final RegExp _phoneRegExp = RegExp(
    r"(?:(?:\+?\d{1,3}[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)?(?:\d{3}[-.\s]?)?\d{4})",
    caseSensitive: false,
  );

  static final RegExp _emailRegExp = RegExp(
    r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
    caseSensitive: false,
  );

  static final RegExp _urlRegExp = RegExp(
    r"(?:https?:\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)",
    caseSensitive: false,
  );

  static final RegExp _zipcodeRegExp = RegExp(
    r"\b\d{5}(?:-\d{4})?\b",
    caseSensitive: false,
  );

  static BusinessCardEntity parse(String text) {
    final lines = text.split('\n');

    // Extract entities
    final phoneNumbers = _extractPhoneNumbers(text);
    final emails = _extractEmails(text);
    final urls = _extractUrls(text);
    final name = _extractName(lines, phoneNumbers, emails, urls);
    final address = _extractAddress(text, lines);

    return BusinessCardEntity(
      name: name,
      phoneNumbers: phoneNumbers,
      emails: emails,
      urls: urls,
      address: address,
    );
  }

  static List<String> _extractPhoneNumbers(String text) {
    final matches = _phoneRegExp.allMatches(text);
    final results = <String>[];

    for (final match in matches) {
      final phone = match.group(0)?.trim();
      if (phone != null && phone.length >= 7) {
        results.add(phone);
      }
    }

    return results;
  }

  static List<String> _extractEmails(String text) {
    final matches = _emailRegExp.allMatches(text);
    final results = <String>[];

    for (final match in matches) {
      final email = match.group(0)?.trim();
      if (email != null) {
        results.add(email);
      }
    }

    return results;
  }

  static List<String> _extractUrls(String text) {
    final matches = _urlRegExp.allMatches(text);
    final results = <String>[];

    for (final match in matches) {
      final url = match.group(0)?.trim();
      if (url != null) {
        // Filter out email domains incorrectly matched as URLs
        if (!url.contains('@') && url.contains('.')) {
          results.add(url);
        }
      }
    }

    return results;
  }

  static String? _extractName(
    List<String> lines,
    List<String> phoneNumbers,
    List<String> emails,
    List<String> urls,
  ) {
    // Simple heuristic: The name is often the first non-empty line
    // that isn't a phone, email or URL
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Skip lines that contain phone numbers, emails or URLs
      bool containsContactInfo = false;
      for (final phone in phoneNumbers) {
        if (trimmedLine.contains(phone)) {
          containsContactInfo = true;
          break;
        }
      }

      if (!containsContactInfo) {
        for (final email in emails) {
          if (trimmedLine.contains(email)) {
            containsContactInfo = true;
            break;
          }
        }
      }

      if (!containsContactInfo) {
        for (final url in urls) {
          if (trimmedLine.contains(url)) {
            containsContactInfo = true;
            break;
          }
        }
      }

      if (!containsContactInfo) {
        return trimmedLine;
      }
    }

    return lines.isNotEmpty ? lines[0].trim() : null;
  }

  static String? _extractAddress(String text, List<String> lines) {
    // Look for lines with postal codes
    final addressLines = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Check for address indicators
      if (_zipcodeRegExp.hasMatch(trimmedLine)) {
        addressLines.add(trimmedLine);

        // Also add the line before if it exists and isn't a contact method
        final lineIndex = lines.indexOf(line);
        if (lineIndex > 0) {
          final prevLine = lines[lineIndex - 1].trim();
          if (prevLine.isNotEmpty &&
              !_phoneRegExp.hasMatch(prevLine) &&
              !_emailRegExp.hasMatch(prevLine) &&
              !_urlRegExp.hasMatch(prevLine)) {
            addressLines.insert(0, prevLine);
          }
        }
      } else if (trimmedLine.contains('St') ||
          trimmedLine.contains('Street') ||
          trimmedLine.contains('Ave') ||
          trimmedLine.contains('Avenue') ||
          trimmedLine.contains('Rd') ||
          trimmedLine.contains('Road') ||
          trimmedLine.contains('Blvd') ||
          trimmedLine.contains('Boulevard')) {
        addressLines.add(trimmedLine);
      }
    }

    return addressLines.isNotEmpty ? addressLines.join(', ') : null;
  }
}
