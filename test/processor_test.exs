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
  test "Return from subroutine" do
    state = %{:stackPointer=>1,:stack=>[22]}
    assert Processor.returnFromSubroutine(state) == %{:stackPointer=>0,:stack=>[],:programCounter=>22}
  end
  test "Nibbles to value" do
    assert Processor.nibblesToNumber([0xF,0xF]) == 0xFF
    assert Processor.nibblesToNumber([0xA,0xB,0xC,0xD]) == 0xABCD
  end
  test "Jump to addr" do
    assert Map.fetch(Processor.jumpToAddr(%{:programCounter=>0x000},0xC,0xB,0xA),:programCounter) == {:ok,0xCBA}
  end
  test "Call addr" do
    assert Processor.callAddr(%{:programCounter=>0x00,:stackPointer=>0,:stack=>[]},0xC,0xB,0xA) == %{:programCounter=>0xCBA,:stackPointer=>1,:stack=>[0x00]}
  end
end
