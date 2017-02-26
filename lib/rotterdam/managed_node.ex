defmodule Rotterdam.Managed.Node do
  defstruct id: nil,
            label: nil,
            role: nil,
            host: nil,
            port: "2376",
            cert_path: nil,
            status: :stopped,
            status_msg: ""
end
