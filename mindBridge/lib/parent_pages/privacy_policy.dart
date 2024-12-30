import 'dart:convert';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final String jsonData = '''
{
  "title": "Privacy Policy for Voxigo",
  "description": "This privacy policy applies to the use of the Voxigo application (the \\\"application\\\"). We are committed to protecting your privacy and handling your personal data in compliance with any applicable laws and regulations. Below, we detail the types of personal data we collect, how we use it, and the measures we take to protect it.",
  "contactInformation": {
    "email": "VoxigoAAC@gmail.com"
  },
  "dataTypes": [
    {
      "title": "User Interactions with the Application",
      "details": [
        "Clicked Phrases: When a user selects phrases from the Speech Generating Device (SGD) grid, these interactions are stored to enhance the user experience and improve predictive sentence generation.",
        "Emotion Selections: Data regarding clicked emotions on the emotion-handling page is collected to support emotional communication features.",
        "SGD Grid Information: We store customized grid layouts, including buttons, folders, and associated images.",
        "Media Storage: Audio and image files uploaded or generated in the application, including on the music page and other designated sections, are stored for playback and customization purposes",
        "Settings: User-specific preferences, such as themes and access to AI features, are stored to personalize the application."
      ]
    },
    {
      "title": "Child Accounts",
      "details": [
        "Username, password, and name to enable secure access.",
        "Data regarding interactions within the application to support functionality and customization."
      ]
    },
    {
      "title": "Parent/Administrator Accounts",
      "details": [
        "Name, email address, linked child accounts, and password to facilitate account management and access control."
      ]
    },
    {
      "title": "AI-Powered Features",
      "details": [
        "The application uses data processed through third party APIs to power advanced AI features, including predictive sentence generation and chatbot functionalities. All data shared with APIs is anonymized."
      ]
    }
  ],
  "dataSecurity": {
    "points": [
      "Anonymized: Personal identifiers are removed wherever possible.",
      "Encrypted: Data is secured using industry standard or equivalent encryption protocols to safeguard from unauthorized access, loss, or misuse.",
      "Stored: Data is stored in a secure manner. No data is transmitted to unauthorized third parties."
    ]
  },
  "minors": {
    "description": "We recognize the importance of protecting the privacy of minors and are committed to adhering to applicable laws and regulations regarding their data. For users under the age of 18, the following provisions apply:",
    "provisions": [
      "Parental Consent: A parent or legal guardian must provide explicit consent at the time of account creation for children under the age of 18.",
      "Parents or legal guardians will review and agree to the terms and conditions of the application before account setup."
    ],
    "accountManagement": [
      "Child accounts are created and managed by parents, administrators, or caregivers.",
      "Login credentials, including the username and password, are set up by the parent, administrator, or caregiver.",
      "Permissions for accessing and operating the application are also configured and managed by the parent, administrator, or caregiver, ensuring appropriate controls and oversight."
    ],
    "dataLimitation": "Data collection for child accounts is strictly limited to the minimum necessary to provide core application functionalities. We do not collect sensitive or unnecessary information from minors."
  },
  "dataSharing": {
    "description": "We do not sell personal data to third parties or use it for advertising, profiling, or marketing purposes. Personal data will only be shared in the following circumstances:",
    "circumstances": [
      "With service providers or subcontractors who assist in application functionality (\\\"processors\\\"), subject to strict data processing agreements.",
      "With legal authorities, when required by law."
    ]
  },
  "thirdParty": "We integrate with third-party APIs, such as Gemini. While we ensure they comply with applicable regulations, we are not liable for their independent actions, breaches, or misuse of data outside of our control.",
  "liability": "We employ industry-standard practices to protect your data. However, no system can be guaranteed to be 100% secure. By using the application, you acknowledge and agree that application developers and operators shall not be liable for unauthorized access, data breaches, or other risks beyond our control.",
  "dataRetention": "We retain personal data only as long as necessary to fulfill the purposes outlined in this policy or to comply with legal obligations. Users may request the deletion of their data at any time, and we will respond within the statutory timeframe.",
  "rights": {
    "description": "You have the right to:",
    "list": [
      "Access, amend, or delete your personal data.",
      "Restrict or object to certain processing activities.",
      "Withdraw previously provided consent."
    ],
    "contact": "For inquiries or requests regarding your personal data, please contact us at VoxigoAAC@gmail.com."
  },
  "policyChanges": {
    "description": "We may update this policy to reflect changes in legal requirements or application functionalities. Users will be notified of material changes, and continued use of the application after such changes constitutes acceptance of the updated policy.",
    "effectiveDate": "January 1st, 2025"
  }
}
''';
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = jsonDecode(jsonData);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data['title'],
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
            _buildSubSection(
                'Data Storage and Security', data['dataSecurity']['points']),
            _buildMinorsSection(data['minors']),
            _buildSubSection(
                'Data Sharing', data['dataSharing']['circumstances']),
            _buildSectionHeader('Liability for Third-Party Integrations'),
            Text(
              data['thirdParty'],
              style: const TextStyle(fontSize: 16.0, height: 1.5),
            ),
            const SizedBox(height: 16.0),
            _buildSubSection('Limitation of Liability', [data['liability']]),
            _buildSubSection('Data Retention', [data['dataRetention']]),
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
            .map<Widget>((managementDetail) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text(
                    '- $managementDetail',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ))
            .toList(),
        const SizedBox(height: 16.0),
        _buildSectionHeader('Data Collection Limitation'),
        Text(
          minorsData['dataLimitation'],
          style: const TextStyle(fontSize: 16.0, height: 1.5),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }
}
