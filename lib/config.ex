defmodule SecretOperator.Config do


  @doc """
  ## Examples
   
  iex> SecretOperator.Config.secret_namespace_origin
  "secret"

  """

def secret_namespace_origin do
  Application.get_env(:secret_operator, :secret_namespace_origin)
end
  
end
