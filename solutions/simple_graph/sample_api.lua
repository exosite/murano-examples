--#ENDPOINT GET /admin/lightbulb/{sn}
local sn = tostring(request.parameters.sn)

if true then
  local data = {}
  out = Timeseries.query({
    epoch='ms',
    q = 'SELECT value FROM temperature,humidity,'.. sn ..' WHERE time > now() - 30m LIMIT 10000'})
  data['timeseries'] = out
  return data
else
  http_error(403, response)
end
