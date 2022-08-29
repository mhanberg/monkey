defmodule Monkey.ObjectTest do
  use ExUnit.Case, async: true

  alias Monkey.Object
  alias Monkey.Object.Obj

  test "string hash key" do
    hello1 = %Object.String{value: "Hello World"}
    hello2 = %Object.String{value: "Hello World"}

    diff1 = %Object.String{value: "My name is johnny"}
    diff2 = %Object.String{value: "My name is johnny"}

    assert Obj.hash_key(hello1) == Obj.hash_key(hello2)
    assert Obj.hash_key(diff1) == Obj.hash_key(diff2)
    refute Obj.hash_key(hello1) == Obj.hash_key(diff1)
  end

  test "boolean hash key" do
    true1 = %Object.Boolean{value: true}
    true2 = %Object.Boolean{value: true}

    false1 = %Object.Boolean{value: false}
    false2 = %Object.Boolean{value: false}

    assert Obj.hash_key(true1) == Obj.hash_key(true2)
    assert Obj.hash_key(false1) == Obj.hash_key(false2)
    refute Obj.hash_key(true1) == Obj.hash_key(false1)
  end

  test "integer hash key" do
    one1 = %Object.Integer{value: 1}
    one2 = %Object.Integer{value: 1}

    two1 = %Object.Integer{value: 2}
    two2 = %Object.Integer{value: 2}

    assert Obj.hash_key(one1) == Obj.hash_key(one2)
    assert Obj.hash_key(two1) == Obj.hash_key(two2)
    refute Obj.hash_key(one1) == Obj.hash_key(two1)
  end
end
