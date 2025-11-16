#!/bin/bash

# Create Piggy Bank Game Instances
# This script creates piggy bank game instances with predefined parameter sets

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get active environment
get_active_env() {
    sui client active-env 2>/dev/null || echo "unknown"
}

# Function to generate timestamp
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Function to save game creation output to files
save_game_output() {
    local env="$1"
    local timestamp="$2"
    local game_type="$3"
    local param_set="$4"
    local output_dir="outputs/$env"
    local base_filename="piggy_bank_game_${param_set}_${timestamp}"

    # Create environment-specific directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Save env file with game id, parameter store id, and game statistics id
    local env_file="$output_dir/${base_filename}.env"
    > "$env_file"
    echo "export PIGGY_BANK_GAME_ID=\"$GAME_ID\"" >> "$env_file"
    echo "export PIGGY_BANK_PARAM_STORE_ID=\"$PARAM_STORE_ID\"" >> "$env_file"
    echo "export PIGGY_BANK_GAME_STATS_ID=\"$GAME_STATS_ID\"" >> "$env_file"
    print_success "Game environment saved to $env_file"
}

# Function to pretty print the steps payout multipliers
print_steps_payout_table() {
    local steps_bps_csv="$1" # expects like: 10740, 11535, ... OR [10740, ...]

    # Normalize brackets/spaces
    local cleaned
    cleaned=$(echo "$steps_bps_csv" | sed 's/\[//g; s/\]//g; s/ //g')

    IFS=',' read -r -a arr <<< "$cleaned"

    echo "    Tile Multipliers (index: bps -> x):"
    local idx=1
    for bps in "${arr[@]}"; do
        if command -v bc >/dev/null 2>&1; then
            local mult
            mult=$(echo "scale=4; $bps/10000" | bc)
            printf "      %2d: %s bps -> %sx\n" "$idx" "$bps" "$mult"
        else
            printf "      %2d: %s bps\n" "$idx" "$bps"
        fi
        idx=$((idx+1))
    done
}

# Function to show available parameter sets using get_parameter_set
show_parameter_sets() {
    echo ""
    print_status "Available Piggy Bank Parameter Sets:"
    echo ""
    for set_num in 1 2 3; do
        get_parameter_set "$set_num" >/dev/null 2>&1

        local min_stake_sui max_stake_sui success_rate_percent
        if command -v bc >/dev/null 2>&1; then
            min_stake_sui=$(echo "scale=2; $MIN_STAKE/1000000000" | bc)
            max_stake_sui=$(echo "scale=2; $MAX_STAKE/1000000000" | bc)
            success_rate_percent=$(echo "scale=2; $SUCCESS_RATE_BPS/100" | bc)
        else
            min_stake_sui="$MIN_STAKE (raw)"
            max_stake_sui="$MAX_STAKE (raw)"
            success_rate_percent="N/A"
        fi

        echo "------------------------------------------------------------"
        echo "Parameter Set $set_num: $GAME_TYPE - Piggy Bank game"
        echo "    Minimum Stake   : $min_stake_sui SUI"
        echo "    Maximum Stake   : $max_stake_sui SUI"
        echo "    Success Rate    : ${success_rate_percent}% ($SUCCESS_RATE_BPS bps)"
        echo "    Steps Payout bps: $STEPS_PAYOUT_BPS"
        print_steps_payout_table "$STEPS_PAYOUT_BPS"
        echo "------------------------------------------------------------"
        echo ""
    done
}

