import 'dart:math';
import 'package:flutter/material.dart';
import 'brainchip_data.dart';
import 'game_state.dart';
import 'nation_selection_screen.dart';
import 'main.dart';
import 'start_screen.dart';

class BrainChipSelectionScreen extends StatefulWidget {
  const BrainChipSelectionScreen({super.key});
  @override
  State<BrainChipSelectionScreen> createState() => _BrainChipSelectionScreenState();
}

class _BrainChipSelectionScreenState extends State<BrainChipSelectionScreen> {
  late BrainChip chip;
  @override
  void initState() {
    super.initState();
    final rnd = Random();
    chip = brainChipPool[rnd.nextInt(brainChipPool.length)];
    GameState.selectedBrainChipId = chip.id;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CyberBackground()),
          Center(
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF6CE4FF).withValues(alpha: 0.5)),
                boxShadow: [BoxShadow(color: const Color(0xFF6CE4FF).withValues(alpha: 0.2), blurRadius: 16)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.memory, color: Color(0xFF6CE4FF), size: 18),
                      SizedBox(width: 8),
                      Text("// BRAIN-CHIP", style: TextStyle(color: Color(0xFF6CE4FF), fontSize: 12, fontFamily: 'monospace', letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(chip.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text("Lv.${chip.level} · ${chip.effect ?? ''}", style: const TextStyle(color: Color(0xFF8FA3C0), fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(chip.description, style: const TextStyle(color: Color(0xFF8FA3C0), fontSize: 12, height: 1.5)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: CyberButton(
                          label: '确认装备',
                          height: 40,
                          fontSize: 12,
                          onPressed: () {
                            Navigator.pushReplacement(context, createHoloRoute(const NationSelectionScreen()));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
