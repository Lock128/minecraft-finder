import 'java_random.dart';
import 'bedrock_random.dart';

/// Minecraft edition variants
enum MinecraftEdition { java, bedrock }

/// Version era for ore distribution model selection
enum VersionEra { legacy, modern }

/// Abstract RNG strategy that both JavaRandom and BedrockRandom implement.
///
/// Use [GameRandom.forEdition] to obtain the correct implementation
/// for a given Minecraft edition.
abstract class GameRandom {
  void setSeed(int seed);
  int nextInt(int bound);
  int nextLong();
  double nextDouble();
  double nextFloat();
  bool nextBool();

  factory GameRandom.forEdition(MinecraftEdition edition, int seed) {
    switch (edition) {
      case MinecraftEdition.java:
        return JavaRandom(seed);
      case MinecraftEdition.bedrock:
        return BedrockRandom(seed);
    }
  }
}
