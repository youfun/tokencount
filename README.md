# TokenCount

**TokenCount** is a pure Elixir implementation of a BPE (Byte Pair Encoding) tokenizer, designed to be a 1:1 functional replacement for OpenAI's `tiktoken`, but without any Rust or NIF dependencies.

## Key Features

-   **Zero Dependencies**: No Rust toolchain, no C compiler, no NIFs. Highly portable and safe.
-   **OpenAI Compatible**: Supports `cl100k_base` (GPT-4, GPT-3.5), `o200k_base` (GPT-4o), `p50k_base`, and `r50k_base`.
-   **Automatic Loading**: Automatically downloads and caches `.tiktoken` rank files from OpenAI's public storage.
-   **High Performance**: Optimized using Erlang's `:gb_sets` for BPE merging, achieving ~3MB/s throughput on standard hardware.
-   **Special Token Support**: Full support for special tokens like `<|endoftext|>`, `<|fim_prefix|>`, etc.

## Installation

Add `tokencount` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tokencount, path: "path/to/tokencount"} # While in development
    # {:tokencount, "~> 0.1.0"} # Future hex release
  ]
end
```

## Quick Start

### Basic Usage

```elixir
# Count tokens for a specific model
{:ok, count} = TokenCount.count_tokens("gpt-4", "Hello world!")
# => {:ok, 3}

# Get encoding and encode text
{:ok, encoding} = TokenCount.encoding_for_model("gpt-4")
{:ok, tokens} = TokenCount.encode(encoding, "Hello world!")
# => {:ok, [9906, 1917, 0]}

# Decode tokens back to text
{:ok, text} = TokenCount.decode(encoding, [9906, 1917, 0])
# => {:ok, "Hello world!"}
```

### Handling Special Tokens

By default, `TokenCount.encode/3` allows parsing of special tokens if they exist in the input string.

```elixir
{:ok, encoding} = TokenCount.encoding_for_model("gpt-4")
{:ok, tokens} = TokenCount.encode(encoding, "Hello <|endoftext|>", allow_special_tokens: true)
# => {:ok, [9906, 220, 100257]}
```

## Performance

TokenCount is optimized for the BEAM. While it cannot match the raw speed of the highly optimized Rust-based `tiktoken`, it is more than fast enough for most Elixir applications (LLM prompts, document indexing, etc.).

**Benchmark results (Example):**
- **Short text** (~50 chars): ~40,000 iterations/sec (0.02 ms/op)
- **Long text** (~4 KB): ~800 iterations/sec (1.2 ms/op)

To run the benchmark yourself:
```bash
elixir usage_script.exs
```

## How it Works

1. **Regex Splitting**: Uses Erlang's `re` module (PCRE) to split text into manageable chunks based on OpenAI's official patterns.
2. **BPE Merging**: Implements the Byte Pair Encoding algorithm. For efficiency, it uses a naive recursive approach for small chunks and a min-heap (via `:gb_sets`) for larger chunks.
3. **Caching**: Fetches `.tiktoken` files once and stores them in the user cache directory (e.g., `~/.cache/tokencount`).

## Comparison with Tiktoken-Elixir

| Feature | tiktoken-elixir | **TokenCount** |
| :--- | :--- | :--- |
| **Implementation** | Rust NIF | **Pure Elixir** |
| **Risk** | Can crash VM on panic | **Safe (Isolated process)** |
| **Dependencies** | Rust + Cargo required | **None** |
| **Speed** | Extremely Fast | Fast (BEAM Optimized) |
| **Deployment** | Requires compilation | **Cross-platform (Bytecode)** |

## License

MIT