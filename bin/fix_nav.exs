defmodule Nav do
  @root_dir Path.expand("..", __DIR__)
  @raw_dir Path.join(@root_dir, "raw")
  @assets_dir Path.join(@raw_dir, "assets")
  @data_dir Path.join(@root_dir, "data")

  def fix do
    js = Path.join(@assets_dir, "application.js")
    body = File.read!(js)
    header = File.read!(Path.join(@data_dir, "header.js"))
    File.write!(js, header <> body)
  end
end

Nav.fix()
|> IO.inspect()
