local redfs = require "redfs"
local filesystem = require "filesystem"
local shell = require "shell"

local arg,opt = shell.parse(...)
if #arg ~= 1 or next(opt) then
   print("Usage: mount.redfs /mount/point")
   os.exit(1)
end

local s,e = filesystem.mount(redfs.proxy, arg[1])
if not s then
   print("Mount failed: "..e)
   os.exit(1)
end
