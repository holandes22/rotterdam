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
    config = format_keys(config)
    post("/services/create", config) |> response
  end

  def events(stream_to) do
    # TODO: PR to Tesla. hackney adapter is not handling {:ok, %HTTPoison.AsyncResponse{id: #Reference<pid>}}
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

  def format_keys(%{__struct__: _} = struct) do
    Map.from_struct(struct) |> format_keys
  end
  def format_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, &format_key/2)
  end

  defp format_key({key, value}, accumulator) when is_map(value) do
    put_in(accumulator, [camelize_key(key)], format_keys(value))
  end
  defp format_key({key, value}, accumulator) do
    put_in(accumulator, [camelize_key(key)], value)
  end

  defp camelize_key(key) when is_atom(key), do: key |> Atom.to_string |> camelize_key
  defp camelize_key(key), do: Phoenix.Naming.camelize(key)

end
