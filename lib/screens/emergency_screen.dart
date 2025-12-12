import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'ai_chat_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String? _expandedCategory;

  // Emergency Guide Data
  final List<EmergencyCategory> _categories = [
    EmergencyCategory(
      id: 'breathing',
      title: 'Breathing Problems',
      subtitle: 'Choking, difficulty breathing, blue gums',
      icon: Icons.air_rounded,
      color: const Color(0xFFDC2626),
      steps: [
        EmergencyStep(
          title: 'Check for obstruction',
          description: 'Open mouth and look for visible objects. If visible and reachable, carefully remove with fingers.',
          warning: 'Do NOT push objects deeper or use tools that could injure.',
        ),
        EmergencyStep(
          title: 'Heimlich maneuver (for choking)',
          description: 'For dogs: Stand behind, place hands under ribcage, apply quick upward thrusts. For cats: Hold upside down briefly, pat between shoulder blades.',
        ),
        EmergencyStep(
          title: 'Check gum color',
          description: 'Pink = normal, Blue/Purple = lack of oxygen (emergency), White = shock, Bright red = overheating or carbon monoxide.',
          isImportant: true,
        ),
        EmergencyStep(
          title: 'Clear airway position',
          description: 'Extend neck gently, pull tongue forward. Ensure no fluids blocking throat.',
        ),
        EmergencyStep(
          title: 'Rescue breathing (if unconscious)',
          description: 'Close mouth, breathe into nostrils every 3-5 seconds. Watch for chest rising.',
          seekHelp: true,
        ),
      ],
    ),
    EmergencyCategory(
      id: 'bleeding',
      title: 'Bleeding & Wounds',
      subtitle: 'Cuts, lacerations, internal bleeding signs',
      icon: Icons.healing_rounded,
      color: const Color(0xFFEA580C),
      steps: [
        EmergencyStep(
          title: 'Apply direct pressure',
          description: 'Use clean cloth or gauze. Press firmly for at least 5-10 minutes without lifting to check.',
          isImportant: true,
        ),
        EmergencyStep(
          title: 'Elevate the wound',
          description: 'If on a limb, raise above heart level while maintaining pressure.',
        ),
        EmergencyStep(
          title: 'Bandage properly',
          description: 'Wrap snugly but not too tight. You should be able to slip one finger under bandage.',
          warning: 'Check every 15 min for swelling below bandage.',
        ),
        EmergencyStep(
          title: 'Signs of internal bleeding',
          description: 'Pale gums, rapid breathing, weak pulse, bloated abdomen, blood in urine/stool.',
          seekHelp: true,
        ),
        EmergencyStep(
          title: 'Keep pet calm',
          description: 'Minimize movement. Speak softly. Cover with blanket to prevent shock.',
        ),
      ],
    ),
    EmergencyCategory(
      id: 'poisoning',
      title: 'Poisoning',
      subtitle: 'Toxic ingestion, chemicals, medications',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFF9333EA),
      steps: [
        EmergencyStep(
          title: 'Identify the poison',
          description: 'Note what was ingested, how much, and when. Keep packaging if available.',
          isImportant: true,
        ),
        EmergencyStep(
          title: 'Common pet toxins',
          description: 'Chocolate, grapes/raisins, onions, xylitol (sweetener), lilies (cats), antifreeze, medications.',
        ),
        EmergencyStep(
          title: 'Inducing vomiting',
          description: 'Only if instructed by vet. 3% hydrogen peroxide (dogs only): 1 tsp per 10 lbs body weight.',
          warning: 'NEVER induce vomiting for: corrosives, petroleum, sharp objects, or if pet is unconscious.',
        ),
        EmergencyStep(
          title: 'Activated charcoal',
          description: 'May help absorb toxins - only give if directed by vet.',
        ),
        EmergencyStep(
          title: 'Symptoms to watch',
          description: 'Vomiting, diarrhea, drooling, seizures, difficulty breathing, lethargy.',
          seekHelp: true,
        ),
      ],
    ),
    EmergencyCategory(
      id: 'heatstroke',
      title: 'Heatstroke',
      subtitle: 'Overheating, heavy panting, collapse',
      icon: Icons.thermostat_rounded,
      color: const Color(0xFFF59E0B),
      steps: [
        EmergencyStep(
          title: 'Move to cool area',
          description: 'Immediately get pet into shade or air-conditioned space.',
          isImportant: true,
        ),
        EmergencyStep(
          title: 'Cool gradually',
          description: 'Apply cool (not cold) water to neck, armpits, groin. Use wet towels.',
          warning: 'Do NOT use ice water - causes blood vessels to constrict, trapping heat inside.',
        ),
        EmergencyStep(
          title: 'Offer water',
          description: 'Small amounts of cool water. Do not force if unconscious.',
        ),
        EmergencyStep(
          title: 'Monitor temperature',
          description: 'Normal: 101-102.5°F (38-39°C). Heatstroke: >104°F (40°C). Stop cooling at 103°F.',
        ),
        EmergencyStep(
          title: 'Warning signs',
          description: 'Bright red tongue, thick saliva, vomiting, staggering, collapse.',
          seekHelp: true,
        ),
      ],
    ),
    EmergencyCategory(
      id: 'seizures',
      title: 'Seizures',
      subtitle: 'Convulsions, muscle spasms, unconsciousness',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF6366F1),
      steps: [
        EmergencyStep(
          title: 'Stay calm, protect pet',
          description: 'Move furniture away. Place soft padding around pet. Do NOT restrain.',
          isImportant: true,
        ),
        EmergencyStep(
          title: 'Time the seizure',
          description: 'Note when it starts and stops. Seizures >5 minutes are emergencies.',
          warning: 'Do NOT put fingers in mouth - they won\'t swallow their tongue.',
        ),
        EmergencyStep(
          title: 'Keep environment quiet',
          description: 'Dim lights, reduce noise. Stimulation can prolong seizure.',
        ),
        EmergencyStep(
          title: 'After seizure (post-ictal)',
          description: 'Pet may be confused, wobbly, temporarily blind. Stay with them, speak softly.',
        ),
        EmergencyStep(
          title: 'When to seek help',
          description: 'First seizure, seizure >5 min, multiple seizures, difficulty recovering.',
          seekHelp: true,
        ),
      ],
    ),
    EmergencyCategory(
      id: 'fractures',
      title: 'Fractures & Falls',
      subtitle: 'Broken bones, limping, spinal injury',
      icon: Icons.accessibility_new_rounded,
      color: const Color(0xFF0891B2),
      steps: [
        EmergencyStep(
          title: 'Minimize movement',
          description: 'Keep pet as still as possible. Movement can worsen fractures.',
          isImportant: true,
        ),
        EmergencyStep(
          title: 'Support the injury',
          description: 'Use a rolled towel or newspaper as a splint if needed for transport.',
          warning: 'Do NOT attempt to realign bones.',
        ),
        EmergencyStep(
          title: 'Transport safely',
          description: 'Use a flat board or blanket as a stretcher. Keep spine aligned.',
        ),
        EmergencyStep(
          title: 'Suspected spinal injury',
          description: 'Do NOT bend or twist the pet. Slide onto rigid surface, tape gently to immobilize.',
          seekHelp: true,
        ),
        EmergencyStep(
          title: 'Watch for shock',
          description: 'Signs: rapid breathing, weak pulse, pale gums, cold extremities. Keep warm.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Emergency Guide',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quick first-aid instructions for pet emergencies',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // AI Symptom Checker Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryCta,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Symptom Checker',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Describe symptoms for personalized guidance',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white.withAlpha(180), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'First Aid Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ),

          // Emergency Categories
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCategoryCard(_categories[index]),
                childCount: _categories.length,
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(EmergencyCategory category) {
    final isExpanded = _expandedCategory == category.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? category.color.withAlpha(100) : AppColors.borderLight,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded 
                ? category.color.withAlpha(30) 
                : Colors.black.withAlpha(8),
            blurRadius: isExpanded ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategory = isExpanded ? null : category.id;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(category.icon, color: category.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category.subtitle,
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: category.color,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Steps
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildStepsList(category),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList(EmergencyCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: category.color.withAlpha(8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Column(
        children: [
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: category.steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final step = category.steps[index];
              return _buildStepCard(step, index + 1, category.color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(EmergencyStep step, int number, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: step.isImportant 
            ? Border.all(color: color.withAlpha(60), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        if (step.isImportant)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'CRITICAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Warning box
          if (step.warning != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D).withAlpha(80)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.warning!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Seek help indicator
          if (step.seekHelp) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_hospital_rounded, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seek veterinary care immediately',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Data models
class EmergencyCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<EmergencyStep> steps;

  EmergencyCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

class EmergencyStep {
  final String title;
  final String description;
  final String? warning;
  final bool isImportant;
  final bool seekHelp;

  EmergencyStep({
    required this.title,
    required this.description,
    this.warning,
    this.isImportant = false,
    this.seekHelp = false,
  });
}