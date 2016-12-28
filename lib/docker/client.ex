defmodule Docker.Middleware.AdapterOpts do
  def call(env, next, opts) do
    opts = Keyword.merge(opts, env.opts)
    env = %{env | opts: opts}
    IO.inspect opts
    Tesla.run(env, next)
  end
end


defmodule Docker do
  use Tesla

  alias Docker.Spec.Service

  adapter :hackney

  def client(host, port, cert_path \\ nil, opts \\ [connect_timeout: 1500]) do
    {scheme, opts } = case cert_path do
      nil ->
        {"http", opts}
      _   ->
        ssl_options = build_ssl_options(cert_path)
        opts = Keyword.merge([ssl_options: ssl_options], opts)
        {"https", opts}
    end

    base_url = "#{scheme}://#{host}:#{port}"

    client = Tesla.build_client [
      {Docker.Middleware.AdapterOpts, opts},
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.JSON, []}
    ]

    try do
      get(client, "/version", opts: [recv_timeout: 2000])
      {:ok, client}
    rescue
      error in Tesla.Error ->
        msg = err_message(error.reason, port, base_url)
        {:error, "Error connecting to host #{host}. #{msg}"}
    end
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

  defp response(%Tesla.Env{body: body, status: status}) do
    case status do
      _ when status in 200..299 ->
        {:ok, body, status}
      _   ->
        {:error, body, status}
    end
  end

  defp err_message(reason, port, base_url) do
    case reason do
      :bad_request ->
        "Bad request using base URL #{base_url}"
      :ehostunreach ->
        "Unreachable"
      :econnrefused ->
        "Verify API is listening on port #{port}"
      :connect_timeout ->
        "Connection timeout"
      {:options, {_, path, {:error, :enoent}}} ->
        "Path #{path} does not exists"
      {:options, {_, path, {:error, :eacces}}} ->
        "Cannot read #{path}. Verify file permissions"
      {:keyfile, {:badmatch, []}} ->
        "Bad certificate key"
      {:tls_alert, _} ->
        "Bad TLS certificate"
      _ ->
        "Unknown reason"
    end
  end

end
