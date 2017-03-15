local component = require "component"
local event = require "event"
local filesystem = require "filesystem"
local sides = require "sides"
local colors = require "colors"

local redfs = {proxy={type="filesystem",address="a15416ca-a9a8-11e4-82fa-001b770653b8"}}

local root_node = {}

-- Giant block of things that would normally be closures
-- We save some memory by having only one copy of these, and using a parameter
-- block to pass information
local function wireless_frequency_read(addr)
   return tostring(component.invoke(addr, "getWirelessFrequency"))
end
local function wireless_frequency_write(wat, addr)
   wat = tonumber(wat)
   if not wat or wat%1~=0 then return nil,"Invalid argument" end
   component.invoke(addr, "setWirelessFrequency", wat)
end
local function wireless_input_read(addr)
   return tostring(component.invoke(addr, "getWirelessInput"))
end
local function wireless_output_read(addr)
   return tostring(component.invoke(addr, "getWirelessOutput"))
end
local function wireless_output_write(wat, addr)
   wat = tonumber(wat)
   if not wat or wat < 0 or wat%1~=0 then return nil,"Invalid argument" end
   component.invoke(addr, "setWirelessOutput", wat)
end
local function normal_input_read(addr, side)
   return tostring(component.invoke(addr, "getInput", side))
end
local function normal_output_read(addr, side)
   return tostring(component.invoke(addr, "getOutput", side))
end
local function normal_output_write(wat, addr, side)
   wat = tonumber(wat)
   if not wat or wat < 0 or wat%1~=0 then return nil,"Invalid argument" end
   component.invoke(addr, "setOutput", side, wat)
end
local function color_input_read(addr, side, color)
   return tostring(component.invoke(addr, "getBundledInput", side, color))
end
local function color_output_read(addr, side, color)
   return tostring(component.invoke(addr, "getBundledOutput", side, color))
end
local function color_output_write(wat, addr, side, color)
   wat = tonumber(wat)
   if not wat or wat < 0 or wat%1~=0 then return nil,"Invalid argument" end
   component.invoke(addr, "setBundledOutput", side, color, wat)
end

