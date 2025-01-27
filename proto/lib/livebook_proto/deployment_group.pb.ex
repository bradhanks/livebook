defmodule LivebookProto.DeploymentGroup do
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :string
  field :name, 2, type: :string
  field :mode, 3, type: :string
  field :secrets, 4, repeated: true, type: LivebookProto.DeploymentGroupSecret
  field :clustering, 5, type: :string
  field :zta_provider, 6, type: :string
  field :zta_key, 7, type: :string
end
