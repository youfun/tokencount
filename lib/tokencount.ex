defmodule TokenCount do
  @moduledoc """
  Pure Elixir BPE tokenizer for OpenAI models.

  This library provides tiktoken-compatible tokenization without Rust/NIF dependencies.

  ## Basic Usage

      # Get encoding and count tokens
      {:ok, encoding} = TokenCount.get_encoding("cl100k_base")
      {:ok, tokens} = TokenCount.encode(encoding, "Hello world")
      {:ok, count} = TokenCount.count_tokens("gpt-4", "Hello world")
  """

  alias TokenCount.Core.Encoding
  alias TokenCount.OpenAI.Loader
  alias TokenCount.OpenAI.Params

  @doc """
  Get an encoding by name (cl100k_base, p50k_base, r50k_base, o200k_base).
  """
  @spec get_encoding(String.t()) :: {:ok, Encoding.t()} | {:error, term()}
  def get_encoding(name) do
    with {:ok, params} <- Params.get(name),
         {:ok, ranks} <- Loader.load_ranks(name) do
      Encoding.new(
        pat_str: Keyword.fetch!(params, :pat_str),
        mergeable_ranks: ranks,
        special_tokens: Keyword.get(params, :special_tokens, %{})
      )
    end
  end

  @doc """
  Get the encoding for a specific OpenAI model.
  """
  @spec encoding_for_model(String.t()) :: {:ok, Encoding.t()} | {:error, term()}
  def encoding_for_model(model) when is_binary(model) do
    case Params.model_to_encoding(model) do
      nil -> {:error, {:unknown_model, model}}
      encoding_name -> get_encoding(encoding_name)
    end
  end

  @doc """
  Encode text into token IDs.
  """
  @spec encode(Encoding.t(), String.t(), keyword()) ::
          {:ok, [non_neg_integer()]} | {:error, term()}
  def encode(%Encoding{} = encoding, text, opts \\ []) do
    Encoding.encode(encoding, text, opts)
  end

  @doc """
  Decode token IDs back into text.
  """
  @spec decode(Encoding.t(), [non_neg_integer()]) :: {:ok, String.t()} | {:error, term()}
  def decode(%Encoding{} = encoding, tokens) do
    Encoding.decode(encoding, tokens)
  end

  @doc """
  Count tokens for a given model and text.
  """
  @spec count_tokens(String.t(), String.t(), keyword()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def count_tokens(model, text, opts \\ []) do
    with {:ok, encoding} <- encoding_for_model(model),
         {:ok, tokens} <- encode(encoding, text, opts) do
      {:ok, length(tokens)}
    end
  end
end
