defmodule Docker.Spec.Utils do

  def format_keys(%{__struct__: _} = struct) do
    Map.from_struct(struct) |> format_keys
  end
  def format_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, &format_key/2)
  end

  defp format_key({key, value}, acc) when is_map(value) do
    put_in(acc, [camelize(key)], format_keys(value))
  end
  defp format_key({key, value}, acc) do
    put_in(acc, [camelize(key)], value)
  end

  defp camelize(atom) when is_atom(atom), do: atom |> Atom.to_string |> camelize
  defp camelize(string), do: Phoenix.Naming.camelize(string)

end
