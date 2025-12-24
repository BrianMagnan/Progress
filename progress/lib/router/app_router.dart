import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/skills_screen.dart';
import '../screens/sub_skills_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/goal_detail_screen.dart';
import '../screens/short_term_goals_screen.dart';
import '../screens/short_term_goal_detail_screen.dart';
import '../models/category.dart';
import '../models/skill.dart';
import '../models/sub_skill.dart';
import '../models/goal.dart';
import '../models/short_term_goal.dart';
import '../services/supabase_database_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('The page you\'re looking for doesn\'t exist.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/long-term-goals',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/long-term-goals/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return FutureBuilder<Category?>(
            future: SupabaseDatabaseService.instance.getCategory(categoryId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return SkillsScreen(category: snapshot.data!);
              }
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Category not found')),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/long-term-goals/:categoryId/skills/:skillId',
        builder: (context, state) {
          final skillId = state.pathParameters['skillId']!;
          return FutureBuilder<Skill?>(
            future: SupabaseDatabaseService.instance.getSkill(skillId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return SubSkillsScreen(skill: snapshot.data!);
              }
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Skill not found')),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/long-term-goals/:categoryId/skills/:skillId/sub-skills/:subSkillId',
        builder: (context, state) {
          final subSkillId = state.pathParameters['subSkillId']!;
          return FutureBuilder<SubSkill?>(
            future: SupabaseDatabaseService.instance.getSubSkill(subSkillId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return GoalsScreen(subSkill: snapshot.data!);
              }
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Sub-skill not found')),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/goals/:goalId',
        builder: (context, state) {
          final goalId = state.pathParameters['goalId']!;
          return FutureBuilder<Goal?>(
            future: SupabaseDatabaseService.instance.getGoal(goalId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return GoalDetailScreen(goal: snapshot.data!);
              }
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Goal not found')),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/short-term-goals',
        builder: (context, state) => const ShortTermGoalsScreen(),
      ),
      GoRoute(
        path: '/short-term-goals/:goalId',
        builder: (context, state) {
          final goalId = state.pathParameters['goalId']!;
          return FutureBuilder<ShortTermGoal?>(
            future: SupabaseDatabaseService.instance.getShortTermGoal(goalId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return ShortTermGoalDetailScreen(goal: snapshot.data!);
              }
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Goal not found')),
              );
            },
          );
        },
      ),
    ],
  );
}

