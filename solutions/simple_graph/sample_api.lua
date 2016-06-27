--#ENDPOINT GET /admin/lightbulb/{sn}
local sn = tostring(request.parameters.sn)
local window = tostring(request.parameters.window)

if true then
  local data = {}
  if window == nil then window = '30' end
  out = Timeseries.query({
    epoch='ms',
    q = "SELECT value FROM temperature,humidity WHERE sn = '" ..sn.."' AND time > now() - "..window.."m LIMIT 10000"})
  data['timeseries'] = out
  return data
else
  http_error(403, response)
end
--#ENDPOINT GET /admin/test
return 'running'
--#ENDPOINT GET /admin/gettsdb
local data = {}
out = Timeseries.query({
  epoch='ms',
  q = 'SELECT value FROM *'})
data['timeseries'] = out
return data
