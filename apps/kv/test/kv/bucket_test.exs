defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    bucket = start_supervised!(KV.Bucket)
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "delete a key from bucket", %{bucket: bucket} do
    KV.Bucket.put(bucket, "oil", 2)
    assert KV.Bucket.delete(bucket, "oil") == 2
    assert KV.Bucket.delete(bucket, "does-exist-key") == nil
  end

  test "bucket are temporary" do
    assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
  end
end
