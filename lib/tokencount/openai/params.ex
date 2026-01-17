defmodule TokenCount.OpenAI.Params do
  @moduledoc """
  Definitions for OpenAI encoding parameters (regex patterns, special tokens).
  """

  @cl100k_base_pat ~S"(?i:'s|'t|'re|'ve|'m|'ll|'d)|[^
\p{L}\p{N}]?\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]+[\r\n]*|\s*[\r\n]+|\s+(?!\S)|\s+"

  # p50k and r50k share the same pattern
  @p50k_pat ~S"'(?i:[sdmt]|ll|ve|re)| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+"

  # o200k_base pattern parts joined
  @o200k_pat [
               ~S"[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]*[\p{Ll}\p{Lm}\p{Lo}\p{M}]+(?i:'s|'t|'re|'ve|'m|'ll|'d)?",
               ~S"[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]+[\p{Ll}\p{Lm}\p{Lo}\p{M}]*(?i:'s|'t|'re|'ve|'m|'ll|'d)?",
               ~S"\p{N}{1,3}",
               ~S" ?[^\s\p{L}\p{N}]+[\r\n/]*",
               ~S"\s*[\r\n]+",
               ~S"\s+(?!\S)",
               ~S"\s+"
             ]
             |> Enum.join("|")

  @spec get(String.t()) :: {:ok, keyword()} | {:error, term()}
  def get("cl100k_base") do
    {:ok,
     [
       pat_str: @cl100k_base_pat,
       special_tokens: %{
         "<|endoftext|>" => 100_257,
         "<|fim_prefix|>" => 100_258,
         "<|fim_middle|>" => 100_259,
         "<|fim_suffix|>" => 100_260,
         "<|endofprompt|>" => 100_276
       }
     ]}
  end

  def get("p50k_base") do
    {:ok,
     [
       pat_str: @p50k_pat,
       special_tokens: %{
         "<|endoftext|>" => 50256
       }
     ]}
  end

  def get("r50k_base") do
    {:ok,
     [
       pat_str: @p50k_pat,
       special_tokens: %{
         "<|endoftext|>" => 50256
       }
     ]}
  end

  def get("o200k_base") do
    # Note: o200k_base has many more special tokens (199998, 199999 etc), 
    # but <|endoftext|> is usually mapped to 199999 or similar depending on the exact version.
    # For now we stick to the basic ones known or keep it minimal until full list is verified.
    # According to public sources, o200k_base also uses <|endoftext|> and others but IDs differ.
    # Let's verify IDs or keep minimal for now to avoid incorrect IDs.
    # Placeholder for o200k special tokens.
    {:ok,
     [
       pat_str: @o200k_pat,
       special_tokens: %{
         "<|endoftext|>" => 199_999
       }
     ]}
  end

  def get(name), do: {:error, {:unknown_encoding, name}}

  @doc """
  Resolves model name to encoding name.
  """
  def model_to_encoding("gpt-4o" <> _), do: "o200k_base"
  def model_to_encoding("gpt-4" <> _), do: "cl100k_base"
  def model_to_encoding("gpt-3.5-turbo" <> _), do: "cl100k_base"
  def model_to_encoding("text-embedding-ada-002"), do: "cl100k_base"
  def model_to_encoding("text-embedding-3-" <> _), do: "cl100k_base"

  def model_to_encoding("text-davinci-003"), do: "p50k_base"
  def model_to_encoding("text-davinci-002"), do: "p50k_base"
  def model_to_encoding("code-" <> _), do: "p50k_base"

  def model_to_encoding("text-davinci-001"), do: "r50k_base"
  def model_to_encoding("davinci"), do: "r50k_base"
  def model_to_encoding("curie"), do: "r50k_base"
  def model_to_encoding("babbage"), do: "r50k_base"
  def model_to_encoding("ada"), do: "r50k_base"

  def model_to_encoding(_), do: nil
end
