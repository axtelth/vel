defmodule VelTest do
  use ExUnit.Case
  doctest Vel

  test "greets the world" do
    assert Vel.hello() == :world
  end
end
