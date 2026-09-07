# Release Notes - Version 1.0.52
## Major Update: New Ores, Vein Size Estimates & Accuracy Overhaul

### 🆕 **Two New Ore Types**
- **🟠 Copper Ore**: Now searchable across Y -16 to 112, peaking around Y 48. Copper generates in large veins, so expect plenty per find.
- **💚 Emerald Ore**: Now searchable in mountain biomes only, all the way up to Y 320. Rare and valuable, generated as single blocks.

### 📦 **Estimated Vein Sizes**
- Every ore result now shows an **estimated number of blocks** in the vein, not just a probability.
- See at a glance whether a location is likely a small pocket or a large haul.
- Estimates scale with location quality — higher-probability spots suggest bigger veins.
- Includes the min/max range per ore type (e.g. coal 1–17, copper 1–20, diamond 1–10).

### 🎯 **Ore Distribution Accuracy Improvements**
- **Diamonds**: More accurate deep-layer distribution, better reflecting the Y -4 to 16 band.
- **Coal**: Now correctly found up to Y 320 in mountainous terrain.
- **Nether Gold**: Uses the correct Nether distribution (Y 10–117) instead of the overworld pattern.
- **Ore Veins**: Cleaner contrast between dense vein centers and empty rock for more realistic results.

### 🏛 **Structure Finding Accuracy Improvements**
- **Strongholds**: Now placed using Minecraft's authentic ring-based system (concentric rings around the world origin) instead of an even grid.
- **Ancient Cities**: Restricted to Deep Dark areas, matching real generation.
- **Buried Treasure**: Uses proper per-chunk placement at the correct chunk position.
- **Biomes**: Structure biome detection is now spatially coherent, so structures show up in believable, connected regions instead of scattered noise.

### ⚡ **Performance**
- Faster searches through reduced overhead during large-radius scans.
- More thorough Netherite scanning that no longer skips over small Ancient Debris veins.

### 🎯 **Perfect for All Players**
- **Miners**: Know roughly how much ore awaits before you dig.
- **Builders**: Locate copper and emerald for the first time in-app.
- **Explorers**: Trust structure locations with more realistic placement.

---

# Release Notes - Version 1.0.36
## Quality of Life Update: Complete Search Persistence

### 💾 **Complete Search Memory Feature**
- **Automatic Parameter Saving**: The app now remembers ALL your search parameters
- **World Seed Persistence**: Your world seed is automatically saved and restored
- **Coordinate Memory**: X, Y, Z coordinates are remembered between sessions
- **Search Radius Persistence**: Your preferred search radius is saved
- **Instant Restoration**: When you restart the app, all your last search settings are loaded
- **No More Re-typing**: Never lose your search configuration again

### 🎯 **Enhanced User Experience**
- **Seamless Workflow**: Continue your ore hunting sessions exactly where you left off
- **Time Saving**: Eliminates the need to remember and re-enter all search parameters
- **Better Productivity**: Focus on finding ores instead of configuring search settings
- **Perfect for Regular Users**: Ideal for players who frequently search the same world areas

### 🔧 **Technical Improvements**
- **Comprehensive Persistence**: All text input fields are automatically saved
- **Smart Defaults**: Falls back to sensible defaults for new users
- **Efficient Storage**: Uses platform-native storage for optimal performance
- **Cross-Platform**: Works consistently across all supported platforms

This update addresses the most requested feature from our German-speaking community and significantly improves the workflow for all players.

---

# Release Notes - Version 1.0.27
## Minor Update
Updated splash screen and icons


# Release Notes - Version 1.0.22
## Major Update: Extended Ore Discovery & Enhanced UI

### 🆕 New Ore Types Added
We've significantly expanded the ore discovery capabilities with three essential new ore types:

#### ⚪ **Iron Ore Discovery**
- **Y-Level Range**: Y -64 to 256 (entire world height)
- **Peak Generation Zones**:
  - Mountain Iron: Y 128-256 (peaks at Y 232)
  - Underground Iron: Y -24 to 56 (peaks at Y 15)
- **Uses**: Essential for tools, armor, redstone contraptions, anvils, hoppers, and iron golems

#### 🔴 **Redstone Ore Discovery**
- **Y-Level Range**: Y -64 to 15 (deep underground)
- **Peak Generation Zones**:
  - Optimal Layer: Y -64 to -59 (90% probability)
  - Good Layers: Y -58 to -48 (70% probability)
- **Uses**: Automation systems, powered mechanisms, farms, and complex contraptions

#### ⚫ **Coal Ore Discovery**
- **Y-Level Range**: Y 0 to 256 (surface to sky limit)
- **Peak Generation Zone**: Y 80-136 (peaks at Y 96)
- **Uses**: Primary fuel source, torch crafting, and efficient storage as coal blocks

### 🎨 **Improved User Interface**
- **Compact Ore Selection**: Redesigned ore picker with space-efficient layout
  - Row 1: Diamond 💎, Gold 🏅, Iron ⚪
  - Row 2: Redstone 🔴, Coal ⚫
  - Separate Netherite button for special searches
- **Visual Legend**: Added emoji legend to clarify ore types
- **Enhanced Tooltips**: Better user guidance throughout the interface

### 🔍 **Enhanced Results & Filtering**
- **Extended Ore Filters**: Results page now includes filter chips for all 6 ore types
- **Complete Coverage**: Filter and view results for Diamond, Gold, Iron, Redstone, Coal, and Netherite
- **Improved Color Coding**: Each ore type has distinct colors in results display

### 📚 **Comprehensive Guide Updates**
- **Detailed Mining Guides**: Added complete information for Iron, Redstone, and Coal
- **Optimal Y-Level Data**: Precise mining recommendations for each ore type
- **Practical Usage Info**: Explains what each ore is used for in Minecraft gameplay
- **Enhanced Formatting**: Consistent styling with emojis and color coding

### 🛠 **Technical Improvements**
- **Realistic Generation Patterns**: Ore spawning algorithms match actual Minecraft behavior
- **Optimized Search Performance**: Efficient Y-level scanning for each ore type
- **Better Error Handling**: Improved stability and user experience
- **Enhanced Probability Calculations**: More accurate ore location predictions

### 🎯 **Perfect for All Players**
- **Speedrunners**: Quickly locate essential ores for efficient runs
- **Builders**: Find iron for tools and redstone for mechanisms
- **Miners**: Optimize mining efficiency with probability-based locations
- **Automation Enthusiasts**: Locate redstone for complex contraptions
- **New Players**: Learn optimal mining levels for each resource

### 📱 **Cross-Platform Compatibility**
- All new features work seamlessly across phones, tablets, and web browsers
- Responsive design optimized for all screen sizes
- Consistent experience across all platforms

---

## Previous Updates

### Version 1.0.20 - Structure Discovery
- Added comprehensive structure finding capabilities
- Village, stronghold, and rare structure discovery
- Advanced biome filtering and coordinate ranges

### Version 1.0.15 - Initial Release
- Diamond, Gold, and Netherite ore discovery
- World seed analysis and probability calculations
- Dark/light theme support