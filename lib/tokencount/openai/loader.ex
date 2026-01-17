defmodule TokenCount.OpenAI.Loader do
  @moduledoc """
  Loads OpenAI .tiktoken rank files from blob storage or local cache.

  Handles downloading, caching, and parsing base64-encoded rank files.
  """

  @base_url "https://openaipublic.blob.core.windows.net/encodings"

  @doc """
  Load a tiktoken rank file by name (e.g., "cl100k_base").

  Returns `{:ok, mergeable_ranks}` where mergeable_ranks is a map of `binary() => integer()`.
  """
  @spec load_ranks(String.t()) :: {:ok, %{binary() => non_neg_integer()}} | {:error, term()}
  def load_ranks(encoding_name) when is_binary(encoding_name) do
    filename = "#{encoding_name}.tiktoken"
    url = "#{@base_url}/#{filename}"

    with {:ok, cache_path} <- cache_path(filename),
         {:ok, content} <- fetch_or_read_cache(url, cache_path) do
      parse_tiktoken_file(content)
    end
  end

  defp fetch_or_read_cache(url, cache_path) do
    if File.exists?(cache_path) do
      File.read(cache_path)
    else
      with {:ok, content} <- fetch_http(url),
           :ok <- write_cache(cache_path, content) do
        {:ok, content}
      end
    end
  end

  defp fetch_http(url) do
    url_charlist = String.to_charlist(url)
    headers = [{~c"user-agent", ~c"tokencount-elixir/0.1.0"}]

    http_options = [
      timeout: 120_000,
      connect_timeout: 30_000,
      autoredirect: true,
      ssl: ssl_options()
    ]

    request_options = [body_format: :binary]

    case :httpc.request(:get, {url_charlist, headers}, http_options, request_options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, body}

      {:ok, {{_, status, _}, _headers, _body}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  defp ssl_options do
    base_opts = [
      verify: :verify_peer,
      depth: 3,
      cacerts: cacerts()
    ]

    maybe_add_hostname_check(base_opts)
  end

  defp cacerts do
    if Code.ensure_loaded?(:public_key) and function_exported?(:public_key, :cacerts_get, 0) do
      apply(:public_key, :cacerts_get, [])
    else
      []
    end
  rescue
    _ -> []
  end

  defp maybe_add_hostname_check(opts) do
    if Code.ensure_loaded?(:public_key) and
         function_exported?(:public_key, :pkix_verify_hostname_match_fun, 1) do
      match_fun = apply(:public_key, :pkix_verify_hostname_match_fun, [:https])
      Keyword.put(opts, :customize_hostname_check, match_fun: match_fun)
    else
      opts
    end
  end

  defp cache_path(filename) do
    cache_dir = cache_dir()

    with :ok <- File.mkdir_p(cache_dir) do
      {:ok, Path.join(cache_dir, filename)}
    end
  end

  defp cache_dir do
    case System.get_env("TOKENCOUNT_CACHE_DIR") do
      nil ->
        :filename.basedir(:user_cache, "tokencount")

      dir ->
        dir
    end
  end

  defp write_cache(path, content) do
    File.write(path, content)
  end

  @doc """
  Parse a .tiktoken file content into a rank map.

  Format: each line is "base64_token rank_number"
  """
  def parse_tiktoken_file(content) when is_binary(content) do
    ranks =
      content
      |> String.split("\n", trim: true)
      |> Enum.reduce(%{}, fn line, acc ->
        case String.split(line, " ", parts: 2) do
          [b64_token, rank_str] ->
            with {:ok, token_bytes} <- Base.decode64(b64_token),
                 {rank, ""} <- Integer.parse(rank_str) do
              Map.put(acc, token_bytes, rank)
            else
              _ -> acc
            end

          _ ->
            acc
        end
      end)

    {:ok, ranks}
  rescue
    e -> {:error, {:parse_error, Exception.message(e)}}
  end
end
