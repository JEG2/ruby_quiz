Mix.install([
  {:req, "~> 0.5.15"}
])

root_dir = Path.expand("..", __DIR__)
assets_dir = Path.join(root_dir, "raw/assets")
File.mkdir_p!(assets_dir)

images_dir = Path.join(root_dir, "../ink/app/assets/images")

[
  "favicon.ico",
  "logo.png",
  "projects/code_reading_equalizer_and_concord.png",
  "projects/emacs_video.png",
  "projects/ruby_quiz.png",
  "projects/ruby_quiz_study_group.png",
  "social-icons/rss.png",
  "social-icons/twitter.png"
]
|> Enum.each(fn path ->
  from = Path.join(images_dir, path)
  to = Path.join(assets_dir, Path.basename(path))
  File.cp!(from, to)
end)

assets_url = "http://graysoftinc.com/assets"

[
  "application-cc1b6decf7f067ecd750d7a042a701c4.css",
  "application-52055d2f84f85ee9312223f80caadfc1.js"
]
|> Enum.each(fn file ->
  content = Req.get!("#{assets_url}/#{file}").body

  File.write!(
    Path.join(assets_dir, String.replace(file, ~r{-\w+}, "")),
    content
  )
end)
