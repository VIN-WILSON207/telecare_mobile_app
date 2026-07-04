import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

// ── Mock Data Models ────────────────────────────────────────────────────────
class _MockArticle {
  final String title;
  final String category;
  final String status; // 'Published', 'Draft', 'Archived'
  final String author;
  final DateTime date;
  final int viewCount;

  const _MockArticle({
    required this.title,
    required this.category,
    required this.status,
    required this.author,
    required this.date,
    required this.viewCount,
  });
}

class _MockVideo {
  final String title;
  final String duration;
  final String category;
  final String status;

  const _MockVideo({
    required this.title,
    required this.duration,
    required this.category,
    required this.status,
  });
}

class _MockFAQ {
  final String question;
  final String answer;
  final String category;
  final String status;

  const _MockFAQ({
    required this.question,
    required this.answer,
    required this.category,
    required this.status,
  });
}

class _MockCategory {
  final String name;
  final IconData icon;
  final int articleCount;

  const _MockCategory({
    required this.name,
    required this.icon,
    required this.articleCount,
  });
}

class HealthContentView extends ConsumerStatefulWidget {
  const HealthContentView({super.key});

  @override
  ConsumerState<HealthContentView> createState() => _HealthContentViewState();
}

class _HealthContentViewState extends ConsumerState<HealthContentView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Mock Data ─────────────────────────────────────────────────────────────
  final List<_MockArticle> _articles = [
    _MockArticle(
      title: 'Understanding Hypertension: A Patient Guide',
      category: 'Chronic Disease',
      status: 'Published',
      author: 'Dr. Amara Okafor',
      date: DateTime(2026, 6, 28),
      viewCount: 1243,
    ),
    _MockArticle(
      title: '10 Tips for Better Sleep Hygiene',
      category: 'Mental Health',
      status: 'Published',
      author: 'Dr. Ngozi Adeyemi',
      date: DateTime(2026, 6, 25),
      viewCount: 876,
    ),
    _MockArticle(
      title: 'Nutrition During Pregnancy: What to Eat',
      category: "Women's Health",
      status: 'Draft',
      author: 'Dr. Aisha Mohammed',
      date: DateTime(2026, 6, 30),
      viewCount: 0,
    ),
    _MockArticle(
      title: 'Diabetes Management: Exercise Routines',
      category: 'Exercise',
      status: 'Archived',
      author: 'Dr. Emeka Nwosu',
      date: DateTime(2026, 5, 10),
      viewCount: 2105,
    ),
  ];

  final List<_MockVideo> _videos = [
    const _MockVideo(
      title: 'How to Measure Blood Pressure at Home',
      duration: '5:32',
      category: 'General Health',
      status: 'Published',
    ),
    const _MockVideo(
      title: 'Simple Home Exercises for Back Pain',
      duration: '12:45',
      category: 'Exercise',
      status: 'Published',
    ),
    const _MockVideo(
      title: 'Understanding Your Lab Results',
      duration: '8:15',
      category: 'General Health',
      status: 'Draft',
    ),
  ];

  final List<_MockFAQ> _faqs = [
    const _MockFAQ(
      question: 'How do I book a consultation?',
      answer:
          'Navigate to the Appointments tab, select your preferred doctor, choose an available time slot, and confirm your booking.',
      category: 'General Health',
      status: 'Published',
    ),
    const _MockFAQ(
      question: 'What should I do if I miss my medication?',
      answer:
          'If you miss a dose, take it as soon as you remember. If it is almost time for your next dose, skip the missed dose. Do not double up.',
      category: 'Chronic Disease',
      status: 'Published',
    ),
    const _MockFAQ(
      question: 'Are teleconsultations covered by insurance?',
      answer:
          'Coverage varies by provider. Please contact your insurance company to confirm telehealth benefits before booking.',
      category: 'General Health',
      status: 'Draft',
    ),
    const _MockFAQ(
      question: 'How can I improve my mental well-being?',
      answer:
          'Regular exercise, adequate sleep, social connections, and mindfulness practices can significantly improve mental health.',
      category: 'Mental Health',
      status: 'Published',
    ),
  ];

  final List<_MockCategory> _categories = const [
    _MockCategory(name: 'General Health', icon: Icons.health_and_safety_rounded, articleCount: 12),
    _MockCategory(name: 'Nutrition', icon: Icons.restaurant_rounded, articleCount: 8),
    _MockCategory(name: 'Mental Health', icon: Icons.psychology_rounded, articleCount: 6),
    _MockCategory(name: 'Exercise', icon: Icons.fitness_center_rounded, articleCount: 9),
    _MockCategory(name: 'Chronic Disease', icon: Icons.monitor_heart_rounded, articleCount: 7),
    _MockCategory(name: "Women's Health", icon: Icons.female_rounded, articleCount: 5),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: AppTheme.neutralSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.neutralMedium,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Articles'),
                Tab(text: 'Videos'),
                Tab(text: 'FAQs'),
                Tab(text: 'Categories'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildArticlesTab(),
                _buildVideosTab(),
                _buildFAQsTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add New Content dialog would appear here.'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Content',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Articles Tab ──────────────────────────────────────────────────────────
  Widget _buildArticlesTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _articles.length,
      itemBuilder: (context, index) => _buildArticleCard(_articles[index]),
    );
  }

  Widget _buildArticleCard(_MockArticle article) {
    final formattedDate =
        '${article.date.day}/${article.date.month}/${article.date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(article.status),
              ],
            ),
            const SizedBox(height: 10),

            // Category chip + Author + Date
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.category,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: AppTheme.neutralLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    article.author,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralMedium,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date + Views + Action Buttons
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 12, color: AppTheme.neutralLight),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutralMedium,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.visibility_rounded,
                    size: 12, color: AppTheme.neutralLight),
                const SizedBox(width: 4),
                Text(
                  '${article.viewCount} views',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutralMedium,
                  ),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: article.status == 'Published'
                      ? Icons.archive_rounded
                      : Icons.publish_rounded,
                  label: article.status == 'Published' ? 'Archive' : 'Publish',
                  color: article.status == 'Published'
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppTheme.errorColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Videos Tab ────────────────────────────────────────────────────────────
  Widget _buildVideosTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _videos.length,
      itemBuilder: (context, index) => _buildVideoCard(_videos[index]),
    );
  }

  Widget _buildVideoCard(_MockVideo video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 80,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.neutralSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 32, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_rounded,
                          size: 12, color: AppTheme.neutralLight),
                      const SizedBox(width: 4),
                      Text(
                        video.duration,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.neutralMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(video.status),
          ],
        ),
      ),
    );
  }

  // ── FAQs Tab ──────────────────────────────────────────────────────────────
  Widget _buildFAQsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _faqs.length,
      itemBuilder: (context, index) => _buildFAQCard(_faqs[index]),
    );
  }

  Widget _buildFAQCard(_MockFAQ faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_rounded,
                      size: 16, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    faq.question,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                ),
                _buildStatusBadge(faq.status),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                faq.answer,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  faq.category,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Categories Tab ────────────────────────────────────────────────────────
  Widget _buildCategoriesTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _categories.length,
      itemBuilder: (context, index) =>
          _buildCategoryCard(_categories[index]),
    );
  }

  Widget _buildCategoryCard(_MockCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child:
                  Icon(category.icon, size: 22, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.articleCount} articles',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppTheme.infoColor),
              tooltip: 'Edit category',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Edit ${category.name}'),
                    backgroundColor: AppTheme.infoColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppTheme.errorColor),
              tooltip: 'Delete category',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delete ${category.name}?'),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Helpers ────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Published':
        bgColor = AppTheme.statusApproved;
        textColor = AppTheme.statusApprovedText;
        break;
      case 'Draft':
        bgColor = AppTheme.statusPending;
        textColor = AppTheme.statusPendingText;
        break;
      case 'Archived':
        bgColor = AppTheme.statusRejected;
        textColor = AppTheme.statusRejectedText;
        break;
      default:
        bgColor = AppTheme.neutralSurface;
        textColor = AppTheme.neutralMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label action triggered'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
