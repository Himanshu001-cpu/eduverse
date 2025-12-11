import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';

class FeedData {
  // ============================================================
  // TRENDING POSTS
  // ============================================================
  static const List<TrendingPost> trending = [
    TrendingPost(
      title: 'Master Essay Writing: Complete Guide for Civil Services',
      likes: '2.5k',
      comments: '384',
      emoji: '✍️',
      color: Colors.deepPurple,
    ),
    TrendingPost(
      title: 'India\'s Digital Revolution: Current Affairs Analysis',
      likes: '1.8k',
      comments: '256',
      emoji: '📱',
      color: Colors.blue,
    ),
    TrendingPost(
      title: 'Climate Change & Sustainable Development Goals',
      likes: '3.2k',
      comments: '512',
      emoji: '🌍',
      color: Colors.green,
    ),
    TrendingPost(
      title: 'Indian Economy: Budget Analysis 2025',
      likes: '2.1k',
      comments: '445',
      emoji: '💰',
      color: Colors.orange,
    ),
    TrendingPost(
      title: 'Constitution Day Special: Fundamental Rights',
      likes: '1.9k',
      comments: '298',
      emoji: '⚖️',
      color: Colors.indigo,
    ),
  ];

  // ============================================================
  // FEED ITEMS
  // ============================================================
  static final List<FeedItem> feedItems = [
    // ------------------------------
    // Answer Writing
    // ------------------------------
    FeedItem(
      id: 'aw-001',
      type: ContentType.answerWriting,
      title: 'How to Write 250-word Answers Effectively',
      description:
          'Learn the art of structuring your UPSC mains answers with proper introduction, body, and conclusion. Master time management techniques.',
      categoryLabel: 'Answer Writing',
      emoji: '📝',
      color: Colors.purple,
      isPublic: true,
      answerWritingContent: const AnswerWritingContent(
        id: 'aw-001',
        question: 'Discuss the role of civil society in strengthening democracy in India. How can the government and civil society work together to address social challenges?',
        wordLimit: 250,
        timeLimitMinutes: 7,
        keyPoints: [
          'Define civil society and its components',
          'Historical role in Indian democracy',
          'Current challenges and opportunities',
          'Collaboration mechanisms with government',
          'Way forward with specific recommendations',
        ],
      ),
    ),
    FeedItem(
      id: 'aw-002',
      type: ContentType.answerWriting,
      title: 'Ethics Case Study: Dilemma Resolution Strategy',
      description:
          'Approach ethical dilemmas systematically using stakeholder analysis, ethical frameworks, and balanced recommendations.',
      categoryLabel: 'Answer Writing',
      emoji: '🤔',
      color: Colors.purple,
      isPublic: true,
      answerWritingContent: const AnswerWritingContent(
        id: 'aw-002',
        question: 'You are a District Collector. A major industrial project promises employment but threatens the livelihood of traditional fishermen. The project has political support. How would you approach this situation? Discuss the ethical dilemmas involved.',
        wordLimit: 250,
        timeLimitMinutes: 10,
        keyPoints: [
          'Identify all stakeholders',
          'Analyze competing interests',
          'Apply ethical frameworks',
          'Consider legal and constitutional aspects',
          'Propose balanced solution',
        ],
      ),
    ),

    // ------------------------------
    // Current Affairs
    // ------------------------------
    FeedItem(
      id: 'ca-001',
      type: ContentType.currentAffairs,
      title: 'India\'s G20 Presidency: Key Outcomes',
      description:
          'Comprehensive analysis of India\'s successful G20 presidency, major achievements, and its global economic impact.',
      categoryLabel: 'Current Affairs',
      emoji: '🌐',
      color: Colors.blue,
      isPublic: true,
      currentAffairsContent: CurrentAffairsContent(
        id: 'ca-001',
        title: 'India\'s G20 Presidency: Key Outcomes',
        eventDate: DateTime(2023, 9, 10),
        context: 'International',
        whatHappened: 'India successfully concluded its G20 Presidency with the New Delhi Leaders\' Declaration. The summit saw consensus on critical global issues including climate finance, digital public infrastructure, and inclusive growth. The African Union was admitted as a permanent member of the G20.',
        whyItMatters: 'This marks India\'s emergence as a key player in shaping global governance. The focus on Global South concerns, sustainable development, and multilateral reform signals a more inclusive international order. The emphasis on Digital Public Infrastructure could revolutionize development strategies worldwide.',
        upscRelevance: 'Relevant for GS-II (International Relations), GS-III (Economy). Topics: Multilateral institutions, India\'s foreign policy, Global South, Climate finance, Digital governance. Potential essay topics on India\'s role in shaping new world order.',
        tags: ['G20', 'Diplomacy', 'International Relations', 'Economics'],
      ),
    ),
    FeedItem(
      id: 'ca-002',
      type: ContentType.currentAffairs,
      title: 'New Education Policy Implementation Update',
      description:
          'Latest developments in NEP 2020 rollout across states, challenges faced, and success stories from different institutions.',
      categoryLabel: 'Current Affairs',
      emoji: '📚',
      color: Colors.blue,
      isPublic: true,
      currentAffairsContent: CurrentAffairsContent(
        id: 'ca-002',
        title: 'NEP 2020 Implementation Progress',
        eventDate: DateTime(2024, 11, 15),
        context: 'National',
        whatHappened: 'Multiple states have begun implementing key provisions of NEP 2020 including 5+3+3+4 structure, mother tongue instruction in early years, and vocational education integration. The National Credit Framework is being operationalized across higher education institutions.',
        whyItMatters: 'Education reform is fundamental to India\'s demographic dividend and economic aspirations. NEP 2020 represents the most significant educational overhaul since 1986. Its successful implementation will determine India\'s knowledge economy trajectory for decades.',
        upscRelevance: 'Relevant for GS-I (Society), GS-II (Education Policy). Topics: Federal implementation challenges, equity in education, skill development, constitutional provisions on education. Potential questions on state vs central roles in education.',
        tags: ['NEP 2020', 'Education', 'Policy', 'States'],
      ),
    ),

    // ------------------------------
    // Articles
    // ------------------------------
    FeedItem(
      id: 'art-001',
      type: ContentType.articles,
      title: 'Understanding India\'s Federal Structure',
      description:
          'Deep dive into constitutional provisions governing Centre-State relations, fiscal federalism, and cooperative federalism.',
      categoryLabel: 'Article',
      emoji: '📄',
      color: Colors.teal,
      isPublic: true,
      articleContent: ArticleContent(
        id: 'art-001',
        title: 'Understanding India\'s Federal Structure',
        body: '''India's federal structure is unique and often described as "quasi-federal" or "federal with a strong unitary bias." This article explores the constitutional framework that governs the relationship between the Union and States.

Constitutional Framework

The Constitution of India establishes a dual polity with clear division of powers between the Centre and States. The Seventh Schedule contains three lists:

1. Union List (97 items): Defence, Foreign Affairs, Banking, Communications
2. State List (66 items): Police, Public Health, Agriculture, Land
3. Concurrent List (47 items): Education, Forests, Trade Unions

Key Features of Indian Federalism

• Written Constitution with supremacy
• Division of powers between Centre and States
• Independent Judiciary
• Bicameral Legislature at Centre

Cooperative Federalism in Practice

Recent years have seen emphasis on cooperative federalism through institutions like:
- NITI Aayog replacing Planning Commission
- GST Council for indirect tax coordination
- Inter-State Council for policy coordination

Challenges and the Way Forward

The tension between centralization and state autonomy continues. Issues like Governor's role, Article 356 misuse, and fiscal transfers remain contentious. The future lies in genuine cooperative federalism that respects constitutional boundaries while ensuring national unity.

Understanding this framework is crucial for UPSC preparation as it forms the basis of Indian governance and administration.''',
        tags: ['Constitution', 'Federalism', 'Polity', 'Governance'],
        estimatedReadTime: 8,
        publishedDate: DateTime(2024, 11, 20),
      ),
    ),
    FeedItem(
      id: 'art-002',
      type: ContentType.articles,
      title: 'Women Empowerment: Progress & Challenges',
      description:
          'Analyzing government initiatives, social changes, and persistent challenges in achieving gender equality in India.',
      categoryLabel: 'Article',
      emoji: '👩',
      color: Colors.teal,
      isPublic: true,
      articleContent: ArticleContent(
        id: 'art-002',
        title: 'Women Empowerment: Progress & Challenges',
        body: '''Women empowerment in India has seen significant progress across multiple dimensions, yet substantial challenges remain. This comprehensive analysis examines the current state and future trajectory.

Legal Framework

India has enacted comprehensive legislation for women's rights:
• Women's Reservation Bill (33% seats in Parliament)
• Protection of Women from Domestic Violence Act
• Sexual Harassment of Women at Workplace Act
• Maternity Benefit Amendment Act

Economic Participation

Women's labor force participation has shown concerning trends:
- LFPR dropped from 31.2% (2011-12) to 25.1% (2017-18)
- Gender pay gap remains at approximately 19%
- Only 14% of senior management positions held by women

Government Initiatives

Several schemes target women's empowerment:
1. Beti Bachao Beti Padhao
2. Pradhan Mantri Ujjwala Yojana
3. MUDRA loans prioritizing women entrepreneurs
4. One Stop Centres for violence survivors

Social Change Indicators

Positive trends in:
• Increasing female literacy (65.46% in 2011 to 70.3% in 2022)
• Declining maternal mortality rate
• Rising political participation

Persistent Challenges

• Deep-rooted patriarchal mindsets
• Safety concerns limiting mobility
• Unpaid care work burden
• Technology gap in digital access

The path forward requires multi-pronged approach combining legal protection, economic opportunity, social change, and political participation.''',
        tags: ['Women', 'Empowerment', 'Gender', 'Social Issues'],
        estimatedReadTime: 10,
        publishedDate: DateTime(2024, 11, 25),
      ),
    ),

    // ------------------------------
    // Videos
    // ------------------------------
    FeedItem(
      id: 'vid-001',
      type: ContentType.videos,
      title: 'Ancient Indian History Crash Course',
      description:
          'Complete video series covering Indus Valley Civilization to Gupta Period. Includes maps and diagrams.',
      categoryLabel: 'Video',
      emoji: '🎥',
      color: Colors.red,
      isPublic: true,
      videoContent: const VideoContent(
        id: 'vid-001',
        title: 'Ancient Indian History Crash Course',
        description: 'This comprehensive video course covers Ancient Indian History from the Harappan Civilization to the end of Gupta period. Perfect for UPSC Prelims and Mains preparation with detailed coverage of art, architecture, society, and economy.',
        videoUrl: 'https://example.com/video/ancient-history',
        durationMinutes: 45,
        keyPoints: [
          'Indus Valley Civilization: Town planning, seals, script',
          'Vedic Period: Rig Veda, society, religion',
          'Mahajanapadas: 16 kingdoms, rise of new religions',
          'Mauryan Empire: Administration, Ashoka\'s edicts',
          'Post-Mauryan: Art styles, trade routes',
          'Gupta Period: Golden age, literature, science',
        ],
      ),
    ),
    FeedItem(
      id: 'vid-002',
      type: ContentType.videos,
      title: 'Geography: Climate Patterns of India',
      description:
          'Visual explanation of monsoon mechanism, climate zones, and their impact on agriculture and economy.',
      categoryLabel: 'Video',
      emoji: '🌦️',
      color: Colors.red,
      isPublic: true,
      videoContent: const VideoContent(
        id: 'vid-002',
        title: 'Climate Patterns of India',
        description: 'Understand the complex climate patterns of India including the monsoon mechanism, El Niño effects, and regional climate variations. Essential for Geography preparation with animated explanations.',
        videoUrl: 'https://example.com/video/climate-india',
        durationMinutes: 35,
        keyPoints: [
          'Factors influencing Indian climate',
          'Southwest Monsoon mechanism',
          'Northeast Monsoon and winter weather',
          'Climate zones and their characteristics',
          'Impact on agriculture and water resources',
          'Climate change and future projections',
        ],
      ),
    ),

    // ------------------------------
    // Quizzes
    // ------------------------------
    FeedItem(
      id: 'quiz-001',
      type: ContentType.quizzes,
      title: 'Daily Current Affairs Quiz - Week 45',
      description:
          '20 questions covering national and international events. Includes solutions and concepts.',
      categoryLabel: 'Quiz',
      emoji: '❓',
      color: Colors.amber,
      isPublic: true,
      quizQuestions: [
        QuizQuestion(
          id: 'q1',
          questionText: 'Which country recently became a permanent member of G20?',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'q1a', text: 'Brazil'),
            const AnswerOption(id: 'q1b', text: 'African Union', isCorrect: true),
            const AnswerOption(id: 'q1c', text: 'ASEAN'),
            const AnswerOption(id: 'q1d', text: 'Indonesia'),
          ],
          explanation: 'The African Union was admitted as a permanent member of G20 during India\'s presidency in September 2023, making it the 21st member of the group.',
        ),
        QuizQuestion(
          id: 'q2',
          questionText: 'The Digital Public Infrastructure framework promoted by India includes which of the following?',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'q2a', text: 'Only Aadhaar'),
            const AnswerOption(id: 'q2b', text: 'Only UPI'),
            const AnswerOption(id: 'q2c', text: 'Aadhaar, UPI, and DigiLocker', isCorrect: true),
            const AnswerOption(id: 'q2d', text: 'Only DigiLocker'),
          ],
          explanation: 'India\'s DPI stack includes identity (Aadhaar), payments (UPI), and data (DigiLocker) - forming a comprehensive digital public goods framework.',
        ),
        QuizQuestion(
          id: 'q3',
          questionText: 'The National Credit Framework is associated with which policy?',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'q3a', text: 'Industrial Policy 2011'),
            const AnswerOption(id: 'q3b', text: 'NEP 2020', isCorrect: true),
            const AnswerOption(id: 'q3c', text: 'FDI Policy'),
            const AnswerOption(id: 'q3d', text: 'Trade Policy'),
          ],
          explanation: 'The National Credit Framework is part of NEP 2020, allowing students to accumulate academic credits across institutions and courses.',
        ),
        QuizQuestion(
          id: 'q4',
          questionText: 'Mission LiFE, launched by India, focuses on:',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'q4a', text: 'Financial inclusion'),
            const AnswerOption(id: 'q4b', text: 'Environment-friendly lifestyles', isCorrect: true),
            const AnswerOption(id: 'q4c', text: 'Digital literacy'),
            const AnswerOption(id: 'q4d', text: 'Space exploration'),
          ],
          explanation: 'Mission LiFE (Lifestyle for Environment) promotes environment-friendly lifestyles and sustainable consumption patterns as a mass movement.',
        ),
        QuizQuestion(
          id: 'q5',
          questionText: 'The Global Biofuel Alliance was launched at which summit?',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'q5a', text: 'COP28'),
            const AnswerOption(id: 'q5b', text: 'G20 2023', isCorrect: true),
            const AnswerOption(id: 'q5c', text: 'BRICS 2023'),
            const AnswerOption(id: 'q5d', text: 'SCO 2023'),
          ],
          explanation: 'The Global Biofuel Alliance was launched at the G20 Summit in New Delhi, 2023, to promote sustainable biofuels as a key energy transition strategy.',
        ),
      ],
    ),
    FeedItem(
      id: 'quiz-002',
      type: ContentType.quizzes,
      title: 'Indian Polity: Fundamental Rights Quiz',
      description:
          'Practice MCQs on Articles 12-35 with case law references. Good for prelims revision.',
      categoryLabel: 'Quiz',
      emoji: '⚖️',
      color: Colors.amber,
      isPublic: true,
      quizQuestions: [
        QuizQuestion(
          id: 'p1',
          questionText: 'Article 14 of the Indian Constitution guarantees:',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'p1a', text: 'Right to Freedom'),
            const AnswerOption(id: 'p1b', text: 'Equality before law', isCorrect: true),
            const AnswerOption(id: 'p1c', text: 'Right against Exploitation'),
            const AnswerOption(id: 'p1d', text: 'Right to Constitutional Remedies'),
          ],
          explanation: 'Article 14 guarantees equality before law and equal protection of laws within the territory of India. It prohibits class legislation but permits reasonable classification.',
        ),
        QuizQuestion(
          id: 'p2',
          questionText: 'Which article prohibits discrimination on grounds of religion, race, caste, sex, or place of birth?',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'p2a', text: 'Article 14'),
            const AnswerOption(id: 'p2b', text: 'Article 15', isCorrect: true),
            const AnswerOption(id: 'p2c', text: 'Article 16'),
            const AnswerOption(id: 'p2d', text: 'Article 17'),
          ],
          explanation: 'Article 15 prohibits discrimination on grounds of religion, race, caste, sex, or place of birth. However, it allows special provisions for women, children, and socially backward classes.',
        ),
        QuizQuestion(
          id: 'p3',
          questionText: 'The Right to Education (Article 21A) applies to children of age:',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'p3a', text: '5-12 years'),
            const AnswerOption(id: 'p3b', text: '6-14 years', isCorrect: true),
            const AnswerOption(id: 'p3c', text: '3-15 years'),
            const AnswerOption(id: 'p3d', text: '6-18 years'),
          ],
          explanation: 'Article 21A, inserted by the 86th Amendment, provides free and compulsory education to all children in the age group of 6-14 years as a Fundamental Right.',
        ),
        QuizQuestion(
          id: 'p4',
          questionText: 'Which Fundamental Right is available only to citizens and not to foreigners?',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'p4a', text: 'Article 14'),
            const AnswerOption(id: 'p4b', text: 'Article 19', isCorrect: true),
            const AnswerOption(id: 'p4c', text: 'Article 21'),
            const AnswerOption(id: 'p4d', text: 'Article 25'),
          ],
          explanation: 'Article 19 (six freedoms including speech, assembly, movement, etc.) is available only to citizens. Articles 14, 21, and 25 are available to all persons including foreigners.',
        ),
        QuizQuestion(
          id: 'p5',
          questionText: 'The Kesavananda Bharati case established:',
          answerType: AnswerType.multipleChoice,
          options: [
            const AnswerOption(id: 'p5a', text: 'Procedure established by law'),
            const AnswerOption(id: 'p5b', text: 'Basic Structure doctrine', isCorrect: true),
            const AnswerOption(id: 'p5c', text: 'Judicial activism'),
            const AnswerOption(id: 'p5d', text: 'Parliamentary sovereignty'),
          ],
          explanation: 'The Kesavananda Bharati case (1973) established the Basic Structure doctrine, holding that Parliament cannot amend the Constitution to destroy its basic structure.',
        ),
      ],
    ),

    // ------------------------------
    // Jobs
    // ------------------------------
    FeedItem(
      id: 'job-001',
      type: ContentType.jobs,
      title: 'UPSC Civil Services 2025: Notification Out',
      description:
          '1000+ vacancies announced. Eligibility criteria, exam dates, syllabus changes, all in one place.',
      categoryLabel: 'Job Alert',
      emoji: '💼',
      color: Colors.green,
      isPublic: true,
      jobContent: JobContent(
        id: 'job-001',
        title: 'UPSC Civil Services Examination 2025',
        organization: 'Union Public Service Commission',
        location: 'All India',
        salaryRange: '₹56,100 - ₹2,50,000',
        applyUrl: 'https://upsc.gov.in',
        detailsText: 'The Union Public Service Commission invites applications for the Civil Services Examination 2025 for recruitment to Indian Administrative Service (IAS), Indian Foreign Service (IFS), Indian Police Service (IPS), and other Group A & B Central Services.',
        applicationStart: DateTime(2025, 2, 1),
        applicationEnd: DateTime(2025, 2, 28),
        eligibility: '''Age: 21-32 years (relaxation for reserved categories)
Education: Bachelor's degree from recognized university
Nationality: Indian citizen (some services open to specific categories)
Attempts: General - 6, OBC - 9, SC/ST - Unlimited (within age limit)''',
        jobType: 'Permanent',
        vacancies: 1000,
      ),
    ),
    FeedItem(
      id: 'job-002',
      type: ContentType.jobs,
      title: 'State PSC Combined Exam: Apply Now',
      description:
          'Multiple state PSC notifications released. Check exam pattern and preparation strategy.',
      categoryLabel: 'Job Alert',
      emoji: '📋',
      color: Colors.green,
      isPublic: true,
      jobContent: JobContent(
        id: 'job-002',
        title: 'State PSC Combined Competitive Examination 2025',
        organization: 'Various State Public Service Commissions',
        location: 'State Cadre',
        salaryRange: '₹44,900 - ₹1,42,400',
        applyUrl: 'https://example.com/state-psc',
        detailsText: 'Multiple State Public Service Commissions have released notifications for Combined Competitive Examinations. Positions include State Civil Services, State Police Services, and various Group B services. This is an excellent opportunity for those targeting state-level administrative services.',
        applicationStart: DateTime(2025, 1, 15),
        applicationEnd: DateTime(2025, 3, 15),
        eligibility: '''Age: 21-37 years (varies by state, relaxation for reserved categories)
Education: Bachelor's degree from recognized university
Nationality: Indian citizen
Domicile: State-specific requirements may apply''',
        jobType: 'Permanent',
        vacancies: 500,
      ),
    ),
  ];
}

