defmodule TokencountTest do
  use ExUnit.Case
  doctest TokenCount

  @tag timeout: 120_000
  test "end-to-end encoding and decoding for cl100k_base (gpt-4)" do
    # This might trigger a download
    assert {:ok, encoding} = TokenCount.encoding_for_model("gpt-4")

    text = "Hello world"
    assert {:ok, tokens} = TokenCount.encode(encoding, text)
    # Expected tokens for "Hello world" in cl100k_base: [9906, 1917]
    assert tokens == [9906, 1917]

    assert {:ok, decoded} = TokenCount.decode(encoding, tokens)
    assert decoded == text

    assert {:ok, count} = TokenCount.count_tokens("gpt-4", text)
    assert count == 2
  end

  @tag timeout: 120_000
  test "handling special tokens" do
    assert {:ok, _encoding} = TokenCount.encoding_for_model("gpt-4")
    # By default, special tokens raise error if not allowed
    # <|endoftext|> is 100257 in cl100k_base

    _text = "Hello <|endoftext|>"
    # TODO: Implement special token handling tests once special tokens are populated in params
  end
end
