#!/bin/bash

# Minecraft All Ores Finder
# Runs both diamond and gold finders with the same parameters

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored headers
print_header() {
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '%*s' 80 '' | tr ' ' '=')${NC}"
}

print_subheader() {
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}$(printf '%*s' 60 '' | tr ' ' '-')${NC}"
}

# Function to show usage
show_usage() {
    echo -e "${GREEN}Minecraft All Ores Finder${NC}"
    echo ""
    echo "Usage: $0 <seed> [x] [z] [radius] [options]"
    echo ""
    echo "Parameters:"
    echo "  seed     - World seed (string or number)"
    echo "  x        - Center X coordinate (default: 0)"
    echo "  z        - Center Z coordinate (default: 0)"
    echo "  radius   - Search radius in blocks (default: 300)"
    echo ""
    echo "Options:"
    echo "  --nether - Include Nether gold ore in search"
    echo "  --help   - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 12345"
    echo "  $0 \"MyWorld\" 100 -200 500"
    echo "  $0 \"GoldRush\" 0 0 400 --nether"
    echo ""
}

# Function to check if required tools are available
check_dependencies() {
    if ! command -v npx &> /dev/null; then
        echo -e "${RED}Error: npx is not installed. Please install Node.js and npm.${NC}"
        exit 1
    fi
    
    if ! command -v ts-node &> /dev/null; then
        echo -e "${YELLOW}Warning: ts-node not found globally. Will use npx ts-node.${NC}"
    fi
    
    if [ ! -f "minecraft-diamond-finder.ts" ]; then
        echo -e "${RED}Error: minecraft-diamond-finder.ts not found in current directory.${NC}"
        exit 1
    fi
    
    if [ ! -f "minecraft-gold-finder.ts" ]; then
        echo -e "${RED}Error: minecraft-gold-finder.ts not found in current directory.${NC}"
        exit 1
    fi
}

# Function to run diamond finder
run_diamond_finder() {
    local seed="$1"
    local x="$2"
    local z="$3"
    local radius="$4"
    
    print_subheader "💎 DIAMOND ANALYSIS"
    echo ""
    
    if command -v ts-node &> /dev/null; then
        ts-node minecraft-diamond-finder.ts "$seed" "$x" "$z" "$radius"
    else
        npx ts-node minecraft-diamond-finder.ts "$seed" "$x" "$z" "$radius"
    fi
    
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Diamond finder failed with exit code $exit_code${NC}"
        return $exit_code
    fi
}

# Function to run gold finder
run_gold_finder() {
    local seed="$1"
    local x="$2"
    local z="$3"
    local radius="$4"
    local nether_flag="$5"
    
    print_subheader "🏅 GOLD ANALYSIS"
    echo ""
    
    local cmd_args=("$seed" "$x" "$z" "$radius")
    if [ "$nether_flag" = "true" ]; then
        cmd_args+=("--nether")
    fi
    
    if command -v ts-node &> /dev/null; then
        ts-node minecraft-gold-finder.ts "${cmd_args[@]}"
    else
        npx ts-node minecraft-gold-finder.ts "${cmd_args[@]}"
    fi
    
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Gold finder failed with exit code $exit_code${NC}"
        return $exit_code
    fi
}

# Function to get top coordinates from finder output
get_top_coordinates() {
    local finder_type="$1"
    local seed="$2"
    local x="$3"
    local z="$4"
    local radius="$5"
    local nether_flag="$6"
    
    local cmd_args=("$seed" "$x" "$z" "$radius")
    if [ "$finder_type" = "gold" ] && [ "$nether_flag" = "true" ]; then
        cmd_args+=("--nether")
    fi
    
    local output
    if command -v ts-node &> /dev/null; then
        if [ "$finder_type" = "diamond" ]; then
            output=$(ts-node minecraft-diamond-finder.ts "${cmd_args[@]}" 2>/dev/null)
        else
            output=$(ts-node minecraft-gold-finder.ts "${cmd_args[@]}" 2>/dev/null)
        fi
    else
        if [ "$finder_type" = "diamond" ]; then
            output=$(npx ts-node minecraft-diamond-finder.ts "${cmd_args[@]}" 2>/dev/null)
        else
            output=$(npx ts-node minecraft-gold-finder.ts "${cmd_args[@]}" 2>/dev/null)
        fi
    fi
    
    # Extract top 5 coordinates with probability using a simpler approach
    echo "$output" | awk '
    BEGIN { count = 0 }
    /^[0-9]+\. Coordinates:/ { 
        if (count >= 5) exit
        coord = $0
        gsub(/^[0-9]*\. /, "", coord)
        getline  # skip chunk line
        getline  # get probability line
        if ($0 ~ /Probability:/) {
            prob = $0
            gsub(/.*Probability: /, "", prob)
            print coord " - " prob
            count++
        }
    }'
}

