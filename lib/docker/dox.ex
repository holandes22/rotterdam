# TODO: extract to standalone package
defmodule Dox do
  @moduledoc """
  Elixir client for Docker API.
  """
  use Maxwell.Builder, ~w(get post delete)a

  alias Docker.Spec.Service

  middleware Maxwell.Middleware.Json

  adapter Maxwell.Adapter.Hackney

  def conn(host, port, cert_path \\ nil, opts \\ [connect_timeout: 1500]) do
    {scheme, opts} = case cert_path do
      nil ->
        {"http", opts}
      _   ->
        ssl_options = [ssl_options: build_ssl_options(cert_path, host)]
        opts = Keyword.merge(ssl_options, opts)
        {"https", opts}
    end

    base_url = "#{scheme}://#{host}:#{port}"

    conn = base_url
      |> new()
      |> put_option(opts)

    case version(conn, [recv_timeout: 1000]) do
      {:ok, _body} ->
        {:ok, conn}
      {:error, error} ->
        {:error, error}
    end
  end

  def version(conn, opts \\ []) do
    conn
      |> put_option(opts)
      |> put_path("/version")
      |> get
      |> response
  end

  def nodes(conn), do: conn |> put_path("/nodes") |> get |> response
  def nodes(conn, id), do: conn |> put_path("/nodes/#{id}") |> get |> response

  def images(conn), do: conn |> put_path("/images/json") |> get |> response
  def images(conn, id), do: conn |> put_path("/images/#{id}/json") |> get |> response

  def containers(conn), do: conn |> put_path("/containers/json") |> get |> response
  def containers(conn, id), do: conn |> put_path("/containers/#{id}/json") |> get |> response

  def tasks(conn), do: conn |> put_path("/tasks") |> get |> response
  def tasks(conn, id), do: conn |> put_path("/tasks/#{id}") |> get |> response

  def services(conn), do: conn |> put_path("/services") |> get |> response
  def services(conn, id), do: conn |> put_path("/services/#{id}") |> get |> response

  def create_service(conn, name, image) do
    config = Service.config_struct(name, image)
    conn
      |> put_path("/services/create")
      |> put_req_body(config)
      |> post
      |> response
  end

  def remove_service(conn, id) do
    conn
      |> put_path("/services/#{id}")
      |> delete
      |> response
  end

  def events(%Maxwell.Conn{url: url, opts: opts}, stream_to) do
    # TODO: this is to workaround a weird bug. First connection seems to
    # always be bad and gets closed. It sends a message of the form
    # {:ssl, {:sslsocket, {:gen_tcp, #Port<0.7925>, :tls_connection, :undefined}, #PID<0.337.0>, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nServer: Docker/1.12.3 (linux)\r\nDate: Tue, 03 Jan 2017 09:04:42 GMT\r\nTransfer-Encoding: chunked\r\n\r\n"}
    # That only happens when calling the method from a supervised process.
    # Calling it, for example, from IEx works fine without the workaround
    # (1st conn does not get closed).
    opts = Keyword.merge(opts, [async: :once, recv_timeout: 0, stream_to: self()])
    {:ok, ref} = :hackney.get(url, [], '', opts)
    # Spare caller from the workaround messages
    block_until_timeout(ref)

    opts = Keyword.merge(opts, [async: true, recv_timeout: :infinity, stream_to: stream_to])
    # TODO: Block for the status and header messages. If there is
    # an error return an :error tuple, otherwise continue to stream
    # TODO: wrap in a Dox response map
    :hackney.get(url <> "/events", [], '', opts)
  end

  defp block_until_timeout(ref) do
    receive do
      {:hackney_response, _ref, {:error, {:closed, :timeout}}} ->
        :ok
      _ ->
        block_until_timeout(ref)
    end
  end

  defp build_ssl_options(cert_path, _host) do
    [certfile: cert_path <> "/cert.pem",
     cacertfile: cert_path <> "/ca.pem",
     keyfile: cert_path <> "/key.pem",
     verify: :verify_peer,
     #verify_fun: {&:ssl_verify_hostname.verify_fun/3, [check_hostname: to_charlist(host)]}
    ]
  end

  defp response({:ok, %Maxwell.Conn{resp_body: body, status: status}}) do
    case status do
      _ when status in 200..299 ->
        {:ok, body}
      _   ->
        {:error, body}
    end
  end
  defp response({:error, error, %Maxwell.Conn{url: url}}) do
      %URI{port: port} = URI.parse(url)
      msg = err_message(error, port, url)
      {:error, msg}
  end

  defp err_message(reason, port, base_url) do
    case reason do
      :bad_request ->
        "Bad request using base URL #{base_url}"
      :ehostunreach ->
        "Unreachable host"
      :econnrefused ->
        "Connection refused. Verify API is listening on port #{port}"
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
