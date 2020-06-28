defmodule Fset.EctoType.EncryptedBinary do
  use Cloak.Ecto.Binary, vault: Fset.Vault
end
