# Minecraft Ore Finder 💎🏅

A TypeScript tool that analyzes Minecraft world seeds to predict diamond and gold locations and optimize your mining strategy.

## Flutter Mobile App

A complete Flutter application is included in the `flutter_app/` directory with:

### Features
- 📱 **Mobile-Friendly Interface**: Native iOS and Android support
- 🎯 **Interactive Search**: Easy input for coordinates and world seeds
- 💎 **Dual Ore Support**: Switch between diamond and gold finding
- 📊 **Top 10 Results**: Shows the most probable locations
- 📋 **Copy Coordinates**: Tap to copy coordinates to clipboard
- 🌙 **Dark Mode**: Automatic light/dark theme support

### Running the Flutter App

```bash
# Navigate to flutter app directory
cd flutter_app

# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run on specific platform
flutter run -d chrome          # Web browser
flutter run -d android         # Android device/emulator
flutter run -d ios             # iOS device/simulator

# Build for release
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle (for Play Store)
flutter build ios             # iOS (requires Xcode)
flutter build web             # Web deployment
```

### Platform Requirements

**Android:**
- Android Studio with Android SDK
- Android device or emulator
- Minimum SDK: API 21 (Android 5.0)

**iOS:**
- macOS with Xcode installed
- iOS device or iOS Simulator
- Apple Developer account (for device deployment)

**Web:**
- Modern web browser (Chrome, Firefox, Safari, Edge)

### App Usage
1. **Enter World Seed**: Your Minecraft world seed
2. **Set Search Center**: Your current X, Y, Z coordinates
3. **Choose Search Radius**: How far to search (max 1000 blocks)
4. **Select Ore Type**: Diamond or Gold
5. **Optional**: Include Nether Gold for gold searches
6. **Tap Search**: Get top 10 most probable locations
7. **Copy Coordinates**: Tap copy icon to use in-game

---

- 🔍 **Seed Analysis**: Uses Minecraft's world generation patterns to predict ore spawns
- � **LDiamond Finder**: Locate high-probability diamond coordinates
- 🏅 **Gold Finder**: Find gold ore locations with biome-specific analysis
- 📍 **Location Prediction**: Precise coordinate predictions for both ores
- ⛏️ **Mining Optimization**: Strategic mining recommendations for each ore type
- 🎯 **Chunk Information**: Shows chunk coordinates for easier navigation
- 📊 **Probability Scoring**: Ranks locations by ore spawn likelihood
- 🏔️ **Biome Detection**: Special handling for Badlands (Mesa) gold bonuses

## Installation

```bash
# Clone or download the project
git clone <your-repo-url>
cd minecraft-diamond-finder

# Install dependencies
npm install
```

## Usage

### Basic Usage

```bash
# Find diamonds using a numeric seed
npx ts-node minecraft-diamond-finder.ts 12345

# Find diamonds using a string seed
npx ts-node minecraft-diamond-finder.ts "MyAwesomeSeed"

# Find gold using a seed
npx ts-node minecraft-gold-finder.ts 12345

# Find gold including Nether locations
npx ts-node minecraft-gold-finder.ts "GoldRush" 0 0 500 --nether
```

### Advanced Usage

```bash
# Specify center coordinates and search radius
npx ts-node minecraft-diamond-finder.ts "DiamondHunter" 100 -200 500

# Parameters: <seed> [centerX] [centerZ] [radius]
# - seed: Your world seed (string or number)
# - centerX: X coordinate to center search around (default: 0)
# - centerZ: Z coordinate to center search around (default: 0)  
# - radius: Search radius in blocks (default: 300)
```

### Using NPM Scripts

```bash
# Find diamonds
npm run find-diamonds "12345" 0 0 400

# Find gold
npm run find-gold "GoldMiner" 100 -200 300

# Find all ores (diamonds + gold)
npm run find-all "MyWorld" 0 0 500
```

### All-in-One Shell Script

```bash
# Run both diamond and gold analysis
./find-all-ores.sh "MyWorld"

# With custom coordinates and radius
./find-all-ores.sh "MyWorld" 100 -200 500

# Include Nether gold ore
./find-all-ores.sh "GoldRush" 0 0 400 --nether

# Show help
./find-all-ores.sh --help
```

