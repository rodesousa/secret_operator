defmodule SecretOperatorTest do
  use ExUnit.Case
  doctest SecretOperator

  test "greets the world" do
    assert SecretOperator.hello() == :world
  end
end
