# Proposed Features & Improvements

This document outlines proposed future features and improvements for the Minecraft Ore & Structure Finder application, organized by priority level.

---

## High Priority

### 1. Proper Translations for New Localization Keys

| | |
|---|---|
| **Complexity** | Low |
| **Priority** | High |

The 10 new l10n keys added during the modernization effort currently use English placeholder text for German (de), Spanish (es), French (fr), and Japanese (ja) locales. These need proper translations from native speakers or professional translation services to maintain the app's multilingual quality.

**Why it adds value:** The app already supports multiple languages, and untranslated keys break the user experience for non-English speakers -- a significant portion of the Minecraft community.

---

### 2. Export/Share Functionality

| | |
|---|---|
| **Complexity** | Medium |
| **Priority** | High |

Allow users to share search results or favorited locations with friends as images or formatted text. This could integrate with platform share sheets (iOS/Android) and support clipboard copy for web.

**Why it adds value:** Minecraft is inherently social. Players frequently share seed information and coordinates with friends on the same server, making this a natural and high-demand feature.

---

### 3. Map-Tap Coordinate Input

| | |
|---|---|
| **Complexity** | Medium |
| **Priority** | High |

Allow users to set the search center by tapping directly on the 2D world map instead of manually typing X/Z coordinates. The tapped location would populate the coordinate fields automatically.

**Why it adds value:** Reduces friction in the most common workflow. Many users think spatially about their world and find it easier to point at a location than recall exact coordinates.

---

## Medium Priority

### 4. Biome Heatmap on Map

| | |
|---|---|
| **Complexity** | High |
| **Priority** | Medium |

Color the 2D map background by biome zones (desert, forest, ocean, etc.) to provide environmental context when viewing ore/structure search results. Biome data can be derived from the seed using known generation algorithms.

**Why it adds value:** Biome context helps players plan expeditions more effectively. Knowing that a cluster of diamonds is under a desert vs. an ocean changes the mining approach entirely.

---

### 5. Offline Seed Database

| | |
|---|---|
| **Complexity** | Medium |
| **Priority** | Medium |

Pre-compute ore/structure locations for popular seeds and bundle them as a local database. This provides instant results for well-known seeds without requiring on-device computation.

**Why it adds value:** Reduces wait times for popular seeds, works fully offline, and improves the experience on lower-powered devices where computation is slow.

---

### 6. Chunk Border Overlay

| | |
|---|---|
| **Complexity** | Low |
| **Priority** | Medium |

Display chunk boundaries (16x16 block grid) on the 2D map view. This helps players align their mining routes with chunk edges, which is relevant for certain game mechanics like spawn algorithms and loading behavior.

**Why it adds value:** Experienced players think in terms of chunks for efficient exploration and resource gathering. This overlay bridges the gap between the finder tool and in-game navigation.

---

### 7. Seed Comparison Mode

| | |
|---|---|
| **Complexity** | High |
| **Priority** | Medium |

Enable side-by-side comparison of ore distributions across multiple seeds. Users could input 2-4 seeds and see a visual comparison of resource density, helping them choose the best world for a new survival playthrough.

**Why it adds value:** Choosing a seed is a major decision for long-term survival worlds. A comparison tool turns this from guesswork into an informed decision.

---

## Low Priority

### 8. Route Optimization

| | |
|---|---|
| **Complexity** | High |
| **Priority** | Low |

Given multiple found ore/structure locations, calculate and suggest the optimal mining path (shortest route visiting all points). This is essentially a Traveling Salesman Problem (TSP) solution applied to Minecraft coordinates.

**Why it adds value:** Saves players time during mining expeditions by providing an efficient order to visit discovered locations, especially useful when many results are spread across a large area.

---

### 9. Community Seed Sharing

| | |
|---|---|
| **Complexity** | High |
| **Priority** | Low |

Build a backend service (leveraging the existing AWS CDK infrastructure) that allows users to share, browse, and rate seeds. Users could tag seeds with notable features (e.g., "village at spawn", "stronghold nearby") and browse community-curated collections.

**Why it adds value:** Creates a community around the app and provides ongoing value beyond individual searches. The existing AWS infrastructure lowers the barrier to implementation.

---

### 10. Real-Time Collaboration

| | |
|---|---|
| **Complexity** | Very High |
| **Priority** | Low |

Allow users to share a live search session with friends who are playing on the same seed. Multiple users could see each other's marked locations and coordinate exploration in real time.

**Why it adds value:** Multiplayer coordination is a common use case. Real-time collaboration would make this tool invaluable for SMP (Survival Multiplayer) groups planning resource gathering together.

---

## Summary Table

| # | Feature | Priority | Complexity | Category |
|---|---------|----------|------------|----------|
| 1 | Proper Translations | High | Low | Localization |
| 2 | Export/Share Functionality | High | Medium | Social |
| 3 | Map-Tap Coordinate Input | High | Medium | UX |
| 4 | Biome Heatmap on Map | Medium | High | Visualization |
| 5 | Offline Seed Database | Medium | Medium | Performance |
| 6 | Chunk Border Overlay | Medium | Low | Visualization |
| 7 | Seed Comparison Mode | Medium | High | Analysis |
| 8 | Route Optimization | Low | High | Analysis |
| 9 | Community Seed Sharing | Low | High | Social |
| 10 | Real-Time Collaboration | Low | Very High | Social |

---

## Contributing

If you are interested in contributing to any of these features, please open an issue to discuss the approach before starting implementation. We welcome contributions of all sizes, from translations to full feature implementations.
