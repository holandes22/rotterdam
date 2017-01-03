defmodule Docker.Middleware.AdapterOpts do
  def call(env, next, opts) do
    opts = Keyword.merge(opts, env.opts)
    env = %{env | opts: opts}
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
    # TODO: obtaining opts like this is lame
    %Tesla.Env{opts: opts, url: url} = get(client, "/")
    url = url <> "events"
    # TODO: this is to workaround a weird bug. First connection seems to
    # always be bad and gets closed. It sends a message of the form
    # {:ssl, {:sslsocket, {:gen_tcp, #Port<0.7925>, :tls_connection, :undefined}, #PID<0.337.0>, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nServer: Docker/1.12.3 (linux)\r\nDate: Tue, 03 Jan 2017 09:04:42 GMT\r\nTransfer-Encoding: chunked\r\n\r\n"}
    # That only happens when calling the method from a supervised process.
    # Calling it, for example, from IEx works fine without the workaround
    # (1st conn does not gets closed).
    opts = Keyword.merge(opts, [async: :once, recv_timeout: 0, stream_to: self])
    {:ok, ref} = :hackney.get(url, [], '', opts)
    # Spare caller from the workaround messages
    block_until_timeout(ref)

    opts = Keyword.merge(opts, [async: true, recv_timeout: :infinity, stream_to: stream_to])
    # TODO: Block for the status and header messages. If there is
    # an error return an :error tuple, otherwise continue to stream
    :hackney.get(url, [], '', opts)
  end

  defp block_until_timeout(ref) do
    receive do
      {:hackney_response, ref, {:error, {:closed, :timeout}}} ->
        :ok
      _ ->
        block_until_timeout(ref)
    end

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
