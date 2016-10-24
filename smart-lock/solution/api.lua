--#ENDPOINT POST /token
-- create a token for this user, given request body
-- {"email":"<email>", "password":"<password>"}

local ret = User.getUserToken({
	email = request.body.email,
	password = request.body.password
})
if ret ~= nil and ret.status_code ~= nil then
	-- fail. respond with the status_code and message
	response.code = ret.status_code
	response.message = ret.message
else
	-- pass
	response.code = 200
	-- put the token in a session ID cookie, for browsers
	response.headers = {
		["Set-Cookie"] = "sid=" .. tostring(ret)
	}
	-- ...and in the response body, for native mobile apps,
	-- external servers, tools, etc.

  local user = User.getCurrentUser({token = ret})
  if user ~= nil and user.id ~= nil then
		user.token = ret
		response.message = user
	else
		response.code = user.status
		response.message = user
	end
end

--#ENDPOINT GET /user/lock/
-- Get the state of all the locks a given user
-- can access.
local user = util.currentUser(request)
if user ~= nil and user.id ~= nil then
	locks = util.getUserAccessibleItems(user.id, 'lockID')
  return locks
else
	response.code = 400
	response.message = "Token invalid"
end

--#ENDPOINT GET /user/dwelling/
-- Get the state of all the dwellings a given user
-- can access.
local user = util.currentUser(request)
if user ~= nil and user.id ~= nil then
	locks = util.getUserAccessibleItems(user.id, 'dwellingID')
  return locks
else
	response.code = 400
	response.message = "Token invalid"
end

--#ENDPOINT POST /lock/{lockID}
-- This is a public endpoint
-- send lock-command to a particular lock
local pid = Config.solution().products[1]
local rid = Device.list({pid=pid})[1]['rid']

local r = Device.write({
  pid=pid, 
  device_sn=request.parameters.lockID, 
  ['lock-command']=request.body['lock-command']
})

return r

--#ENDPOINT GET /lock/

-- get all the locks. This illustrates a public endpoint 
-- with no authentication and therefore no associated user

-- assume only only one product associated with
-- this solution.
local pid = Config.solution().products[1]

-- get the list of devices for this product
local devices = Device.list({pid=pid})
local response = {}
for k, device in pairs(devices) do
	device.state = util.getStates('lockID', device.sn)
	-- this is deprecated
	device.rid = nil
	-- for consistency, match output of getUserAccessibleItems
	device.lockID = device.sn
	device.sn = nil
	-- ...except role_id, which doesn't make sense here
	
	table.insert(response, device)
end
return devices

--#ENDPOINT WEBSOCKET /notify
-- subscribe for notifications when devices change
response.message = {
	status = 'ok'
}

--#ENDPOINT GET /_init
-- This endpoint is called when the solution is first created.
-- For demonstration it creates some sample users, roles,
-- and device permissions

-- collect results in a table for debugging
local t = {}

-- create sample users
table.insert(t, User.activateUser({
	code=User.createUser({
		name="judy",
		email="judy@exosite.com",
		password="judy-password1"
	})
}))
table.insert(t, User.activateUser({
	code=User.createUser({
		name="frank",
		email="frank@exosite.com",
		password="frank-password1"
	})
}))

-- create initial lock states
table.insert(t, util.setStates('lockID', '001', { 'name', 'Home' }))
table.insert(t, util.setStates('lockID', '002', { 'name', 'Studio' }))

-- get user ids
local users = User.listUsers()
local judy = users[1]
local frank = users[2]

-- create roles
table.insert(t, User.createRole({
	role_id='owner',
	parameter={
		{ name = 'lockID'},
		{ name = 'dwellingID'}
	}
}))
table.insert(t, User.createRole({
	role_id='guest',
	parameter={
		{ name='lockID'}
	}
}))

-- assign roles to users (including parameters
-- for the role's permissions)
table.insert(t, User.assignUser({
	id = judy.id,
	roles = {
		{
			role_id = 'owner',
			parameters = {
				{
					name = 'lockID',
					value = '001' 
				},
				{
					name = 'lockID',
					value = '002' 
				},
				{
					name = 'dwellingID',
					value = '1'
				}			
			}
		}		
	}
}))

-- frank gets guest access to lock 001
table.insert(t, User.assignUser({
	id = frank.id,
	roles = {
		{
			role_id = 'guest',
			parameters = {
				{
					name = 'lockID',
					value = '001' 
				}
			}
		}		
	}
}))

-- dump out the results
table.insert(t, users)
table.insert(t, User.listRoles())
table.insert(t, User.listUserRoles({
	id=judy.id
}))
table.insert(t, User.listUserRoles({
	id=frank.id
}))

-- this should be true
table.insert(t, "tests (every other line below should be 'OK')")
-- expect ok (judy has access to lock 001)
table.insert(t, User.hasUserRoleParam({
	id = judy.id, role_id = 'owner', parameter_name = 'lockID', parameter_value = '001'
}))
-- expect error (frank is not owner of lock 001)
table.insert(t, User.hasUserRoleParam({
	id = frank.id, role_id = 'owner', parameter_name = 'lockID', parameter_value = '001'
}))
-- expect ok (judy has access to lock 002)
table.insert(t, User.hasUserRoleParam({
	id = judy.id, role_id = 'owner', parameter_name = 'lockID', parameter_value = '002'
}))
-- expect error (judy does not have access to lock 999)
table.insert(t, User.hasUserRoleParam({
	id = judy.id, role_id = 'owner', parameter_name = 'lockID', parameter_value = '999'
}))
-- expect "OK" (frank has guest access to lock 001)
table.insert(t, User.hasUserRoleParam({
	id = frank.id, role_id = 'guest', parameter_name = 'lockID', parameter_value = '001'
}))
-- expect error (frank has no dwellingID param)
table.insert(t, User.hasUserRoleParam({
	id = frank.id, role_id = 'guest', parameter_name = 'dwellingID', parameter_value = 1
}))
-- expect "OK"
table.insert(t, User.hasUserRoleParam({
	id = judy.id, role_id = 'owner', parameter_name = 'dwellingID', parameter_value = 1
}))
-- expect error
table.insert(t, User.hasUserRoleParam({
	id = judy.id, role_id = 'owner', parameter_name = 'dwellingID', parameter_value = 2
}))

return t


