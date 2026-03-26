import 'package:flutter/material.dart';
import '../theme/gamer_theme.dart';

/// Skill tier levels for Bedwars guide content.
enum SkillTier {
  starters('Starters', GamerColors.neonGreen),
  practitioners('Practitioners', GamerColors.neonCyan),
  experts('Experts', GamerColors.neonPink);

  final String label;
  final Color accentColor;

  const SkillTier(this.label, this.accentColor);

  /// Returns the guide sections for this tier.
  List<GuideSection> get sections {
    switch (this) {
      case SkillTier.starters:
        return BedwarsGuideData.startersSections;
      case SkillTier.practitioners:
        return BedwarsGuideData.practitionersSections;
      case SkillTier.experts:
        return BedwarsGuideData.expertsSections;
    }
  }
}

/// A single guide section with a title, emoji, accent color, and content lines.
class GuideSection {
  final String title;
  final String emoji;
  final Color accentColor;
  final List<String> content;

  const GuideSection({
    required this.title,
    required this.emoji,
    required this.accentColor,
    required this.content,
  });
}

/// Static Bedwars guide content organized by skill tier.
class BedwarsGuideData {
  static const List<GuideSection> startersSections = [
    GuideSection(
      title: 'Game Objective & Rules',
      emoji: '🎯',
      accentColor: GamerColors.neonGreen,
      content: [
        'Protect your bed while trying to destroy enemy beds.',
        'Once your bed is destroyed, you can no longer respawn.',
        'The last team with a surviving player wins the game.',
        'Collect resources from generators to buy gear and blocks.',
      ],
    ),
    GuideSection(
      title: 'Basic Resource Gathering',
      emoji: '⛏️',
      accentColor: GamerColors.neonGreen,
      content: [
        'Iron and gold spawn automatically at your island generator.',
        'Stay near your generator between fights to collect resources.',
        'Iron is used for basic blocks and tools from the shop.',
        'Gold buys stronger armor, weapons, and utility items.',
      ],
    ),
    GuideSection(
      title: 'Purchasing Essential Items',
      emoji: '🛒',
      accentColor: GamerColors.neonGreen,
      content: [
        'Buy wool or endstone early for bridging and bed defense.',
        'A stone sword is a cheap early upgrade over the wooden one.',
        'Iron armor gives a solid defense boost for the first fights.',
        'Pick up shears to cut through wool defenses quickly.',
      ],
    ),
    GuideSection(
      title: 'Basic Bed Defense',
      emoji: '🛡️',
      accentColor: GamerColors.neonGreen,
      content: [
        'Cover your bed with wool as soon as the game starts.',
        'Add a second layer of endstone around the wool for extra protection.',
        'Never leave your bed completely unguarded in the early game.',
        'Place blocks on all sides including the top of the bed.',
      ],
    ),
    GuideSection(
      title: 'Basic Combat Tips',
      emoji: '⚔️',
      accentColor: GamerColors.neonGreen,
      content: [
        'Always sprint before hitting an opponent for extra knockback.',
        'Block-hit by alternating attack and block to reduce damage taken.',
        'Aim for critical hits by attacking while falling from a jump.',
        'Avoid fighting on narrow bridges where knockback is deadly.',
      ],
    ),
  ];

