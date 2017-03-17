local computer = require("computer")

while true do
  local maxMem = 0
  for i=1,10 do maxMem = math.max(maxMem, computer.freeMemory()) os.sleep(0) end
  print(maxMem)
  os.sleep(5)
end