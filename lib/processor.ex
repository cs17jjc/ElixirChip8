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
  def state(pc,reg,mem) do
    Map.put(Map.put(Map.put(Processor.emptyState(),:programCounter,pc),:registers,reg),:memory,mem)
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

  def nibblesToNumber(nibbleList) do
    withIndex = Enum.with_index(Enum.reverse(nibbleList))
    values = Enum.map(withIndex,fn t -> elem(t,0) <<< (elem(t,1)*4) end)
    Enum.sum(values)
  end

  def incrProgramCounter(state) do
    Map.put(state,:programCounter,Map.fetch!(state,:programCounter)+2)
  end

  def updateState(state) do
    inst = getInstruction(Map.fetch!(state,:programCounter),Map.fetch!(state,:memory))
    nibbles = getInstructionNibbles(inst)
    case nibbles do
       {0x0,0x0,0xE,0xE}->Processor.returnFromSubroutine(state)
       {0x1,n1,n2,n3} -> Processor.jumpToAddr(state,n1,n2,n3)
       {0x2,n1,n2,n3} -> Processor.callAddr(state,n1,n2,n3)
       {0x3,vx,n1,n2} -> Processor.incrProgramCounter(Processor.skipEqual(state,vx,n1,n2))
       {0x4,vx,n1,n2} -> Processor.incrProgramCounter(Processor.skipNotEqual(state,vx,n1,n2))
       {0x5,vx,vy,0} -> Processor.incrProgramCounter(Processor.skipEqualRegisters(state,vx,vy))
       {0x6,vx,n1,n2}-> Processor.incrProgramCounter(Processor.loadValueToRegisters(state,vx,n1,n2))
       {0x7,vx,n1,n2}-> Processor.incrProgramCounter(Processor.addValueRegisters(state,vx,n1,n2))
       {0x8,vx,vy,0}-> Processor.incrProgramCounter(Processor.loadValueRegisters(state,vx,vy))
    end
  end

  def returnFromSubroutine(state) do
    [head | tail] = Map.fetch!(state,:stack)
    Map.put(Map.put(Map.put(state,:programCounter,head),:stack,tail),:stackPointer,Map.fetch!(state,:stackPointer)-1)
  end
  def jumpToAddr(state,highNibble,lowNibble,lowestNibble) do
    Map.put(state,:programCounter,nibblesToNumber([highNibble,lowNibble,lowestNibble]))
  end
  def callAddr(state,highNibble,lowNibble,lowestNibble) do
    pcOnStack = Map.put(state,:stack,[Map.fetch!(state,:programCounter) | Map.fetch!(state,:stack)])
    incStackPtr = Map.put(pcOnStack,:stackPointer,Map.fetch!(pcOnStack,:stackPointer)+1)
    Map.put(incStackPtr,:programCounter,nibblesToNumber([highNibble,lowNibble,lowestNibble]))
  end

  def skipNotEqual(state,vx,lowNibble,lowestNibble) do
    cond do
      Enum.fetch!(Map.fetch!(state,:registers),vx) != nibblesToNumber([lowNibble,lowestNibble]) -> Map.put(state,:programCounter,Map.fetch!(state,:programCounter)+2)
      true -> state
    end
  end
  def skipEqual(state,vx,lowNibble,lowestNibble) do
    cond do
      Enum.fetch!(Map.fetch!(state,:registers),vx) == nibblesToNumber([lowNibble,lowestNibble]) -> Map.put(state,:programCounter,Map.fetch!(state,:programCounter)+2)
      true -> state
    end
  end
  def skipEqualRegisters(state,vx,vy) do
    cond do
      Enum.fetch!(Map.fetch!(state,:registers),vx) == Enum.fetch!(Map.fetch!(state,:registers),vy) -> Map.put(state,:programCounter,Map.fetch!(state,:programCounter)+2)
      true -> state
    end
  end

  def loadValueToRegisters(state,vx,lowNibble,lowestNibble) do
    Map.put(state,:registers,List.replace_at(Map.fetch!(state,:registers),vx,nibblesToNumber([lowNibble,lowestNibble])))
  end
  def addValueRegisters(state,vx,lowNibble,lowestNibble) do
    registers = Map.fetch!(state,:registers)
    oldValue = Enum.fetch!(registers,vx)
    newValue = oldValue + nibblesToNumber([lowNibble,lowestNibble])
    Map.put(state,:registers,List.replace_at(registers,vx,newValue))
  end

  def loadValueRegisters(state,vx,vy) do
    registers = Map.fetch!(state,:registers)
    newValue = Enum.fetch!(registers,vy)
    Map.put(state,:registers,List.replace_at(registers,vx,newValue))
  end

  def orValueRegisters(state,vx,vy) do
    registers = Map.fetch!(state,:registers)
    newValue = Enum.fetch!(registers,vx) ||| Enum.fetch!(registers,vy)
    Map.put(state,:registers,List.replace_at(registers,vx,newValue))
  end
  def andValueRegisters(state,vx,vy) do
    registers = Map.fetch!(state,:registers)
    newValue = Enum.fetch!(registers,vx) &&& Enum.fetch!(registers,vy)
    Map.put(state,:registers,List.replace_at(registers,vx,newValue))
  end
  def xorValueRegisters(state,vx,vy) do
    registers = Map.fetch!(state,:registers)
    newValue = Enum.fetch!(registers,vx) ^^^ Enum.fetch!(registers,vy)
    Map.put(state,:registers,List.replace_at(registers,vx,newValue))
  end
  def addValueRegisters(state,vx,vy) do
    registers = Map.fetch!(state,:registers)
    newValue = Enum.fetch!(registers,vx) + Enum.fetch!(registers,vy)
    Map.put(state,:registers,List.replace_at(registers,vx,newValue))
  end
  def subValueRegisters(state,vx,vy) do
    registers = Map.fetch!(state,:registers)
    newValue = Enum.fetch!(registers,vx) - Enum.fetch!(registers,vy)
    Map.put(state,:registers,List.replace_at(registers,vx,newValue))
  end
end
