#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HADRIAN_SRC="${HADRIAN_SRC:-$HOME/src/hadrian/hadrian}"
MOCKER_PORT="${MOCKER_PORT:-8000}"
HADRIAN_PORT="${HADRIAN_PORT:-8081}"
RATE="${RATE:-1000}"
DURATION="${DURATION:-30}"
OUTPUT="${OUTPUT:-results.json}"

cleanup() {
    echo "Cleaning up..."
    kill "$MOCKER_PID" "$HADRIAN_PID" 2>/dev/null || true
    wait "$MOCKER_PID" "$HADRIAN_PID" 2>/dev/null || true
}
trap cleanup EXIT

# 1. Build Hadrian (tiny profile, release)
echo "Building Hadrian..."
(cd "$HADRIAN_SRC" && cargo build --release --no-default-features --features tiny)

# 2. Start mocker
echo "Starting mocker on port $MOCKER_PORT..."
(cd "$SCRIPT_DIR/mocker" && go run main.go -host 0.0.0.0 -port "$MOCKER_PORT") &
MOCKER_PID=$!
sleep 2

# 3. Start Hadrian
echo "Starting Hadrian on port $HADRIAN_PORT..."
RUST_LOG=warn "$HADRIAN_SRC/target/release/hadrian" --config "$SCRIPT_DIR/hadrian-bench.toml" --no-browser &
HADRIAN_PID=$!
sleep 2

# 4. Health checks
curl -sf "http://localhost:$MOCKER_PORT/health" > /dev/null || { echo "Mocker not healthy"; exit 1; }
curl -sf "http://localhost:$HADRIAN_PORT/health" > /dev/null || { echo "Hadrian not healthy"; exit 1; }
echo "Both services healthy."

# 5. Run benchmark
echo "Running benchmark (rate=$RATE, duration=${DURATION}s)..."
(cd "$SCRIPT_DIR" && go run benchmark.go \
    --provider hadrian \
    --rate "$RATE" \
    --duration "$DURATION" \
    --host localhost \
    --output "$OUTPUT")

echo "Done. Results in $OUTPUT"
