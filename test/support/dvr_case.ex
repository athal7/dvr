defmodule DVR.DVRCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case

      setup_all do
        Absinthe.Test.prime(DVR.Absinthe.TestSchema)

        children = [
          {Phoenix.PubSub, name: DVR.Phoenix.PubSub},
          DVR.Phoenix.TestEndpoint,
          {Absinthe.Subscription, DVR.Phoenix.TestEndpoint}
        ]

        {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
        :ok
      end

      setup do
        :mnesia.clear_table(:dvr)
        DVR.Store.init_store()
        DVR.Store.copy_store()
        :ok
      end
    end
  end
end
