defmodule Docker.Client.SslOptions do
  def call(env, next, ssl_options) do
    env = %{env | opts: [ssl_options: ssl_options]}
    Tesla.run(env, next)
  end
end

defmodule Docker do
  use Tesla

  alias Docker.Spec.Service

  plug Tesla.Middleware.JSON

  adapter fn(env) ->
    [{:ssl_options, ssl_options}] = env.opts
    Tesla.Adapter.Hackney.call(env, [ssl_options: ssl_options])
  end


  def client(host, port, cert_path) do
    Tesla.build_client [
      {Docker.Client.SslOptions, build_ssl_options(cert_path)},
      {Tesla.Middleware.BaseUrl, "https://#{host}:#{port}"}
    ]
  end

  def build_ssl_options(cert_path) do
    [certfile: cert_path <> "/cert.pem",
     cacertfile: cert_path <> "/ca.pem",
     keyfile: cert_path <> "/key.pem"]
  end

  def images, do: get("/images/json") |> response
  def images(id), do: get("/images/#{id}/json") |> response

  def containers, do: get("/containers/json") |> response
  def containers(id), do: get("/containers/#{id}/json") |> response

  def services(client), do: get(client, "/services") |> response
  def services(client, id), do: get(client, "/services/#{id}") |> response

  def create_service(name, image) do
    config = Service.config_struct(name, image)
    post("/services/create", config) |> response
  end

  def remove_service(id), do: delete("/services/#{id}")

  def tasks, do: get("/tasks") |> response
  def tasks(id), do: get("/tasks/#{id}") |> response

  def events(host, port, ssl_options, stream_to) do
    # TODO: PR to Tesla. hackney adapter is not handling {:ok, #Reference<pid>}
    #get("/events", opts: [async: true, stream_to: stream_to, recv_timeout: :infinity])
    HTTPoison.get "https://#{host}:#{port}/events", %{}, stream_to: stream_to, recv_timeout: :infinity, ssl: ssl_options
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
