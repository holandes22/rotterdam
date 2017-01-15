defmodule Rotterdam.PageView do
  use Rotterdam.Web, :view

  alias Poison.Parser


  def stats do
    case Application.get_env(:rotterdam, :environment, :dev) do
      :prod ->
        {:ok, stats} = File.read!("priv/static/stats.json") |> Parser.parse()
        stats
      :dev ->
        %{
          "assetsByChunkName" => %{
            "app" => ["js/app.js", "css/app.css"],
            "vendor" => ["js/vendor.js", "css/vendor.css"],
            "manifest" => "js/manifest.js"
          }
        }
    end
  end

  def render("scripts.html", assigns) do
    [css: _, js: [manifest, vendor, app]] = files()

    ~E"""
      <script src="<%= static_path(@conn, "/#{manifest}") %>"></script>
      <script src="<%= static_path(@conn, "/#{vendor}") %>"></script>
      <script src="<%= static_path(@conn, "/#{app}") %>"></script>
    """
  end
  def render("links.html", assigns) do
    [css: [vendor, app], js: _] = files()

    ~E"""
      <link rel="stylesheet" href="<%= static_path(@conn, "/#{vendor}") %>">
      <link rel="stylesheet" href="<%= static_path(@conn, "/#{app}") %>">
    """
  end

  defp files() do
    %{
      "assetsByChunkName" => %{
        "app" => app_files,
        "vendor" => vendor_files,
        "manifest" => manifest
      }
    } = stats()

    [app_js, app_css] = app_files
    [vendor_js, vendor_css] = vendor_files

    [css: [vendor_css, app_css], js: [manifest, vendor_js, app_js]]
  end

end
