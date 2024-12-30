import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _loadJsonData() async {
    final String jsonString = await rootBundle
        .loadString('assets/privacyandterms/terms_of_use_voxigo.json');
    return jsonDecode(jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadJsonData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Terms of Use"),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Terms of Use"),
              centerTitle: true,
            ),
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Terms of Use"),
              centerTitle: true,
            ),
            body: const Center(
              child: Text("No data found"),
            ),
          );
        }

        final data = snapshot.data!['terms_of_use'];
        return Scaffold(
          appBar: AppBar(
            title: const Text("Terms of Use"),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Terms of Use",
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  data['welcome_message'] ?? '',
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                ),
                const SizedBox(height: 24.0),
                _buildSectionHeader('Acceptance of Terms'),
                _buildSubSection('', [
                  data['acceptance_of_terms']?['statement'] ?? '',
                  data['acceptance_of_terms']?['age_requirement'] ?? ''
                ]),
                _buildSectionHeader('User Responsibilities'),
                Text(
                  data['user_responsibilities']?['general_use'] ?? '',
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                ),
                const SizedBox(height: 16.0),
                _buildSubSection(
                  data['user_responsibilities']?['responsibilities_for_minors']
                          ?['statement'] ??
                      '',
                  data['user_responsibilities']?['responsibilities_for_minors']
                          ?['details'] ??
                      [],
                ),
                _buildSubSection('Disclaimer', [
                  data['disclaimer']?['statement'] ?? '',
                  data['disclaimer']?['accuracy_and_reliability'] ?? '',
                  data['disclaimer']?['third_party_services'] ?? '',
                  data['disclaimer']?['liability'] ?? ''
                ]),
                _buildSubSection('Limitation of Liability', [
                  data['limitation_of_liability']?['statement'] ?? '',
                  ...data['limitation_of_liability']?['details'] ?? [],
                  data['limitation_of_liability']?['acknowledgment'] ?? '',
                  data['limitation_of_liability']?['additional_terms']
                          ?['free_application'] ??
                      '',
                  data['limitation_of_liability']?['additional_terms']
                          ?['developer_rights'] ??
                      '',
                ]),
                _buildSubSection('Privacy and Data Protection',
                    [data['privacy_and_data_protection']?['statement'] ?? '']),
                _buildSubSection('Data Upload and Intellectual Property', [
                  ...data['data_upload_and_intellectual_property']
                          ?['user_responsibilities'] ??
                      [],
                  data['data_upload_and_intellectual_property']
                          ?['prohibited_content'] ??
                      '',
                  data['data_upload_and_intellectual_property']
                          ?['liability_statement'] ??
                      ''
                ]),
                _buildSubSection('Attribution', [
                  data['attribution']?['acknowledgment'] ?? '',
                  ...data['attribution']?['third_party_services'] ?? [],
                  data['attribution']?['agreement'] ?? ''
                ]),
                _buildSubSection('Revisions and Updates', [
                  data['revisions_and_updates']?['statement'] ?? '',
                  data['revisions_and_updates']?['encouragement'] ?? ''
                ]),
                _buildSubSection('Compliance with Laws',
                    [data['compliance_with_laws']?['statement'] ?? '']),
                _buildSubSection('Termination of Service', [
                  data['termination_of_service']?['statement'] ?? '',
                  ...data['termination_of_service']?['conditions'] ?? [],
                  data['termination_of_service']?['notice'] ?? ''
                ]),
                _buildSubSection('Contact Information',
                    ['Email: ${data['contact_information']?['email'] ?? ''}']),
                Text(
                  'Effective Date: ${data['effective_date'] ?? ''}',
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                ),
                const SizedBox(height: 16.0),
                Text(
                  data['acceptance_statement'] ?? '',
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubSection(String title, List<dynamic> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) _buildSectionHeader(title),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                '- $point',
                style: const TextStyle(fontSize: 16.0),
              ),
            )),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
