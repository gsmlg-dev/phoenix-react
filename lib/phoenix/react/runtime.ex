defmodule Phoenix.React.Runtime do
  @moduledoc """
  The runtime of react, like node, babel-node, etc.
  """

  @type t :: %__MODULE__{}

  defstruct __MODULE__: [:name, :command, :working_dir]

end
