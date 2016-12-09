defmodule Docker.Client do
  use Tesla

  alias Docker.Spec.Service

  @base_url "https://192.168.99.100:2376"
  @cert_path "/home/pablo/.docker/machine/machines/cluster1-node1"
  @ssl_options [certfile: @cert_path <> "/cert.pem", cacertfile: @cert_path <> "/ca.pem", keyfile: @cert_path <> "/key.pem"]

  plug Tesla.Middleware.BaseUrl, @base_url
  plug Tesla.Middleware.JSON

  adapter Tesla.Adapter.Hackney, [ssl_options: @ssl_options]

  def images, do: get("/images/json") |> response

  def services, do: get("/services") |> response
  def services(id), do: get("/services/" <> id) |> response

  def tasks, do: get("/tasks") |> response
  def tasks(id), do: get("/tasks/" <> id) |> response

  def create_service(name, image) do
    config = Service.config_struct(name, image)
    post("/services/create", config) |> response
  end

  def events(stream_to) do
    # TODO: PR to Tesla. hackney adapter is not handling {:ok, #Reference<pid>}
    #get("/events", opts: [async: true, stream_to: stream_to, recv_timeout: :infinity])
    HTTPoison.get "#{@base_url}/event", %{}, stream_to: stream_to, recv_timeout: :infinity, ssl: @ssl_options
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
