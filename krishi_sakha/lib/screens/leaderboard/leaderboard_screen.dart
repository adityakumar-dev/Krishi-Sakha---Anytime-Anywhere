import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:krishi_sakha/models/leaderboard_model.dart';
import 'package:krishi_sakha/providers/leaderboard_provider.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<ProfileProvider>(context, listen: false).userProfile?.id;
      AppLogger.debug('🚀 LeaderboardScreen initialized with userId: $userId');
      if (userId != null) {
        Provider.of<LeaderboardProvider>(context, listen: false)
            .fetchUserLeaderboardData(userId);
      } else {
        AppLogger.warning('⚠️ No userId found in ProfileProvider');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Selector<LeaderboardProvider, ({bool isLoading, int leaderboardCount, UserRank? userRank, UserScore? userScore, String? error})>(
          selector: (_, provider) => (
            isLoading: provider.isLoading,
            leaderboardCount: provider.leaderboard.length,
            userRank: provider.userRank,
            userScore: provider.userScore,
            error: provider.error,
          ),
          builder: (context, state, child) {
            if (state.isLoading) {
              return _buildLoadingState();
            }

            if (state.error != null && state.leaderboardCount == 0) {
              return _buildErrorState(state.error!, context.read<LeaderboardProvider>());
            }

            if (state.leaderboardCount == 0) {
              return _buildEmptyState();
            }

            return _buildLeaderboardContent(context.read<LeaderboardProvider>());
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildHeader(showBackButton: true),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading leaderboard...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardContent(LeaderboardProvider provider) {
    final currentUserId = Provider.of<ProfileProvider>(context, listen: false).userProfile?.id;
    final top3 = provider.leaderboard.take(3).toList();
    final remaining = provider.leaderboard.length > 3 
        ? provider.leaderboard.sublist(3) 
        : <LeaderboardEntry>[];

    return RefreshIndicator(
      onRefresh: () async {
        final userId = Provider.of<ProfileProvider>(context, listen: false).userProfile?.id;
        if (userId != null) {
          await provider.fetchUserLeaderboardData(userId);
        }
      },
      color: const Color(0xFF2D5016),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          // User Rank Card
          if (provider.userRank != null)
            SliverToBoxAdapter(
              child: FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: _buildUserRankCard(provider.userRank!),
              ),
            ),

          // Top 3 Podium (only show if we have at least 3 users)
          if (top3.length >= 3)
            SliverToBoxAdapter(
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildPodium(top3, currentUserId),
              ),
            ),

          // Full Leaderboard List (show all if less than 3, or remaining if 3+)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // If less than 3 users, show all. Otherwise show from rank 4 onwards
                  final entry = top3.length < 3 
                      ? provider.leaderboard[index]
                      : remaining[index];
                  final rank = top3.length < 3 
                      ? index + 1 
                      : index + 4;
                  final isCurrentUser = entry.userId == currentUserId;
                  
                  return FadeInUp(
                    delay: Duration(milliseconds: 300 + (index * 50)),
                    child: _buildRankCard(entry, rank, isCurrentUser),
                  );
                },
                childCount: top3.length < 3 
                    ? provider.leaderboard.length 
                    : remaining.length,
              ),
            ),
          ),

          // Stats Section
          if (provider.userScore != null)
            SliverToBoxAdapter(
              child: FadeInUp(
                delay: Duration(milliseconds: 300 + (remaining.length * 50)),
                child: _buildStatsSection(provider.userScore!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader({bool showBackButton = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.emoji_events, color: Color(0xFF2D5016), size: 28),
          const SizedBox(width: 8),
          const Text(
            'Leaderboard',
            style: TextStyle(
              color: Color(0xFF1A2F0D),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(UserRank userRank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trophy Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          // Rank Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR RANK',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#${userRank.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${userRank.totalScore} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3, String? currentUserId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd Place
          if (top3.length > 1)
            Expanded(
              child: _buildPodiumPosition(
                top3[1],
                2,
                170,
                const [Color(0xFFC0C0C0), Color(0xFF909090)],
                currentUserId == top3[1].userId,
              ),
            ),
          const SizedBox(width: 12),
          // 1st Place
          Expanded(
            child: _buildPodiumPosition(
              top3[0],
              1,
              200,
              const [Color(0xFFFFD700), Color(0xFFFFAA00)],
              currentUserId == top3[0].userId,
            ),
          ),
          const SizedBox(width: 12),
          // 3rd Place
          if (top3.length > 2)
            Expanded(
              child: _buildPodiumPosition(
                top3[2],
                3,
                150,
                const [Color(0xFFCD7F32), Color(0xFF9D5F22)],
                currentUserId == top3[2].userId,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
    LeaderboardEntry entry,
    int rank,
    double height,
    List<Color> colors,
    bool isCurrentUser,
  ) {
    return Column(
      children: [
        // Avatar
        Container(
          width: rank == 1 ? 72 : 64,
          height: rank == 1 ? 72 : 64,
          decoration: BoxDecoration(
            color: colors[0],
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentUser ? const Color(0xFF2D5016) : Colors.grey.shade300,
              width: isCurrentUser ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: rank == 1 ? 36 : 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Name
        Text(
          entry.name,
          style: const TextStyle(
            color: Color(0xFF1A2F0D),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Score Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors[0],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${entry.finalScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            color: colors[0],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rank == 1
                    ? Icons.emoji_events
                    : rank == 2
                        ? Icons.military_tech
                        : Icons.workspace_premium,
                color: Colors.white,
                size: rank == 1 ? 50 : 40,
              ),
              const SizedBox(height: 8),
              Text(
                '#$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: rank == 1 ? 36 : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankCard(LeaderboardEntry entry, int rank, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF2D5016).withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser 
              ? const Color(0xFF2D5016)
              : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? const Color(0xFF2D5016)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: Color(0xFF1A2F0D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildSmallStat(Icons.article, entry.totalPosts),
                    const SizedBox(width: 12),
                    _buildSmallStat(Icons.favorite, entry.totalLikes),
                    const SizedBox(width: 12),
                    _buildSmallStat(Icons.verified, 
                      entry.ashaEndorsements + entry.panchayatEndorsements + entry.govEndorsements),
                  ],
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${entry.finalScore}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(
          value.toString(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(UserScore userScore) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Color(0xFF2D5016), size: 24),
              const SizedBox(width: 10),
              const Text(
                'Your Statistics',
                style: TextStyle(
                  color: Color(0xFF1A2F0D),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Score Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Score',
                  userScore.total.totalScore.toString(),
                  Icons.stars,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Posts',
                  userScore.posts.length.toString(),
                  Icons.article,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Likes',
                  userScore.total.totalLikes.toString(),
                  Icons.favorite,
                  Colors.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Endorsements',
                  (userScore.total.totalAsha + 
                   userScore.total.totalPanchayat + 
                   userScore.total.totalGov).toString(),
                  Icons.verified,
                  Colors.green,
                ),
              ),
            ],
          ),
          if (userScore.posts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Recent Posts',
              style: TextStyle(
                color: Color(0xFF1A2F0D),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...userScore.posts.take(3).map((post) => _buildPostPreview(post)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A2F0D),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreview(PostScore post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${post.postScore}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              post.content,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, LeaderboardProvider provider) {
    return Column(
      children: [
        _buildHeader(showBackButton: true),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Oops!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2F0D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      final userId = Provider.of<ProfileProvider>(context, listen: false).userProfile?.id;
                      if (userId != null) {
                        provider.fetchUserLeaderboardData(userId);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5016),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(showBackButton: true),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Rankings Yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2F0D),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Be the first to make a post!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
