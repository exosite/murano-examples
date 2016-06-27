--#ENDPOINT GET /development/test
return 'Hello World! \r\nI am a test Murano Solution API Route entpoint'

--#ENDPOINT GET /development/device/{sn}/keyvalue
-- Show current key-value data for a specific unique device
local identifier = tostring(request.parameters.identifier)
local resp = Keystore.get({key = "identifier_" .. identifier})
return 'Getting Key Value Raw Data for: '..identifier..'\r\n'..to_json(resp)


--#ENDPOINT GET /development/device/{identifier}/timeseries
-- Show current time-series data for a specific unique device
local identifier = tostring(request.parameters.identifier)
local window = tostring(request.parameters.window) -- in minutes,if ?window=<number>
if true then
  local data = {}
  if window == nil then window = '30' end
  -- Assumes temperature and humidity data device resources
  out = Timeseries.query({
    epoch='ms',
    q = "SELECT value FROM temperature,humidity WHERE identifier = '" ..identifier.."' LIMIT 20"})
  data['timeseries'] = out

  return 'Getting Last 20 Time Series Raw Data Points for: '..identifier..'\r\n'..to_json(out)
else
  http_error(403, response)
end


--#ENDPOINT GET /development/device/{identifier}/data
local identifier = tostring(request.parameters.identifier)
local window = tostring(request.parameters.window) -- in minutes,if ?window=<number>
if true then
  local data = {}
  if window == nil then window = '30' end
  -- Assumes temperature and humidity data device resources
  out = Timeseries.query({
    epoch='ms',
    q = "SELECT value FROM temperature,humidity WHERE identifier = '" ..identifier.."' AND time > now() - "..window.."m LIMIT 10000"})
  data['timeseries'] = out
  return data
else
  http_error(403, response)
end
