{:ok, _} = DVR.Phoenix.TestEndpoint.start_link()
{:ok, _} = Absinthe.Subscription.start_link(DVR.Phoenix.TestEndpoint)

ExUnit.start(exclude: [:skip])
