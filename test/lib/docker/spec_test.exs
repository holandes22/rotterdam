defmodule Docker.Spec.ServiceTest do
  use ExUnit.Case, async: true

  alias Docker.Spec.Service

  test "config_struct" do
    map = Service.config_struct("fake_name", "fake_image")
    assert map["Name"] == "fake_name"
    assert map["TaskTemplate"]["ContainerSpec"]["Image"] == "fake_image"
  end
end