local function build_redstone_component_node(addr)
   local ret = {
      name=addr,
      -- no need to move this closure to the giant block up top; its memory
      -- usage is similar to that of a function reference + a parameter block
      { name="address", read=function() return addr end }
   }
   local methods = component.methods(addr)
   if methods.getWirelessInput then
      local wireless_param_block = {addr}
      ret[#ret+1] = {
         name="wireless",
         { name="input", param=wireless_param_block,
           read=wireless_input_read,
         },
         { name="output", param=wireless_param_block,
           read=wireless_output_read, write=wireless_output_write,
         },
         { name="frequency", param=wireless_param_block,
           read=wireless_frequency_read, write=wireless_frequency_write,
         },
      }
   end
   local side_nodes = {}
   for side=0,5 do
      local side_param_block = {addr, side}
      local node = {
         name=tostring(side),
         { name="input", param=side_param_block,
           read=normal_input_read,
         },
         { name="output", param=side_param_block,
           read=normal_output_read, write=normal_output_write,
         },
      }
      if methods.getBundledInput then
         local bundle_node = {
            name="bundled"
         }
         local color_nodes = {}
         for color=0,15 do
            local color_param_block = {addr, side, color}
            local node = {
               name=tostring(color),
               { name="input", param=color_param_block,
                 read=color_input_read,
               },
               { name="output", param=color_param_block,
                 read=color_output_read, write=color_output_write,
               },
            }
            bundle_node[#bundle_node+1] = node
            color_nodes[color] = node
         end
         for k,v in pairs(colors) do
            if type(k) == "string" and color_nodes[v] then
               bundle_node[#bundle_node+1] = { name=k, link=color_nodes[v] }
            end
         end
         node[#node+1] = bundle_node
      end
      ret[#ret+1] = node
      side_nodes[side] = node
   end
   for k,v in pairs(sides) do
      if type(k) == "string" and side_nodes[v] then
         ret[#ret+1] = { name=k, link=side_nodes[v] }
      end
   end
   return ret
end

local function cook_node(node)
   if node._cooked then return end
   node._cooked = true
   if not node.link then
      node._children = {}
      for n=1,#node do
         cook_node(node[n])
         node._children[node[n].name] = node[n]
      end
   end
end

local function resolve_node(path)
   local cur_node = root_node
   for n=1,#path do
      cur_node = cur_node._children[path[n]]
      if not cur_node then return nil,"no such file or directory" end
      while cur_node.link do cur_node = cur_node.link end
   end
   return cur_node
end

local function rebuild_root_node()
   root_node = { name="root" }
   if component.isAvailable("redstone") then
      primary_card = component.getPrimary("redstone").address
   else primary_card = nil end
   for addr in component.list("redstone") do
      root_node[#root_node+1] = build_redstone_component_node(addr)
      if addr == primary_card then
         root_node[#root_node+1] = {name="primary", link=root_node[#root_node]}
      end
   end
   cook_node(root_node)
end
event.listen("component_added", rebuild_root_node)
event.listen("component_removed", rebuild_root_node)
event.listen("component_available", rebuild_root_node)
event.listen("component_unavailable", rebuild_root_node)
rebuild_root_node()

local function unimp()
   return nil, "operation not supported"
end
function redfs.proxy.spaceUsed()
   return 0
end
function redfs.proxy.spaceTotal()
   return 0
end
redfs.proxy.makeDirectory = unimp
redfs.proxy.remove = unimp
redfs.proxy.rename = unimp
redfs.proxy.seek = unimp -- TODO: seek to 0 to prepare to read again
function redfs.proxy.exists(path)
   local node, why = resolve_node(filesystem.segments(path))
   return not not node, why
end
function redfs.proxy.isDirectory(path)
   local node, why = resolve_node(filesystem.segments(path))
   return node and #node > 0
end
function redfs.proxy.size(path)
   local node, why = resolve_node(filesystem.segments(path))
   if not node then return nil, why
   elseif not node.read then return 0
   else return #node.read(table.unpack(node.param or {})) end
end
function redfs.proxy.lastModified(path)
   return 0 -- lazy
end
function redfs.proxy.isReadOnly()
   return false
end
function redfs.proxy.list(path)
   local node, why = resolve_node(filesystem.segments(path))
   if not node then return {}
   else
      local ret = {}
      for n=1,#node do ret[n] = node[n].name end
      return ret
   end
end
function redfs.proxy.getLabel()
   return "RedFS"
end
redfs.proxy.setLabel = redfs.proxy.getLabel
function redfs.proxy.open(path, mode)
   mode = mode or "r"
   local node, why = resolve_node(filesystem.segments(path))
   if not node then return nil, why
   elseif mode:match("^[rwa]") and not mode:match("%+") then
      if mode:sub(1,1) == "r" then
         handle_mode = "read"
      elseif mode:sub(1,1) == "w" or mode:sub(1,1) == "a" then
         handle_mode = "write"
      end
      if handle_mode and node[handle_mode] then
         return {_handler=handler, _mode=handle_mode,
                 _b=mode:match("b"), _node=node}
      elseif #node > 0 then
         return nil,"is a directory"
      else
         return unimp()
      end
   end
   return unimp()
end
function redfs.proxy.read(handle, count)
   -- ignore count, always read a full buffer
   -- unless we've already read, in which case return EOF
   if handle._mode ~= "read" then return unimp() end
   if handle._used then return nil end
   handle._used = true
   local ret = handle._node.read(table.unpack(handle._node.param or {}))
   if handle._b then return ret
   elseif ret then return ret.."\n"
   else return nil end
end
function redfs.proxy.write(handle, data)
   if handle._mode ~= "write" then return unimp() end
   return handle._node.write(data, table.unpack(handle._node.param or {}))
end
function redfs.proxy.close(handle)
   handle._mode = nil
end

return redfs