  static const List<GuideSection> practitionersSections = [
    GuideSection(
      title: 'Efficient Resource Management & Upgrades',
      emoji: '💎',
      accentColor: GamerColors.neonCyan,
      content: [
        'Visit diamond and emerald generators on the center islands regularly.',
        'Prioritize team upgrades like sharpness, protection, and forge upgrades.',
        'Split resource collection duties with teammates for faster progression.',
        'Save emeralds for powerful items like diamond armor or ender pearls.',
      ],
    ),
    GuideSection(
      title: 'Intermediate Bed Defense',
      emoji: '🏰',
      accentColor: GamerColors.neonCyan,
      content: [
        'Layer your bed defense: wool inside, endstone middle, wood or glass outside.',
        'Use blast-proof glass to counter TNT attacks on your bed.',
        'Add water buckets near your bed to slow down attackers.',
        'Consider placing obsidian as the innermost layer for maximum durability.',
      ],
    ),
    GuideSection(
      title: 'Team Coordination Strategies',
      emoji: '🤝',
      accentColor: GamerColors.neonCyan,
      content: [
        'Assign roles: one player defends while others rush or gather resources.',
        'Communicate enemy positions and incoming attacks to your team.',
        'Coordinate simultaneous attacks on enemy bases for maximum pressure.',
        'Share resources with teammates who need specific upgrades.',
      ],
    ),
    GuideSection(
      title: 'Bridge-Building Techniques',
      emoji: '🌉',
      accentColor: GamerColors.neonCyan,
      content: [
        'Practice speed-bridging by shifting at the edge and placing blocks quickly.',
        'Build bridges with slight zigzag patterns to avoid easy bow shots.',
        'Use blocks that are hard to break like endstone for permanent bridges.',
        'Always carry enough blocks before starting a bridge to an enemy island.',
      ],
    ),
    GuideSection(
      title: 'Mid-Game Combat Tactics',
      emoji: '🗡️',
      accentColor: GamerColors.neonCyan,
      content: [
        'Use knockback sticks to push enemies off bridges and islands.',
        'Carry a bow for ranged pressure while approaching enemy bases.',
        'Use fireballs to blast through defenses and knock players into the void.',
        'Always eat a golden apple before engaging in a tough fight.',
      ],
    ),
  ];

  static const List<GuideSection> expertsSections = [
    GuideSection(
      title: 'Advanced PvP Combat',
      emoji: '🔥',
      accentColor: GamerColors.neonPink,
      content: [
        'Master W-tap combos by releasing and re-pressing forward between hits.',
        'Use fishing rods to pull enemies closer and reset their sprint.',
        'Strafe in unpredictable patterns to make yourself harder to hit.',
        'Combine rod pulls with immediate sword swings for devastating combos.',
      ],
    ),
    GuideSection(
      title: 'Speed-Bridging & Advanced Movement',
      emoji: '🏃',
      accentColor: GamerColors.neonPink,
      content: [
        'Learn ninja-bridging to place blocks while moving forward without shifting.',
        'Practice breezily bridging for the fastest straight-line bridge speed.',
        'Use block clutches to save yourself from falling into the void.',
        'Master jump-bridging to cover gaps quickly during rushes.',
      ],
    ),
    GuideSection(
      title: 'Rush Strategies & Timing',
      emoji: '⚡',
      accentColor: GamerColors.neonPink,
      content: [
        'Rush the nearest enemy base within the first 30 seconds for an early advantage.',
        'Buy TNT and a pickaxe for a fast bed break on defended bases.',
        'Time your rushes when enemies leave their base to gather resources.',
        'Use invisibility potions for surprise attacks on well-defended beds.',
      ],
    ),
    GuideSection(
      title: 'Endgame Tactics & Resource Prioritization',
      emoji: '👑',
      accentColor: GamerColors.neonPink,
      content: [
        'Stockpile ender pearls for quick escapes and surprise engagements.',
        'Prioritize diamond armor and sharpness upgrades for final fights.',
        'Control the center map generators to deny resources to remaining teams.',
        'Keep emergency blocks and golden apples ready for clutch moments.',
      ],
    ),
    GuideSection(
      title: 'Counter-Strategies Against Common Plays',
      emoji: '🧠',
      accentColor: GamerColors.neonPink,
      content: [
        'Counter bridge rushers by placing void traps or using bows at range.',
        'Against TNT attacks, use blast-proof glass and obsidian layers.',
        'Counter invisible players by watching for armor particles and footstep sounds.',
        'Against fireball spam, carry a water bucket to extinguish fires and block knockback.',
      ],
    ),
  ];
}
