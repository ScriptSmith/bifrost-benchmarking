# AI Gateway Benchmark Suite

A high-performance load testing tool for benchmarking AI gateways (Bifrost, Hadrian, LiteLLM, Portkey, Helicone) using a mock LLM server to measure pure proxy overhead.

Forked from [maximhq/bifrost-benchmarking](https://github.com/maximhq/bifrost-benchmarking).

## Features

- 🚀 Configurable requests per second (RPS)
- ⏱️ Customizable test duration
- 🔄 Streaming and non-streaming support
- 🎯 Multiple models and providers
- 📊 Real-time statistics
- 🔑 Virtual key authentication
- 📈 Success rate tracking

## Installation

### Build from source

```bash
cd /path/to/bifrost-enterprise/cmd/hitter
go build -o hitter main.go
```

### Or run directly

```bash
go run main.go [flags]
```

## Usage

### Basic Example

```bash
./hitter --rps 100 --duration 60s
```

### With Custom Models and Providers

```bash
./hitter \
  --models "gpt-4o,gpt-4o-mini,claude-3-opus" \
  --providers "openai,anthropic" \
  --rps 50 \
  --duration 120s
```

### With Streaming

```bash
./hitter \
  --stream \
  --models "gpt-4o,gpt-5.2" \
  --rps 100 \
  --duration 60s \
  --virtual-key sk-bf-xxxxx
```

## Benchmarking Hadrian

### Quick Start

```bash
./run-hadrian-bench.sh
```

This builds Hadrian with the `tiny` feature profile (minimal binary, OpenAI provider only), starts the mocker and Hadrian, runs the benchmark, and cleans up.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HADRIAN_SRC` | `~/src/hadrian/hadrian` | Path to Hadrian source |
| `HADRIAN_PORT` | `8081` | Port for Hadrian |
| `MOCKER_PORT` | `8000` | Port for the mock LLM server |
| `RATE` | `1000` | Requests per second |
| `DURATION` | `30` | Test duration in seconds |
| `OUTPUT` | `results.json` | Output file |

### Manual Setup

```bash
# 1. Build Hadrian
cd ~/src/hadrian/hadrian
cargo build --release --no-default-features --features tiny

# 2. Start mocker
cd mocker && go run main.go -host 0.0.0.0 -port 8000

# 3. Start Hadrian
RUST_LOG=warn ./target/release/hadrian --config hadrian-bench.toml --no-browser

# 4. Run benchmark
go run benchmark.go --provider hadrian --rate 1000 --duration 30
```

## Command-Line Flags

| Flag            | Type     | Default                                     | Description                                  |
| --------------- | -------- | ------------------------------------------- | -------------------------------------------- |
| `--url`         | string   | `http://localhost:8080/v1/chat/completions` | Target API endpoint                          |
| `--rps`         | int      | `100`                                       | Requests per second                          |
| `--duration`    | duration | `60s`                                       | Test duration (e.g., 30s, 5m, 1h)            |
| `--models`      | string   | `gpt-4,gpt-4o,gpt-4o-mini,gpt-4.1,gpt-5`    | Comma-separated list of models to test       |
| `--providers`   | string   | `""`                                        | Comma-separated list of providers (optional) |
| `--max-tokens`  | int      | `150`                                       | Maximum tokens per request                   |
| `--temperature` | float    | `0.7`                                       | Temperature for model responses              |
| `--stream`      | bool     | `false`                                     | Enable streaming responses                   |
| `--verbose`     | bool     | `false`                                     | Enable verbose logging                       |
| `--virtual-key` | string   | `""`                                        | Virtual API key for authentication           |

## Examples

### 1. High-Load Test

Test with 500 requests per second for 5 minutes:

```bash
./hitter --rps 500 --duration 5m --verbose
```

### 2. Multiple Models Test

Test different models simultaneously:

```bash
./hitter \
  --models "gpt-4o,gpt-4o-mini,gpt-5.2,claude-3-opus" \
  --rps 200 \
  --duration 180s
```

### 3. Provider-Specific Test

Test with specific providers:

```bash
./hitter \
  --models "gpt-4o,claude-3-opus" \
  --providers "openai,anthropic" \
  --rps 100 \
  --duration 120s
```

### 4. Streaming Test with Authentication

```bash
./hitter \
  --stream \
  --models "gpt-4o-mini" \
  --providers "openai" \
  --rps 50 \
  --duration 60s \
  --virtual-key sk-bf-your-key-here \
  --verbose
```

### 5. Custom Endpoint Test

```bash
./hitter \
  --url "https://api.example.com/v1/chat/completions" \
  --models "gpt-4o" \
  --rps 100 \
  --duration 30s \
  --virtual-key sk-bf-your-key-here
```

## Important Notes

### ⚠️ Flag Syntax Rules

**Boolean Flags:**

- ✅ Correct: `--stream` or `--stream=true`
- ❌ Wrong: `--stream true` (will break subsequent flags)

**Comma-Separated Values:**

- ✅ Correct: `--models "gpt-4o,gpt-5.2,claude-3"` (quoted with spaces)
- ✅ Correct: `--models gpt-4o,gpt-5.2,claude-3` (no spaces)
- ❌ Wrong: `--models gpt-4o, gpt-5.2, claude-3` (spaces without quotes)

**Duration Format:**

- Valid: `30s`, `5m`, `1h`, `90s`, `2h30m`
- Examples: `--duration 30s`, `--duration 5m`, `--duration 1h30m`

### Test Behavior

- **Random Selection**: For each request, a random model, provider, and prompt are selected from the configured options
- **Token Variation**: Max tokens vary by ±25 tokens from the configured value
- **Temperature Variation**: Temperature varies by ±0.1 from the configured value
- **Graceful Shutdown**: Press `Ctrl+C` to stop the test early and see final statistics

### Model/Provider Format

When providers are specified, requests will use the format: `provider/model`

Example:

```bash
--models "gpt-4o,gpt-5.2" --providers "openai,anthropic"
```

Will generate requests like:

- `openai/gpt-4o`
- `openai/gpt-5.2`
- `anthropic/gpt-4o`
- `anthropic/gpt-5.2`

## Output

### Real-time Statistics (every 10 seconds)

```
📈 [10s] Requests: 1000 | Success: 98.5% | RPS: 100.0
📈 [20s] Requests: 2000 | Success: 98.7% | RPS: 100.0
```

### Final Statistics

```
📋 FINAL STATISTICS
   Duration: 60.123s
   Total Requests: 6012
   Successful: 5934 (98.7%)
   Errors: 78
   Average RPS: 100.0
```

## Test Prompts

The tool uses a variety of prompts including:

- Technical explanations (quantum computing, machine learning, neural networks)
- Creative writing (short stories, poems)
- Educational content (photosynthesis, climate change)
- Technical processes (blockchain, GPS systems)

## Troubleshooting

### No Requests Being Sent

**Check:**

- Is the URL correct and reachable?
- Is the server running on the specified port?
- Are you using the correct virtual key?

```bash
# Test with verbose logging
./hitter --verbose --rps 1 --duration 10s
```

### All Requests Failing

**Common causes:**

- Invalid virtual key
- Server not running
- Wrong endpoint URL
- Network issues

**Debug:**

```bash
./hitter --verbose --rps 1 --duration 10s --virtual-key your-key
```

### Flags Not Being Recognized

**Check:**

- Are boolean flags formatted correctly? (use `--stream` not `--stream true`)
- Are comma-separated values quoted if they contain spaces?
- Are you using double dashes `--` for long flags?

## Performance Tips

1. **Start Small**: Begin with low RPS (10-50) and gradually increase
2. **Use Streaming**: Streaming tests better simulate real-world usage
3. **Monitor Server**: Watch server metrics during load tests
4. **Timeout Settings**: Default HTTP timeout is 30 seconds
5. **System Resources**: Ensure your system can handle the target RPS

## Contributing

When modifying the tool:

- Update this README with new flags or features
- Test with various RPS and duration combinations
- Ensure graceful shutdown works correctly
- Add appropriate error handling

## License

Part of the Bifrost Enterprise project.
