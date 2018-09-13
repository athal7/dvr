defmodule DVR.DVRCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case

      setup do
        :mnesia.clear_table(:dvr)
        DVR.Store.init_store()
        DVR.Store.copy_store()
        :ok
      end
    end
  end
end
