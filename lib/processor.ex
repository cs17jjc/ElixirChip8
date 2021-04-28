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

  def nibblesToNumber(nibbleList) do
    withIndex = Enum.with_index(Enum.reverse(nibbleList))
    values = Enum.map(withIndex,fn t -> elem(t,0) <<< (elem(t,1)*4) end)
    Enum.sum(values)
  end

  def jumpToAddr(state,highNibble,lowNibble,lowestNibble) do
    Map.put(state,:programCounter,nibblesToNumber([highNibble,lowNibble,lowestNibble]))
  end
  def callAddr(state,highNibble,lowNibble,lowestNibble) do
    pcOnStack = Map.put(state,:stack,[Map.fetch!(state,:programCounter) | Map.fetch!(state,:stack)])
    incStackPtr = Map.put(pcOnStack,:stackPointer,Map.fetch!(pcOnStack,:stackPointer)+1)
    Map.put(incStackPtr,:programCounter,nibblesToNumber([highNibble,lowNibble,lowestNibble]))
  end

  def skipNextInstruction(state,vx,lowNibble,lowestNibble) do
    cond do
      Enum.fetch!(Map.fetch!(state,:registers),vx) != nibblesToNumber([lowNibble,lowestNibble]) -> Map.put(state,:programCounter,Map.fetch!(state,:programCounter)+2)
      true -> state
    end
  end
end