# Function to get parameter set
get_parameter_set() {
    local set_num="$1"

    case $set_num in
        1)
            MIN_STAKE=10000000
            MAX_STAKE=1000000000
            SUCCESS_RATE_BPS=9000
            STEPS_PAYOUT_BPS="[10740, 11535, 12388, 13305, 14290, 15347, 16483, 17702, 19012, 20419, 21930, 23553, 25296, 27168, 29179, 31338, 33657, 36147, 38822, 41695, 44781, 48094, 51653, 55476, 59581, 63990, 68725, 73811, 79273, 85139, 91439, 98206, 105473, 113278, 121661, 130663, 140333, 150717, 161870, 173849, 186713, 200530, 215369]"
            GAME_TYPE="EASY"
            ;;
        2)
            MIN_STAKE=10000000
            MAX_STAKE=1000000000
            SUCCESS_RATE_BPS=8000
            STEPS_PAYOUT_BPS="[12070, 14568, 17584, 21224, 25617, 30920, 37321, 45046, 54371, 65626, 79210, 95606, 115397, 139284, 168116, 202916, 244920, 295618, 356811, 430671, 519820, 627422, 757299, 914060, 1103270]"
            GAME_TYPE="MEDIUM"
            ;;
        3)
            MIN_STAKE=10000000
            MAX_STAKE=1000000000
            SUCCESS_RATE_BPS=7000
            STEPS_PAYOUT_BPS="[13800, 19044, 26281, 36267, 50049, 69068, 95313, 131532, 181515, 250490, 345677, 477034, 658306, 908463, 1253679]"
            GAME_TYPE="HARD"
            ;;
        *)
            print_error "Invalid parameter set: $set_num"
            show_parameter_sets
            exit 1
            ;;
    esac
}

# Function to load core environment variables from openplay-core repo
load_core_variables() {
    local env="$1"
    local core_repo="https://raw.githubusercontent.com/OpenPlay-Technologies/openplay-core/v1.1"
    local core_env_file="outputs/$env/latest.env"
    local local_core_env="outputs/$env/core_latest.env"
    
    # First, try to load from local file (manual override)
    if [ -f "outputs/$env/latest.env" ]; then
        print_status "Loading core variables from local file..."
        source "outputs/$env/latest.env"
        if [ -n "$CURRENT_OPENPLAY_CORE_PACKAGE_ID" ] && [ -n "$OPENPLAY_CORE_REGISTRY_ID" ]; then
            print_success "Loaded core package environment variables from local file"
            return 0
        fi
    fi
    
    # Second, try to load from local cache if it exists
    if [ -f "$local_core_env" ]; then
        # Check if the cached file is valid (contains export statements)
        if head -1 "$local_core_env" 2>/dev/null | grep -q "^export"; then
            print_status "Loading core variables from local cache..."
            source "$local_core_env"
            if [ -n "$CURRENT_OPENPLAY_CORE_PACKAGE_ID" ] && [ -n "$OPENPLAY_CORE_REGISTRY_ID" ]; then
                print_success "Loaded core package environment variables from local cache"
                return 0
            fi
        else
            # Cache file is corrupted (contains a filename reference), remove it
            print_warning "Cached core file appears to be corrupted, removing it..."
            rm -f "$local_core_env"
        fi
    fi
    
    # Try to fetch from git repo
    print_status "Fetching core variables from openplay-core repository..."
    local temp_file
    temp_file=$(mktemp)
    
    if curl -s -f "$core_repo/$core_env_file" -o "$temp_file" 2>/dev/null; then
        # Check if the file is a symlink/reference (contains just a filename)
        local file_content
        file_content=$(cat "$temp_file" | tr -d '\n\r' | xargs)
        
        # If it looks like a filename reference (no export statements), fetch that file instead
        if [[ ! "$file_content" =~ ^export ]]; then
            # It's a symlink/reference file, get the actual filename
            local actual_file="$file_content"
            print_status "Following symlink to: $actual_file"
            
            # Fetch the actual file
            if curl -s -f "$core_repo/outputs/$env/$actual_file" -o "$temp_file" 2>/dev/null; then
                # Verify it contains export statements
                if [[ "$(head -1 "$temp_file")" =~ ^export ]]; then
                    # Create local cache directory if it doesn't exist
                    mkdir -p "outputs/$env"
                    cp "$temp_file" "$local_core_env"
                    source "$local_core_env"
                    rm -f "$temp_file"
                    
                    if [ -n "$CURRENT_OPENPLAY_CORE_PACKAGE_ID" ] && [ -n "$OPENPLAY_CORE_REGISTRY_ID" ]; then
                        print_success "Loaded core package environment variables from repository"
                        return 0
                    fi
                fi
            fi
        else
            # It's a regular env file with export statements
            # Create local cache directory if it doesn't exist
            mkdir -p "outputs/$env"
            cp "$temp_file" "$local_core_env"
            source "$local_core_env"
            rm -f "$temp_file"
            
            if [ -n "$CURRENT_OPENPLAY_CORE_PACKAGE_ID" ] && [ -n "$OPENPLAY_CORE_REGISTRY_ID" ]; then
                print_success "Loaded core package environment variables from repository"
                return 0
            fi
        fi
    fi
    
    rm -f "$temp_file"
    print_error "Failed to load core variables. Please ensure openplay-core is deployed and the outputs are available."
    print_error "You can manually create outputs/$env/latest.env with the core variables, or ensure the repo has outputs/$env/latest.env available."
    return 1
}

