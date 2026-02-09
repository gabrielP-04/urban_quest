import 'package:flutter/material.dart';
import 'package:urban_quest/models/achievement.dart';

/// Central definition of all achievements available in UrbanQuest.
/// This file defines WHAT achievements exist, not WHEN they are unlocked.
/// Unlocking logic is handled by the gamification layer.
final List<Achievement> achievementsDefinition = [
  Achievement(
    id: 'first_steps',
    title: 'First Steps',
    description: 'Visit your first point of interest',
    icon: Icons.directions_walk,
    unlocked: false,
  ),
  Achievement(
    id: 'explorer',
    title: 'Explorer',
    description: 'Visit 5 points of interest',
    icon: Icons.explore,
    unlocked: false,
  ),
  Achievement(
    id: 'urban_master',
    title: 'Urban Master',
    description: 'Visit 10 points of interest',
    icon: Icons.location_city,
    unlocked: false,
  ),
  Achievement(
    id: 'monument_lover',
    title: 'Monument Lover',
    description: 'Visit 3 monuments',
    icon: Icons.account_balance,
    unlocked: false,
  ),
  Achievement(
    id: 'city_flavours',
    title: 'City Flavours',
    description: 'Discover 3 gastronomic places',
    icon: Icons.restaurant,
    unlocked: false,
  ),
  Achievement(
    id: 'curious_explorer',
    title: 'Curious Explorer',
    description: 'Visit 3 optional places',
    icon: Icons.star,
    unlocked: false,
  ),
];
