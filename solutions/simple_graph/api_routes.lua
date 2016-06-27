--#ENDPOINT GET /development/test
return 'hello world! \r\nI am a test Murano Solution API Route entpoint'

--#ENDPOINT GET /development/device/{sn}/data
local sn = tostring(request.parameters.sn)
local window = tostring(request.parameters.window) -- in minutes,if ?window=<number>
if true then
  local data = {}
  if window == nil then window = '30' end
  -- Assumes temperature and humidity data device resources
  out = Timeseries.query({
    epoch='ms',
    q = "SELECT value FROM temperature,humidity WHERE sn = '" ..sn.."' AND time > now() - "..window.."m LIMIT 10000"})
  data['timeseries'] = out
  return data
else
  http_error(403, response)
end
