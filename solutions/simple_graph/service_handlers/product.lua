--
-- Product Event Handler
--
-- TIME SERIES DATABASE STORAGE:
-- Write All Device Resource Data to timeseries database
Timeseries.write({
  query = data.alias .. ",sn=" .. data.device_sn .. " value=" .. data.value[2]
})

-- KEY VALUE STORE:
-- Write All Device Resources incomiong data to key/value data store
-- Check to see what data already exists
local resp = Keystore.get({key = "sn_" .. data.device_sn})
-- Make sure each device has the following keys stored
local value = {
  temperature = "undefined",
  hours = "undefined",
  state = "undefined"
}
if type(resp) == "table" and type(resp.value) == "string" then
  value = from_json(resp.value) -- Decode from JSON to Lua Table
end
-- Add in other available data about this device / incoming data
value[data.alias] = data.value[2]
value["timestamp"] = data.timestamp/1000
value["pid"] = data.vendor or data.pid
value["ip"] = data.source_ip
-- Write data into key/value data store
Keystore.set({key = "sn_" .. data.device_sn, value = to_json(values)})