# Function to provide quick summary
provide_quick_summary() {
    local seed="$1"
    local x="$2"
    local z="$3"
    local radius="$4"
    local nether_flag="$5"
    
    echo ""
    print_subheader "📋 QUICK REFERENCE SUMMARY"
    echo ""
    
    echo -e "${CYAN}Input Parameters:${NC}"
    echo "• Seed: $seed"
    echo "• Center: ($x, $z)"
    echo "• Radius: $radius blocks"
    if [ "$nether_flag" = "true" ]; then
        echo "• Nether: Included"
    fi
    echo ""
    
    echo -e "${PURPLE}💎 Top 5 Diamond Locations:${NC}"
    local diamond_coords
    diamond_coords=$(get_top_coordinates "diamond" "$seed" "$x" "$z" "$radius" "$nether_flag")
    if [ -n "$diamond_coords" ]; then
        echo "$diamond_coords" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "  $line"
            fi
        done
    else
        echo "  No high-probability diamond locations found"
    fi
    echo ""
    
    echo -e "${YELLOW}🏅 Top 5 Gold Locations:${NC}"
    local gold_coords
    gold_coords=$(get_top_coordinates "gold" "$seed" "$x" "$z" "$radius" "$nether_flag")
    if [ -n "$gold_coords" ]; then
        echo "$gold_coords" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "  $line"
            fi
        done
    else
        echo "  No high-probability gold locations found"
    fi
    echo ""
    
    echo -e "${GREEN}Quick Mining Plan:${NC}"
    echo "1. Start with diamonds at Y -59 (deeper, more valuable)"
    echo "2. Mine gold at Y -24 on your way up (higher levels)"
    echo "3. Check top 5 coordinates above for best probability spots"
    echo "4. Plan routes connecting multiple high-probability locations"
    echo ""
}

# Function to provide combined analysis
provide_combined_analysis() {
    local seed="$1"
    local x="$2"
    local z="$3"
    local radius="$4"
    local nether_flag="$5"
    
    print_subheader "📊 COMBINED MINING STRATEGY"
    echo ""
    
    echo -e "${GREEN}Optimal Mining Plan for Seed: $seed${NC}"
    echo -e "Search Area: ($x, $z) with radius $radius blocks"
    echo ""
    
    echo -e "${PURPLE}Mining Priority Recommendations:${NC}"
    echo "1. 💎 Diamond Mining (Y -64 to -48):"
    echo "   • Focus on Y -59 for maximum diamond yield"
    echo "   • Use branch mining technique"
    echo "   • Bring plenty of iron pickaxes or better"
    echo ""
    
    echo "2. 🏅 Gold Mining (Y -32 to -16):"
    echo "   • Best gold layers are higher than diamonds"
    echo "   • Use Fortune III pickaxe for maximum gold yield"
    echo "   • Check for Badlands biomes for 6x gold bonus"
    echo ""
    
    if [ "$nether_flag" = "true" ]; then
        echo "3. 🔥 Nether Gold Mining (Y 10 to 117):"
        echo "   • Bring fire resistance potions"
        echo "   • Nether gold ore drops 2-6 nuggets"
        echo "   • Much more common than overworld gold"
        echo ""
    fi
    
    echo -e "${BLUE}Efficiency Tips:${NC}"
    echo "• Mine diamonds first (deeper, more valuable)"
    echo "• Mine gold on the way up (higher Y levels)"
    echo "• Create vertical shafts connecting both layers"
    echo "• Use water bucket for lava safety"
    echo "• Bring food and torches for long mining sessions"
    echo ""
    
    echo -e "${CYAN}Resource Planning:${NC}"
    echo "• Iron pickaxes: Minimum for diamonds"
    echo "• Diamond pickaxe with Fortune III: Best for gold"
    echo "• Efficiency enchantment: Faster mining"
    echo "• Unbreaking: Longer tool durability"
    echo ""
}

# Main script execution
main() {
    # Parse command line arguments
    if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_usage
        exit 0
    fi
    
    local seed="$1"
    local x="${2:-0}"
    local z="${3:-0}"
    local radius="${4:-300}"
    local include_nether=false
    
    # Check for nether flag
    for arg in "$@"; do
        if [ "$arg" = "--nether" ]; then
            include_nether=true
            break
        fi
    done
    
    # Validate numeric inputs
    if ! [[ "$x" =~ ^-?[0-9]+$ ]]; then
        echo -e "${RED}Error: X coordinate must be a number${NC}"
        exit 1
    fi
    
    if ! [[ "$z" =~ ^-?[0-9]+$ ]]; then
        echo -e "${RED}Error: Z coordinate must be a number${NC}"
        exit 1
    fi
    
    if ! [[ "$radius" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Radius must be a positive number${NC}"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Print main header
    print_header "🎯 MINECRAFT ALL ORES FINDER"
    echo ""
    echo -e "${GREEN}Analyzing seed: ${YELLOW}$seed${NC}"
    echo -e "${GREEN}Center coordinates: ${YELLOW}($x, $z)${NC}"
    echo -e "${GREEN}Search radius: ${YELLOW}$radius blocks${NC}"
    if [ "$include_nether" = "true" ]; then
        echo -e "${GREEN}Including: ${YELLOW}Nether Gold Ore${NC}"
    fi
    echo ""
    
    # Run diamond finder
    echo ""
    if ! run_diamond_finder "$seed" "$x" "$z" "$radius"; then
        echo -e "${RED}Failed to run diamond analysis${NC}"
        exit 1
    fi
    
    echo ""
    echo ""
    
    # Run gold finder
    if ! run_gold_finder "$seed" "$x" "$z" "$radius" "$include_nether"; then
        echo -e "${RED}Failed to run gold analysis${NC}"
        exit 1
    fi
    
    echo ""
    echo ""
    
    # Provide combined analysis
    provide_combined_analysis "$seed" "$x" "$z" "$radius" "$include_nether"
    
    echo ""
    print_header "✅ ANALYSIS COMPLETE"
    
    # Quick summary
    provide_quick_summary "$seed" "$x" "$z" "$radius" "$include_nether"
    
    echo -e "${GREEN}Happy mining! ⛏️💎🏅${NC}"
}

# Run main function with all arguments
main "$@"