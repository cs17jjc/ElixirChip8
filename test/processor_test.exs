defmodule ProcessorTest do
  use ExUnit.Case
  doctest Processor

  test "Empty State" do
    assert Processor.emptyState() == %{
      :programCounter=>0,
      :stackPointer=>0,
      :stack=>[],
      :registers=>List.duplicate(0, 16),
      :iRegister=> 0,
      :delay=>0,
      :sound=>0,
      :memory=>%{}}
  end
  test "Fetch Instruction" do
    memory = %{0=>0,1=>1,2=>4,3=>9}
    assert Processor.getInstruction(0,memory) == {:ok,0,1}
    assert Processor.getInstruction(2,memory) == {:ok,4,9}
    assert Processor.getInstruction(10,memory) == :error
    assert Processor.getInstruction(-1,memory) == :error
  end
  test "Nibblise Instruction" do
    assert Processor.getInstructionNibbles({0x0F,0x0F}) == {0x00,0x0F,0x00,0x0F}
    assert Processor.getInstructionNibbles({0xF0,0xF0}) == {0x0F,0x00,0x0F,0x00}
  end
end