## Example Output

### Diamond Finder
```
🔍 Minecraft Diamond Finder
Seed: DiamondHunter
Center: (0, 0)
Search radius: 300 blocks

💎 Top 10 Diamond Locations:
────────────────────────────────────────────────────────────
1. Coordinates: (-48, -59, 112)
   Chunk: (-3, 7)
   Probability: 87.3%

2. Coordinates: (64, -55, -96)
   Chunk: (4, -6)
   Probability: 82.1%
```

### Gold Finder
```
🏆 Minecraft Gold Finder
Seed: GoldRush
Center: (0, 0)
Search radius: 300 blocks

🏅 Top 10 Gold Locations:

BADLANDS (EXCELLENT!):
1. Coordinates: (128, 64, -96)
   Chunk: (8, -6)
   Probability: 91.2%

OVERWORLD:
2. Coordinates: (-80, -24, 144)
   Chunk: (-5, 9)
   Probability: 73.8%

⛏️ Gold Mining Tips:
• Biome: Badlands/Mesa (EXCELLENT for gold!)
• Surface mining: Y 32 to 80 (very high gold rates)
• TIP: Badlands have 6x more gold than regular biomes!
```

## How It Works

The tool simulates Minecraft's ore generation algorithm by:

1. **Seed Processing**: Converts string seeds to numeric values
2. **Chunk Analysis**: Uses Linear Congruential Generator for predictable randomness
3. **Layer Optimization**: Focuses on Y levels -64 to 16 (diamond spawn range)
4. **Probability Calculation**: Combines multiple factors:
   - Optimal Y level proximity (peak at Y -59)
   - Chunk-based randomness
   - Coordinate-based variation
   - Simulated ore vein patterns

## Ore Spawn Information

### Diamonds
- **Y Range**: -64 to 16 (below Y 16)
- **Peak Layer**: Y -59 (highest concentration)
- **Good Layers**: Y -64 to -48
- **Decent Layers**: Y -47 to -32
- **Lower Chance**: Y -31 to 16

### Gold
- **Overworld Y Range**: -64 to 32
- **Peak Layers**: Y -32 to -16
- **Badlands Bonus**: Y 32 to 80 (6x more gold!)
- **Nether Gold**: Y 10 to 117 (Nether Gold Ore)

## Mining Tips

1. **Start at Y -59** for maximum diamond exposure
2. **Branch mining** every 2-3 blocks horizontally
3. **Strip mining** at multiple Y levels between -64 and -54
4. **Use coordinates** from the tool to plan your mining routes
5. **Bring plenty of torches** and food for long mining sessions

## API Usage

You can also use these as modules in your own projects:

```typescript
import { MinecraftDiamondFinder } from './minecraft-diamond-finder';
import { MinecraftGoldFinder } from './minecraft-gold-finder';

// Diamond finder
const diamondFinder = new MinecraftDiamondFinder({
  seed: "MyWorldSeed",
  version: "1.20"
});

const diamondSpots = diamondFinder.findBestMiningSpots(0, 0, 500, 10);

// Gold finder
const goldFinder = new MinecraftGoldFinder({
  seed: "MyWorldSeed", 
  version: "1.20"
});

const goldSpots = goldFinder.findBestMiningSpots(0, 0, 500, 10, true); // Include nether
const goldTips = goldFinder.getMiningRecommendations(100, -200);
```

## Compatibility

- **Minecraft Versions**: Designed for 1.18+ (cave update generation)
- **Node.js**: Requires Node.js 16+
- **TypeScript**: Built with TypeScript 5.0+

## Limitations

- This is a **prediction tool** based on generation patterns, not a guarantee
- Actual diamond spawns may vary due to:
  - Cave generation interference
  - Lava lake placement
  - Other ore generation conflicts
- Results are most accurate for **overworld** diamond generation
- Does not account for **structure generation** (villages, strongholds, etc.)

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - feel free to use and modify as needed.

---

**Happy Mining!** ⛏️💎