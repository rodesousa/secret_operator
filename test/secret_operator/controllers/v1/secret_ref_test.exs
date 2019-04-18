defmodule SecretOperator.Controller.V1.SecretRefTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias SecretOperator.Controller.V1.SecretRef

  describe "add/1" do
    test "returns :ok" do
      event = %{}
      result = SecretRef.add(event)
      assert result == :ok
    end
  end

  describe "modify/1" do
    test "returns :ok" do
      event = %{}
      result = SecretRef.modify(event)
      assert result == :ok
    end
  end

  describe "delete/1" do
    test "returns :ok" do
      event = %{}
      result = SecretRef.delete(event)
      assert result == :ok
    end
  end

  describe "reconcile/1" do
    test "returns :ok" do
      event = %{}
      result = SecretRef.reconcile(event)
      assert result == :ok
    end
  end
end
