local mp = require 'mp'

local start_time = nil
local end_time = nil

local function reset()
   start_time = nil
   end_time = nil
end

local function add()
   if not start_time then
      start_time = mp.get_property_number("time-pos")
      if not start_time then return end
      if start_time < 0 then start_time = 0 end
      mp.osd_message(string.format("Start at %fs", start_time), 999)
      return
   end
   if not end_time then
      end_time = mp.get_property_number("time-pos")
      if not end_time then return end
      mp.osd_message(string.format("End at %fs", end_time), 999)
      return
   end
   local filepath = mp.get_property("path")
   local file = io.open(string.format("%s-clip.txt", filepath), "a")
   file:write(string.format("%f,%f\n", start_time, end_time))
   file:close()
   mp.osd_message(string.format("Added %fs to %fs", start_time, end_time), 999)
   reset()
end

local function pop()
   if end_time then
      end_time = nil
      mp.osd_message("Reset end time", 1)
      return
   end
   if start_time then
      start_time = nil
      mp.osd_message("Reset start time", 1)
      return
   end
end

reset()

mp.add_key_binding("c", "add", add)
mp.add_key_binding("C", "pop", pop)
