defmodule Docker.Client do
  use Tesla

  alias Docker.Spec.Service

  plug Tesla.Middleware.BaseUrl, base_url
  plug Tesla.Middleware.JSON

  adapter fn(env) ->
    Tesla.Adapter.Hackney.call(env, [ssl_options: ssl_options])
  end

  def base_url do
    app_config = Application.get_env(:rotterdam, Docker.Client)

    "https://#{app_config[:host]}:#{app_config[:port]}"
  end

  def ssl_options do
    cert_path = Application.get_env(:rotterdam, Docker.Client)[:cert_path]

    [certfile: cert_path <> "/cert.pem",
     cacertfile: cert_path <> "/ca.pem",
     keyfile: cert_path <> "/key.pem"]
  end

  def images, do: get("/images/json") |> response
  def images(id), do: get("/images/#{id}/json") |> response

  def containers, do: get("/containers/json") |> response
  def containers(id), do: get("/containers/#{id}/json") |> response

  def services, do: get("/services") |> response
  def services(id), do: get("/services/#{id}") |> response

  def create_service(name, image) do
    config = Service.config_struct(name, image)
    post("/services/create", config) |> response
  end

  def remove_service(id), do: delete("/services/#{id}")

  def tasks, do: get("/tasks") |> response
  def tasks(id), do: get("/tasks/#{id}") |> response


  def events(stream_to) do
    # TODO: PR to Tesla. hackney adapter is not handling {:ok, #Reference<pid>}
    #get("/events", opts: [async: true, stream_to: stream_to, recv_timeout: :infinity])
    HTTPoison.get "#{base_url}/event", %{}, stream_to: stream_to, recv_timeout: :infinity, ssl: ssl_options
  end

  def response(%Tesla.Env{body: body, status: status}) do
    case status do
      _ when status in 200..299 ->
        {:ok, body, status}
      _   ->
        {:error, body, status}
    end
  end

end
