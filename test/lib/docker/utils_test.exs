defmodule FakeStruct do
  defstruct name: 1, foo_bar: "baz"
end

defmodule Docker.Spec.UtilsTest do
  use ExUnit.Case, async: true

  alias Docker.Spec.Utils

  test "format keys camelizes map keys" do
    map = %{name: %{"key_one": 1, second_key: "value"}}
    assert Utils.format_keys(map) == %{"Name" => %{"KeyOne" => 1, "SecondKey" => "value"}}
  end

  test "format keys camelizes struct keys" do
    assert Utils.format_keys(%FakeStruct{}) == %{"Name" => 1, "FooBar" => "baz"}
  end
end