# Check if we're in the right directory
if [ ! -f "package/Move.toml" ]; then
    print_error "This script must be run from the piggy-bank-contracts root directory"
    exit 1
fi

# Check if sui client is available
if ! command -v sui &> /dev/null; then
    print_error "sui client is not available. Please ensure Sui is installed and in your PATH."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Please install jq first."
    exit 1
fi

# Get active environment and timestamp
ACTIVE_ENV=$(get_active_env)
TIMESTAMP=$(get_timestamp)

print_status "Active environment: $ACTIVE_ENV"
print_status "Creation timestamp: $TIMESTAMP"

# Load core environment variables from openplay-core repo
if ! load_core_variables "$ACTIVE_ENV"; then
    print_error "Failed to load core package environment variables"
    exit 1
fi

# Load piggy bank environment variables
if [ -f "outputs/$ACTIVE_ENV/latest_piggy_bank.env" ]; then
    # shellcheck disable=SC1090
    source "outputs/$ACTIVE_ENV/latest_piggy_bank.env"
    print_success "Loaded piggy bank package environment variables"
else
    print_error "Piggy bank package not deployed. Run ./scripts/deploy-package.sh first."
    exit 1
fi

# Check if package variables are loaded
if [ -z "$CURRENT_PIGGY_BANK_PACKAGE_ID" ] || [ -z "$PIGGY_BANK_CAP" ] || [ -z "$CURRENT_OPENPLAY_CORE_PACKAGE_ID" ] || [ -z "$OPENPLAY_CORE_REGISTRY_ID" ]; then
    print_error "Required package variables not loaded. Ensure both core and piggy bank packages are deployed."
    exit 1
fi

# Set package variables for convenience (use CURRENT_* to always use latest version)
CORE_PACKAGE_ID="$CURRENT_OPENPLAY_CORE_PACKAGE_ID"
PIGGY_BANK_PACKAGE_ID="$CURRENT_PIGGY_BANK_PACKAGE_ID"
REGISTRY_ID="$OPENPLAY_CORE_REGISTRY_ID"

# Initialize debug flag
DEBUG_MODE=false

# Handle command line arguments
if [ $# -eq 0 ]; then
    show_parameter_sets
    echo ""
    print_status "Usage: $0 <parameter_set_number> [--debug]"
    print_status "Example: $0 2"
    print_status "         $0 2 --debug"
    exit 1
fi

# Parse arguments
PARAM_SET=""
for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG_MODE=true
            print_status "Debug mode enabled"
            ;;
        *)
            if [ -z "$PARAM_SET" ]; then
                PARAM_SET="$arg"
            fi
            ;;
    esac
done

# Check if parameter set was provided
if [ -z "$PARAM_SET" ]; then
    print_error "Parameter set number is required"
    exit 1
fi

# Get parameter set
get_parameter_set "$PARAM_SET"

