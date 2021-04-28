defmodule Processor do
  use Bitwise
  def emptyState do
    %{
      :programCounter=>0,
      :stackPointer=>0,
      :stack=>[],
      :registers=>List.duplicate(0, 16),
      :iRegister=> 0,
      :delay=>0,
      :sound=>0,
      :memory=>%{}}
  end
  def getInstruction(programCounter, memory) do
      upper = Map.fetch(memory,programCounter)
      lower = Map.fetch(memory,programCounter+1)
      case {upper,lower} do
        {{:ok,u},{:ok,l}} -> {:ok,u,l}
        {:error,_} -> :error
        {_,:error} -> :error
      end
  end

  def getInstructionNibbles(instruction) do
    highestNibble = (elem(instruction,0) >>> 4) &&& 0x0F
    highNibble = elem(instruction,0) &&& 0x0F
    lowNibble = (elem(instruction,1) >>> 4) &&& 0x0F
    lowestNibble = elem(instruction,1) &&& 0x0F
    {highestNibble,highNibble,lowNibble,lowestNibble}
  end

  def returnFromSubroutine(state) do
    [head | tail] = Map.fetch!(state,:stack)
    Map.put(Map.put(Map.put(state,:programCounter,head),:stack,tail),:stackPointer,Map.fetch!(state,:stackPointer)-1)
  end
end
