#!/usr/bin/env node

/**
 * Minecraft Gold Finder
 * Analyzes world generation patterns to predict gold locations
 */

interface GoldLocation {
  x: number;
  y: number;
  z: number;
  chunkX: number;
  chunkZ: number;
  probability: number;
  biome: 'overworld' | 'nether' | 'badlands';
}

interface WorldSeed {
  seed: string | number;
  version: string;
}

class MinecraftGoldFinder {
  private seed: number;
  private version: string;

  constructor(worldSeed: WorldSeed) {
    this.seed = typeof worldSeed.seed === 'string' 
      ? this.stringToSeed(worldSeed.seed) 
      : worldSeed.seed;
    this.version = worldSeed.version;
  }

  /**
   * Convert string seed to numeric seed (simplified)
   */
  private stringToSeed(seedStr: string): number {
    let hash = 0;
    for (let i = 0; i < seedStr.length; i++) {
      const char = seedStr.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash;
  }

  /**
   * Simple LCG (Linear Congruential Generator) for predictable randomness
   */
  private lcg(seed: number): number {
    return (seed * 1664525 + 1013904223) % Math.pow(2, 32);
  }

  /**
   * Generate chunk-based random number
   */
  private getChunkRandom(chunkX: number, chunkZ: number, layer: number): number {
    const chunkSeed = this.seed ^ (chunkX * 341873128712 + chunkZ * 132897987541 + layer);
    return this.lcg(Math.abs(chunkSeed));
  }

  /**
   * Determine biome type based on coordinates (simplified)
   */
  private getBiomeType(x: number, z: number): 'overworld' | 'nether' | 'badlands' {
    // Simplified biome detection - in reality this would be much more complex
    const biomeRandom = this.getChunkRandom(Math.floor(x / 64), Math.floor(z / 64), 0) / Math.pow(2, 32);
    
    // Simulate badlands biome (mesa) - roughly 5% of overworld
    if (biomeRandom > 0.95) {
      return 'badlands';
    }
    
    return 'overworld';
  }

  /**
   * Check if gold can spawn at given coordinates and biome
   */
  private isGoldLayer(y: number, biome: 'overworld' | 'nether' | 'badlands'): boolean {
    switch (biome) {
      case 'overworld':
        return y >= -64 && y <= 32; // Gold spawns from -64 to 32 in overworld
      case 'badlands':
        return y >= -64 && y <= 256; // Gold spawns much higher in badlands/mesa
      case 'nether':
        return y >= 10 && y <= 117; // Nether gold spawns in middle layers
      default:
        return false;
    }
  }

  /**
   * Calculate gold probability for a specific location
   */
  private calculateGoldProbability(x: number, y: number, z: number): number {
    const biome = this.getBiomeType(x, z);
    
    if (!this.isGoldLayer(y, biome)) return 0;

    const chunkX = Math.floor(x / 16);
    const chunkZ = Math.floor(z / 16);
    
    let probability = 0;
    
    // Biome-specific probability calculation
    switch (biome) {
      case 'overworld':
        if (y >= -64 && y <= -48) {
          probability += 0.4; // Lower levels
        } else if (y >= -47 && y <= -16) {
          probability += 0.6; // Peak gold layer
        } else if (y >= -15 && y <= 32) {
          probability += 0.3; // Higher levels
        }
        break;
        
      case 'badlands':
        // Badlands have much more gold at higher elevations
        if (y >= 32 && y <= 80) {
          probability += 0.9; // Excellent gold generation
        } else if (y >= -64 && y <= 31) {
          probability += 0.7; // Good underground gold
        } else if (y >= 81 && y <= 256) {
          probability += 0.5; // Surface gold
        }
        break;
        
      case 'nether':
        // Nether gold (different ore - nether gold ore)
        if (y >= 10 && y <= 117) {
          probability += 0.8; // High nether gold probability
        }
        break;
    }

    // Add randomness based on chunk and coordinates
    const random1 = this.getChunkRandom(chunkX, chunkZ, y) / Math.pow(2, 32);
    const random2 = this.getChunkRandom(chunkX + x % 16, chunkZ + z % 16, y) / Math.pow(2, 32);
    
    // Simulate ore vein generation patterns
    const veinFactor = Math.sin(x * 0.15) * Math.cos(z * 0.15) * Math.sin(y * 0.1);
    probability *= (0.4 + random1 * 0.3 + random2 * 0.3 + Math.abs(veinFactor) * 0.2);

    return Math.min(probability, 1.0);
  }

  /**
   * Find potential gold locations in a given area
   */
  public findGold(
    centerX: number = 0,
    centerZ: number = 0,
    radius: number = 500,
    minProbability: number = 0.6,
    includeNether: boolean = false
  ): GoldLocation[] {
    const locations: GoldLocation[] = [];
    const step = 8; // Check every 8 blocks for performance

    console.log(`Scanning area around (${centerX}, ${centerZ}) with radius ${radius}...`);
    
    for (let x = centerX - radius; x <= centerX + radius; x += step) {
      for (let z = centerZ - radius; z <= centerZ + radius; z += step) {
        const biome = this.getBiomeType(x, z);
        
        // Determine Y range based on biome
        let yMin = -64, yMax = 32, yStep = 4;
        
        if (biome === 'badlands') {
          yMax = 256;
          yStep = 8; // Larger steps for badlands due to height
        } else if (biome === 'nether' && includeNether) {
          yMin = 10;
          yMax = 117;
        } else if (biome === 'nether' && !includeNether) {
          continue; // Skip nether if not requested
        }
        
        for (let y = yMin; y <= yMax; y += yStep) {
          const probability = this.calculateGoldProbability(x, y, z);
          
          if (probability >= minProbability) {
            locations.push({
              x,
              y,
              z,
              chunkX: Math.floor(x / 16),
              chunkZ: Math.floor(z / 16),
              probability: Math.round(probability * 100) / 100,
              biome
            });
          }
        }
      }
    }

    return locations.sort((a, b) => b.probability - a.probability);
  }

  /**
   * Find the best gold mining spots
   */
  public findBestMiningSpots(
    centerX: number = 0,
    centerZ: number = 0,
    radius: number = 300,
    topCount: number = 10,
    includeNether: boolean = false
  ): GoldLocation[] {
    const locations = this.findGold(centerX, centerZ, radius, 0.5, includeNether);
    return locations.slice(0, topCount);
  }

  /**
   * Get mining recommendations for gold
   */
  public getMiningRecommendations(x: number, z: number): string[] {
    const recommendations: string[] = [];
    const biome = this.getBiomeType(x, z);
    
    recommendations.push(`Gold mining recommendations for coordinates (${x}, ${z}):`);
    
    switch (biome) {
      case 'overworld':
        recommendations.push(`• Biome: Regular Overworld`);
        recommendations.push(`• Best Y levels: -32 to -16 (peak gold generation)`);
        recommendations.push(`• Also check: Y -64 to -48 for deeper veins`);
        recommendations.push(`• Surface gold: Y -15 to 32 (lower chance)`);
        break;
        
      case 'badlands':
        recommendations.push(`• Biome: Badlands/Mesa (EXCELLENT for gold!)`);
        recommendations.push(`• Surface mining: Y 32 to 80 (very high gold rates)`);
        recommendations.push(`• Underground: Y -64 to 31 (good rates)`);
        recommendations.push(`• High altitude: Y 81+ (moderate rates)`);
        recommendations.push(`• TIP: Badlands have 6x more gold than regular biomes!`);
        break;
        
      case 'nether':
        recommendations.push(`• Biome: Nether`);
        recommendations.push(`• Nether Gold Ore: Y 10 to 117`);
        recommendations.push(`• Best with Fortune pickaxe for nuggets`);
        recommendations.push(`• WARNING: Bring fire resistance potions!`);
        break;
    }
    
    recommendations.push(`• Create branch mines every 2-3 blocks`);
    recommendations.push(`• Use Fortune III pickaxe for maximum yield`);
    
    const bestSpots = this.findBestMiningSpots(x, z, 100, 3);
    if (bestSpots.length > 0) {
      recommendations.push(`• Highest probability spots nearby:`);
      bestSpots.forEach((spot, index) => {
        const biomeLabel = spot.biome === 'badlands' ? ' (BADLANDS!)' : 
                          spot.biome === 'nether' ? ' (NETHER)' : '';
        recommendations.push(`  ${index + 1}. (${spot.x}, ${spot.y}, ${spot.z}) - ${(spot.probability * 100).toFixed(1)}%${biomeLabel}`);
      });
    }

    return recommendations;
  }

  /**
   * Compare gold vs diamond mining efficiency
   */
  public compareWithDiamonds(x: number, z: number): string[] {
    const comparison: string[] = [];
    const biome = this.getBiomeType(x, z);
    
    comparison.push(`Gold vs Diamond Mining Comparison:`);
    comparison.push(`• Gold is more common than diamonds`);
    comparison.push(`• Gold has wider Y-level distribution`);
    comparison.push(`• Gold tools are faster but less durable`);
    
    if (biome === 'badlands') {
      comparison.push(`• BADLANDS BONUS: This area has exceptional gold rates!`);
      comparison.push(`• Consider prioritizing gold mining here`);
    }
    
    comparison.push(`• Gold Y range: -64 to 32 (vs diamonds: -64 to 16)`);
    comparison.push(`• Gold peak: Y -32 to -16 (vs diamonds: Y -59)`);
    
    return comparison;
  }
}

// CLI Interface
function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 1) {
    console.log('Usage: npx ts-node minecraft-gold-finder.ts <seed> [x] [z] [radius] [--nether]');
    console.log('Example: npx ts-node minecraft-gold-finder.ts 12345 0 0 500');
    console.log('Example: npx ts-node minecraft-gold-finder.ts "GoldRush" 100 -200 400 --nether');
    process.exit(1);
  }

  const seed = args[0];
  const centerX = parseInt(args[1]) || 0;
  const centerZ = parseInt(args[2]) || 0;
  const radius = parseInt(args[3]) || 300;
  const includeNether = args.includes('--nether');

  const finder = new MinecraftGoldFinder({
    seed: seed,
    version: '1.20'
  });

  console.log(`🏆 Minecraft Gold Finder`);
  console.log(`Seed: ${seed}`);
  console.log(`Center: (${centerX}, ${centerZ})`);
  console.log(`Search radius: ${radius} blocks`);
  console.log(`Include Nether: ${includeNether ? 'Yes' : 'No'}\n`);

  // Find best mining spots
  const bestSpots = finder.findBestMiningSpots(centerX, centerZ, radius, 15, includeNether);
  
  if (bestSpots.length === 0) {
    console.log('No high-probability gold locations found in this area.');
    console.log('Try expanding your search radius or checking a different area.');
    return;
  }

  console.log(`🏅 Top ${bestSpots.length} Gold Locations:`);
  console.log('─'.repeat(70));
  
  // Group by biome for better organization
  const byBiome = bestSpots.reduce((acc, location) => {
    if (!acc[location.biome]) acc[location.biome] = [];
    acc[location.biome].push(location);
    return acc;
  }, {} as Record<string, GoldLocation[]>);

  Object.entries(byBiome).forEach(([biome, locations]) => {
    const biomeLabel = biome === 'badlands' ? 'BADLANDS (EXCELLENT!)' : 
                      biome === 'nether' ? 'NETHER' : 'OVERWORLD';
    console.log(`\n${biomeLabel}:`);
    
    locations.forEach((location, index) => {
      const globalIndex = bestSpots.indexOf(location) + 1;
      console.log(`${globalIndex}. Coordinates: (${location.x}, ${location.y}, ${location.z})`);
      console.log(`   Chunk: (${location.chunkX}, ${location.chunkZ})`);
      console.log(`   Probability: ${(location.probability * 100).toFixed(1)}%`);
      console.log('');
    });
  });

  // Get mining recommendations
  const recommendations = finder.getMiningRecommendations(centerX, centerZ);
  console.log('⛏️  Gold Mining Tips:');
  console.log('─'.repeat(70));
  recommendations.forEach(rec => console.log(rec));

  // Add comparison with diamonds
  console.log('\n📊 Gold vs Diamond Analysis:');
  console.log('─'.repeat(70));
  const comparison = finder.compareWithDiamonds(centerX, centerZ);
  comparison.forEach(comp => console.log(comp));
}

// Export for use as module
export { MinecraftGoldFinder, GoldLocation, WorldSeed };

// Run if called directly
if (typeof require !== 'undefined' && require.main === module) {
  main();
}