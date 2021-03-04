defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    # registry = start_supervised!(KV.Registry)
    # %{registry: registry}
    # using test name to name registries.
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    # :error when a registry not exists.any()
    assert KV.Registry.lookup(registry, "shopping") == :error

    # can create a bucket
    KV.Registry.create(registry, "shopping")
    # get bucket and check creation
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # bucket can store key/value
    KV.Bucket.put(bucket, "milk", 2)
    assert KV.Bucket.get(bucket, "milk") == 2
  end

  test "remove buckets on exit", %{registry: registry} do
    # create a bucket
    KV.Registry.create(registry, "shopping")
    # get bucket
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    # stop
    # Agent.stop(bucket)
    # sent sync stop/2. :DOWN are delivered. but not guarantee it has been processed yet.
    Agent.stop(bucket)
    # do another async to KV.Registry to make sure previous request(stop2/ :DOWN) is processed.
    _ = KV.Registry.create(registry, "bogus")
    # verify
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "remove buckets on crash", %{registry: registry} do
    # create a bucket
    KV.Registry.create(registry, "shopping")
    # get bucket
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    # stop
    # Agent.stop(bucket)
    # sent sync stop/2. :DOWN are delivered. but not guarantee it has been processed yet.
    Agent.stop(bucket, :shutdown)
    # do another async to KV.Registry to make sure previous request(stop2/ :DOWN) is processed.
    _ = KV.Registry.create(registry, "bogus")
    # verify
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end