print_status "Creating piggy bank game with parameter set $PARAM_SET ($GAME_TYPE)"
print_status "Parameters: Min Stake=$MIN_STAKE, Max Stake=$MAX_STAKE, Success Rate=${SUCCESS_RATE_BPS}bps"

# Create the game
print_status "Creating game instance..."
GAME_OUTPUT=$(sui client ptb \
    --move-call sui::tx_context::sender \
    --assign sender \
    --assign min_stake $MIN_STAKE \
    --assign max_stake $MAX_STAKE \
    --assign success_rate_bps $SUCCESS_RATE_BPS \
    --make-move-vec "<u64>" "$STEPS_PAYOUT_BPS" \
    --assign steps_payout_bps \
    --move-call $PIGGY_BANK_PACKAGE_ID::game::admin_create @$PIGGY_BANK_CAP @$REGISTRY_ID min_stake max_stake success_rate_bps steps_payout_bps \
    --assign createGameOutput \
    --move-call $PIGGY_BANK_PACKAGE_ID::game::share createGameOutput.0 \
    --move-call $CORE_PACKAGE_ID::parameter_store::freeze_ createGameOutput.1 \
    --move-call $CORE_PACKAGE_ID::game_stats::share createGameOutput.2 \
    --json)

# Debug output if requested
if [ "$DEBUG_MODE" = true ]; then
    echo ""
    print_status "Debug: Full JSON output from game creation:"
    echo "$GAME_OUTPUT" | jq '.'
    echo ""
fi

# Check if game creation was successful
if echo "$GAME_OUTPUT" | jq -e '.effects.status.status == "success"' > /dev/null; then
    print_success "Game created successfully!"
else
    print_error "Game creation failed!"
    echo "$GAME_OUTPUT" | jq '.effects.status'
    exit 1
fi

# Extract game ID
GAME_ID=$(echo "$GAME_OUTPUT" | jq -r '.objectChanges[] | select(.type == "created" and (.objectType | contains("::game::Game"))) | .objectId')

if [ -z "$GAME_ID" ] || [ "$GAME_ID" = "null" ]; then
    print_error "Failed to extract game ID"
    exit 1
fi

# Extract parameter store ID
PARAM_STORE_ID=$(echo "$GAME_OUTPUT" | jq -r '.objectChanges[] | select(.type == "created" and (.objectType | contains("::parameter_store::ParameterStore"))) | .objectId')

if [ -z "$PARAM_STORE_ID" ] || [ "$PARAM_STORE_ID" = "null" ]; then
    print_error "Failed to extract parameter store ID"
    exit 1
fi

# Extract game statistics ID
GAME_STATS_ID=$(echo "$GAME_OUTPUT" | jq -r '.objectChanges[] | select(.type == "created" and (.objectType | contains("::game_stats::GameStatistics"))) | .objectId')

if [ -z "$GAME_STATS_ID" ] || [ "$GAME_STATS_ID" = "null" ]; then
    print_error "Failed to extract game statistics ID"
    exit 1
fi

# Save outputs to files
save_game_output "$ACTIVE_ENV" "$TIMESTAMP" "$GAME_TYPE" "$PARAM_SET"

# Print summary
echo ""
print_success "Piggy Bank game creation completed successfully!"
echo ""
print_status "Game Summary:"
echo "  Game ID: $GAME_ID"
echo "  Parameter Store ID: $PARAM_STORE_ID"
echo "  Game Statistics ID: $GAME_STATS_ID"
echo "  Parameter Set: $PARAM_SET ($GAME_TYPE)"
echo "  Min Stake: $MIN_STAKE"
echo "  Max Stake: $MAX_STAKE"
echo "  Success Rate: ${SUCCESS_RATE_BPS} bps"
echo "  Steps Payout bps: $STEPS_PAYOUT_BPS"
echo "  Tile Multipliers:"
print_steps_payout_table "$STEPS_PAYOUT_BPS"
echo ""


