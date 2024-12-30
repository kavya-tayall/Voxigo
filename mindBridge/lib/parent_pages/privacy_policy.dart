import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _loadJsonData() async {
    final String jsonString = await rootBundle
        .loadString('assets/privacyandterms/privacy_policy_voxigo.json');
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
              title: const Text("Privacy Policy"),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Privacy Policy"),
              centerTitle: true,
            ),
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Privacy Policy"),
              centerTitle: true,
            ),
            body: const Center(
              child: Text("No data found"),
            ),
          );
        }

        final data = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              data['title'],
              style:
                  const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Text(
                  data['description'],
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                ),
                const SizedBox(height: 24.0),
                _buildSectionHeader('Contact Information'),
                Text(
                  'Email: ${data['contactInformation']['email']}',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 24.0),
                _buildSectionList(data['dataTypes'],
                    'Types of Personal Data and Processing Purposes'),
                _buildSubSection('Data Storage and Security',
                    data['dataSecurity']['points']),
                _buildMinorsSection(data['minors']),
                _buildSubSection(
                    'Data Sharing', data['dataSharing']['circumstances']),
                _buildSectionHeader('Liability for Third-Party Integrations'),
                Text(
                  data['thirdParty'],
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                ),
                const SizedBox(height: 16.0),
                _buildSubSection(
                    'Limitation of Liability', [data['liability']]),
                _buildSubSection('Data Retention', [data['dataRetention']]),
                _buildSubSection('Google API', [data['googleAPI']]),
                _buildSubSection('Your Rights', data['rights']['list']),
                Text(
                  'Contact: ${data['rights']['contact']}',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 24.0),
                _buildSectionHeader('Changes to This Privacy Policy'),
                Text(
                  data['policyChanges']['description'],
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                ),
                Text(
                  'Effective Date: ${data['policyChanges']['effectiveDate']}',
                  style: const TextStyle(fontSize: 16.0),
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

  Widget _buildSectionList(List<dynamic> sections, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        ...sections.map((section) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title'],
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ...section['details'].map<Widget>((detail) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                        child: Text(
                          '- $detail',
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      )),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSubSection(String title, List<dynamic> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
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

  Widget _buildMinorsSection(Map<String, dynamic> minorsData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Minors'),
        Text(
          minorsData['description'],
          style: const TextStyle(fontSize: 16.0, height: 1.5),
        ),
        const SizedBox(height: 16.0),
        _buildSectionHeader('Provisions'),
        ...minorsData['provisions']
            .map<Widget>((provision) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text(
                    '- $provision',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ))
            .toList(),
        const SizedBox(height: 16.0),
        _buildSectionHeader('Account Management'),
        ...minorsData['accountManagement']
            .map<Widget>((item) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text(
                    '- $item',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ))
            .toList(),
        const SizedBox(height: 16.0),
        _buildSectionHeader('Data Limitation'),
        Text(
          minorsData['dataLimitation'],
          style: const TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }
}
