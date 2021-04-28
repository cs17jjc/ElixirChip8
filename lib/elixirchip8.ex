defmodule Elixirchip8 do
  def main do
    # Program counter, Stack Pointer, Stack, Regsters, I Register, Delay, Sound, Memory
    state = {0, 0, [], List.duplicate(0, 16), 0, 0, 0, %{}}
  end
end
