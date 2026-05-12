Mix.install([
  {:req, "~> 0.5.15"}
])

defmodule Blog do
  @base_url "http://graysoftinc.com/"
  @raw_dir Path.expand("../raw", __DIR__)
  @footer File.read!(Path.expand("../data/footer.html", __DIR__))

  def fetch_all_pages do
    MapSet.new([{"/", "index.html"}])
    |> Stream.iterate(fn queue ->
      Process.sleep(1_000)

      {web_path, file_path} =
        page =
        Enum.find(queue, fn {_web_path, file_path} ->
          String.ends_with?(file_path, ".html")
        end)

      new_urls = fetch_page(web_path, file_path)

      queue
      |> MapSet.union(new_urls)
      |> MapSet.delete(page)
    end)
    |> Enum.find(fn queue ->
      Enum.all?(queue, fn {_web_path, file_path} ->
        not String.ends_with?(file_path, ".html")
      end)
    end)
  end

  def fetch_page(web_path, file_path) do
    IO.puts("Downloading #{file_path}…")

    page = Req.get!("#{@base_url}#{web_path}").body
    html = clean_html(page)

    path = Path.join(@raw_dir, file_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, html)

    find_linked_urls(html)
  end

  def clean_html(html) do
    html
    |> String.replace(~r{/favicon-\w+\.ico}, "/favicon.ico")
    |> String.replace(
      "The programming blog of James Edward Gray II",
      "The Ruby programming blog of James Edward Gray II"
    )
    |> String.replace(~r{/application-\w+\.(css|js)}, "/application.\\1")
    |> String.replace(~r{^[ ]*<meta .+\bname="csrf-(param|token)" />\n}m, "")
    |> String.replace(
      "http://rubyrogues.com/\">The Ruby Rogues Podcast",
      "https://programmersstone.blog/\">My Elixir Blog"
    )
    |> String.replace(~r{/logo-\w+\.png}, "/logo.png")
    |> String.replace(~r{^[ ]*<li><a class="login_link".+?</ul>\s+</li>\n}ms, "")
    |> String.replace(~r{^[ ]*<footer>.+}ms, @footer)
  end

  def find_linked_urls(html) do
    Regex.scan(~r{(?:href|src)="([^"]+)"}, html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(fn url ->
      url
      |> String.replace(~r{\Ahttps?://graysoftinc\.com}, "")
      |> String.replace(~r{#comments\z}, "")
    end)
    |> Enum.filter(&String.starts_with?(&1, "/"))
    |> Enum.uniq()
    |> Enum.map(fn path -> {path, to_file_name(path)} end)
    |> Enum.reject(fn {web_path, file_path} ->
      String.match?(web_path, ~r{#comment_\d+\z}) ||
        File.exists?(Path.join(@raw_dir, file_path))
    end)
    |> MapSet.new()
  end

  def to_file_name("/" <> path) do
    path = URI.decode(path)

    path =
      case Regex.named_captures(~r{\A(?<path>.*)\?page=(?<page>\d+)\z}, path) do
        %{"path" => path, "page" => "1"} -> path
        %{"path" => path, "page" => page} -> "#{path}/p#{page}"
        nil -> path
      end

    if not String.contains?(path, ".") do
      Path.join(path, "index.html")
    else
      path
    end
  end
end

Blog.fetch_all_pages()
|> IO.inspect()
