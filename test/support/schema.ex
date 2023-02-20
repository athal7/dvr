defmodule DVR.Absinthe.TestSchema do
  use Absinthe.Schema

  query do
    field(:foo, :foo)
  end

  object :foo do
    field(:bar, :string)
    field(:baz, :string)
  end

  object :foo_update do
    field(:foo, :foo)
    field(:replay_id, :integer)
  end

  subscription do
    field :foo_updates, :foo_update do
      config(fn _, _ -> {:ok, topic: "*"} end)

      resolve(fn root, _, _ ->
        {:ok, replay_id} = DVR.record(root, foo_updates: "*")
        {:ok, Map.put(root, :replay_id, replay_id)}
      end)
    end
  end
end
