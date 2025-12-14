import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.update_rounded,
                          title: 'Last Updated',
                          subtitle: 'December 14, 2025',
                        ),
                        const SizedBox(height: 24),
                        
                        _buildIntroText(),
                        const SizedBox(height: 28),
                        
                        _buildSection(
                          number: '1',
                          title: 'Information We Collect',
                          content: '''
When you use The Eduverse, we may collect the following types of information:

• **Personal Information**: Name, email address, phone number, and profile picture that you provide during registration.

• **Educational Data**: Course progress, quiz scores, study materials accessed, and learning preferences.

• **Device Information**: Device type, operating system, unique device identifiers, and mobile network information.

• **Usage Data**: How you interact with our app, including pages visited, features used, and time spent learning.

• **Payment Information**: Payment details are processed securely through third-party payment processors (like Razorpay). We do not store your complete payment card details.''',
                        ),
                        
                        _buildSection(
                          number: '2',
                          title: 'How We Use Your Information',
                          content: '''
We use the collected information for the following purposes:

• **Personalized Learning**: To customize your educational experience and recommend relevant courses.

• **Account Management**: To create and maintain your account, and communicate with you about your account.

• **Service Improvement**: To analyze usage patterns and improve our educational content and platform features.

• **Customer Support**: To respond to your inquiries and provide technical assistance.

• **Notifications**: To send you important updates about courses, new features, and promotional offers (with your consent).

• **Security**: To detect, prevent, and address technical issues and fraudulent activities.''',
                        ),
                        
                        _buildSection(
                          number: '3',
                          title: 'Data Sharing & Disclosure',
                          content: '''
We do not sell your personal information. We may share your data only in these circumstances:

• **Service Providers**: With trusted third-party services (cloud storage, analytics, payment processors) that help us operate our platform.

• **Instructors**: Enrolled course instructors may access your name and progress data to provide better educational support.

• **Legal Requirements**: When required by law, court order, or governmental authority.

• **Business Transfers**: In connection with any merger, acquisition, or sale of company assets.

• **With Your Consent**: When you explicitly agree to share your information with third parties.''',
                        ),
                        
                        _buildSection(
                          number: '4',
                          title: 'Data Security',
                          content: '''
We implement industry-standard security measures to protect your information:

• **Encryption**: All data transmitted between your device and our servers is encrypted using SSL/TLS protocols.

• **Secure Storage**: Your data is stored on secure servers provided by Google Cloud Platform/Firebase.

• **Access Controls**: Only authorized personnel have access to user data, and all access is logged and monitored.

• **Regular Audits**: We conduct periodic security assessments to identify and address vulnerabilities.

While we strive to protect your information, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security.''',
                        ),
                        
                        _buildSection(
                          number: '5',
                          title: 'Your Rights & Choices',
                          content: '''
You have the following rights regarding your personal data:

• **Access**: You can request a copy of your personal data that we hold.

• **Correction**: You can update or correct your profile information at any time through the app settings.

• **Deletion**: You can request deletion of your account and associated data by contacting our support team.

• **Opt-Out**: You can opt out of promotional communications through notification settings.

• **Data Portability**: You can request your data in a commonly used, machine-readable format.

To exercise any of these rights, please contact us using the information provided below.''',
                        ),
                        
                        _buildSection(
                          number: '6',
                          title: 'Children\'s Privacy',
                          content: '''
The Eduverse is intended for users of all ages with appropriate parental/guardian supervision for minors.

• If you are under 18, please use our services only with the involvement of a parent or guardian.

• We do not knowingly collect personal information from children under 13 without parental consent.

• If we learn that we have collected information from a child under 13 without parental consent, we will delete that information promptly.

Parents/guardians can contact us to review, update, or delete their child's information.''',
                        ),
                        
                        _buildSection(
                          number: '7',
                          title: 'Cookies & Tracking Technologies',
                          content: '''
We use cookies and similar technologies to enhance your experience:

• **Essential Cookies**: Required for the app to function properly (authentication, preferences).

• **Analytics**: To understand how users interact with our app and improve our services.

• **Performance**: To monitor app performance and identify issues.

You can manage cookie preferences through your device settings, though some features may not work properly if cookies are disabled.''',
                        ),
                        
                        _buildSection(
                          number: '8',
                          title: 'Changes to This Policy',
                          content: '''
We may update this Privacy Policy from time to time. We will notify you of any significant changes by:

• Posting the new policy on our app
• Sending you an email notification (if applicable)
• Displaying an in-app notification

We encourage you to review this policy periodically. Continued use of our services after changes constitutes acceptance of the updated policy.''',
                        ),
                        
                        _buildSection(
                          number: '9',
                          title: 'Contact Us',
                          content: '''
If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:

📧 **Email**: support@theeduverse.com
📱 **In-App Support**: Profile → Help & Support
📍 **Address**: The Eduverse, India

We will respond to your inquiry within 48 hours during business days.''',
                        ),
                        
                        const SizedBox(height: 24),
                        _buildFooterNote(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.1),
            const Color(0xFF764ba2).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667eea).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF667eea),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroText() {
    return Text(
      'At The Eduverse, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, share, and safeguard your data when you use our educational platform.',
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _buildFormattedContent(content),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    final lines = content.trim().split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) {
          return const SizedBox(height: 8);
        }
        
        // Check if line is a bullet point
        if (trimmedLine.startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF667eea),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildRichText(trimmedLine.substring(1).trim()),
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildRichText(trimmedLine),
        );
      }).toList(),
    );
  }

  Widget _buildRichText(String text) {
    // Simple bold text parsing for **text** format
    final RegExp boldPattern = RegExp(r'\*\*(.+?)\*\*');
    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade700,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey.shade700,
        ),
      ));
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey.shade700,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue.shade700,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'By using The Eduverse, you agree to the collection and use of information in accordance with this Privacy Policy.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
