defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(KV.Registry)
    %{registry: registry}
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
    Agent.stop(bucket)
    # verify
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end
