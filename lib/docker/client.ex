defmodule Docker.Middleware.SslOptions do
  def call(env, next, ssl_options) do
    opts = Keyword.merge([ssl_options: ssl_options], env.opts)
    env = %{env | opts: opts}
    Tesla.run(env, next)
  end
end


defmodule Docker do
  use Tesla

  alias Docker.Spec.Service

  plug Tesla.Middleware.JSON

  adapter :hackney

  def client(host, port, cert_path) do
    Tesla.build_client [
      {Docker.Middleware.SslOptions, build_ssl_options(cert_path)},
      {Tesla.Middleware.BaseUrl, "https://#{host}:#{port}"}
    ]
  end

  def build_ssl_options(cert_path) do
    [certfile: cert_path <> "/cert.pem",
     cacertfile: cert_path <> "/ca.pem",
     keyfile: cert_path <> "/key.pem"]
  end

  def nodes(client), do: get(client, "/nodes") |> response
  def nodes(client, id), do: get(client, "/nodes/#{id}") |> response

  def images(client), do: get(client, "/images/json") |> response
  def images(client, id), do: get(client, "/images/#{id}/json") |> response

  def containers(client), do: get(client, "/containers/json") |> response
  def containers(client, id), do: get(client, "/containers/#{id}/json") |> response

  def services(client), do: get(client, "/services") |> response
  def services(client, id), do: get(client, "/services/#{id}") |> response

  def create_service(client, name, image) do
    config = Service.config_struct(name, image)
    post(client, "/services/create", config) |> response
  end

  def remove_service(client, id), do: delete(client, "/services/#{id}")

  def tasks(client), do: get(client, "/tasks") |> response
  def tasks(client, id), do: get(client, "/tasks/#{id}") |> response

  def events(client, stream_to) do
    # TODO: PR to Tesla. hackney adapter is not handling {:ok, #Reference<pid>}
    # then switch dep on my fork to Tesla release
    opts = [async: true, stream_to: stream_to, recv_timeout: :infinity]
    get(client, "/events", opts: opts) |> response
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
