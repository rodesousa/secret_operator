defmodule SecretOperator.Controller.V1.SecretRef do
  @moduledoc """
  SecretOperator: SecretRef CRD.

  ## Kubernetes CRD Spec

  By default all CRD specs are assumed from the module name, you can override them using attributes.

  ### Examples
  ```
  # Kubernetes API version of this CRD, defaults to value in module name
  @version "v2alpha1"

  # Kubernetes API group of this CRD, defaults to "secret-operator.example.com"
  @group "kewl.example.io"

  The scope of the CRD. Defaults to `:namespaced`
  @scope :cluster

  CRD names used by kubectl and the kubernetes API
  @names %{
    plural: "foos",
    singular: "foo",
    kind: "Foo",
    shortNames: ["f", "fo"]
  }
  ```

  ## Declare RBAC permissions used by this module

  RBAC rules can be declared using `@rule` attribute and generated using `mix bonny.manifest`

  This `@rule` attribute is cumulative, and can be declared once for each Kubernetes API Group.

  ### Examples

  ```
  @rule {apiGroup, resources_list, verbs_list}

  @rule {"", ["pods", "secrets"], ["*"]}
  @rule {"apiextensions.k8s.io", ["foo"], ["*"]}
  ```
  """
  use Bonny.Controller

  # @group "your-operator.your-domain.com"
  # @version "v1"

  # @scope :namespaced
  @scope :cluster
  @names %{
    plural: "secretrefs",
    singular: "secretref",
    kind: "SecretRef",
    shortNames: []
  }

  @additionalPrinterColumns [
    %{
      name: "Origin",
      type: "string",
      description: "Origin namespace",
      JSONPath: ".spec.originNamespace"
    },
    %{
      name: "Target",
      type: "string",
      description: "Target namespace",
      JSONPath: ".spec.targetNamespace"
    }
  ]

  # @rule {"", ["pods", "configmap"], ["*"]}
  @rule {"", ["secrets"], ["*"]}

  @doc """
  Handles an `ADDED` event
  """
  @spec add(map()) :: :ok | :error
  @impl Bonny.Controller
  def add(payload) do
    with {:ok, response} <-
           K8s.Client.get(
             "v1",
             "Secret",
             namespace: payload["spec"]["originNamespace"],
             name: payload["spec"]["secretName"]
           )
           |> K8s.Client.run(:default) do
      response
      |> copy(payload["spec"]["targetNamespace"])
      |> K8s.Client.create()
      |> K8s.Client.run(:default)

      :ok
    end
  end

  @doc """
  Handles a `MODIFIED` event
  """
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(payload), do: update_secret(payload)

  @doc """
  Handles a `DELETED` event
  """
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(payload) do
    response =
      K8s.Client.delete(
        "v1",
        "secret",
        namespace: payload["spec"]["targetNamespace"],
        name: payload["spec"]["secretName"]
      )
      |> K8s.Client.run(:default)

    case response do
      {:ok, _} ->
        :ok

      {_, msg} ->
        IO.puts(msg)
        :error
    end
  end

  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @spec reconcile(map()) :: :ok | :error
  @impl Bonny.Controller
  def reconcile(payload), do: update_secret(payload)

  @doc """
  copy a secret and return the copy in CRD namespace
  """
  @spec copy(map(), String.t()) :: map()
  def copy(payload, ns) do
    %{
      "apiVersion" => payload["apiVersion"],
      "kind" => "Secret",
      "metadata" => %{
        "name" => payload["metadata"]["name"],
        "annotations" => payload["metadata"]["annotations"],
        "namespace" => ns
      },
      "data" => payload["data"],
      "type" => payload["type"]
    }
  end

  @doc """
  Test if secret origin == target
  """
  @spec update_secret(map()) :: :ok | :error
  defp update_secret(payload) do
    with {:ok, secret_reference} <-
           K8s.Client.get(
             "v1",
             "secret",
             namespace: payload["spec"]["originNamespace"],
             name: payload["spec"]["secretName"]
           )
           |> K8s.Client.run(:default),
         {:ok, secret_copied} <-
           K8s.Client.get(
             "v1",
             "secret",
             namespace: payload["spec"]["targetNamespace"],
             name: payload["spec"]["secretName"]
           )
           |> K8s.Client.run(:default) do
      case Map.equal?(secret_reference["data"], secret_copied["data"]) do
        false ->
          %{secret_copied | "data" => secret_reference["data"]}
          |> K8s.Client.update()
          |> K8s.Client.run(:default)

          :ok

        true ->
          :ok
      end
    else
      err ->
        IO.inspect(err)
        :ko
    end
  end
end
