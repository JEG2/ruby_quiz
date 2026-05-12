root_dir = Path.expand("..", __DIR__)
raw_dir = Path.join(root_dir, "raw")
final_dir = Path.join(root_dir, "final")

raw_dir
|> Path.join("**/*.html")
|> Path.wildcard()
|> Enum.each(fn from ->
  to =
    from
    |> Path.relative_to(raw_dir)
    |> then(&Path.join(final_dir, &1))

  to
  |> Path.dirname()
  |> File.mkdir_p!()

  html =
    from
    |> File.read!()
    |> String.replace(~r{<div[^>]+widget_search">.+?\s</div>}s, "")
    |> String.replace(~r{<div[^>]+comment-form-wrapper">.+?</form>\s+</div>\s+</div>}s, "")
    |> String.replace(~r{<span\sclass="c_reply"><a href="#">Reply</a></span>}, "")
    |> String.replace(~r{<li\s+class="reply-form">.+?</li>}s, "")
    |> String.replace(~r{href="([^"]+)"}, fn "href=\"" <> path ->
      edited =
        path
        |> String.slice(0..-2//1)
        |> String.replace(~r{\A[^?]*\?page=\d+\z}, fn p ->
          case String.split(p, "?") do
            [path, "page=1"] ->
              path

            [path, "page=" <> page] ->
              String.replace(path, ~r{/\z}, "") <> "/p#{page}"
          end
        end)

      edited =
        if String.starts_with?(edited, "mailto:") or
             String.contains?(edited, [".", "#", "?"]) or
             String.ends_with?(edited, "/") do
          edited
        else
          "#{edited}/"
        end

      "href=\"#{edited}\""
    end)

  File.write!(to, html)
end)
