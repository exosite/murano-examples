--#ENDPOINT GET /lock/
-- get the state of all the locks
local pid = Config.solution().products[1]
-- Get the list of devices for this product
local devices = Device.list({pid=pid})
local response = {}
for k, device in pairs(devices) do
	table.insert(response, device)
end
return response

--#ENDPOINT GET /setup

-- collect results in a table for debugging
local t = {}

-- create sample endpoint permissions
table.insert(t, User.createPermission({
	method="GET",
	end_point="/lock/{lockID}"
}))
table.insert(t, User.createPermission({
	method="GET",
	end_point="/dwelling/{dwellingID}"
}))


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


-- create roles
table.insert(t, User.deleteRole({role_id="owner"}))
table.insert(t, User.deleteRole({role_id="guest"}))

table.insert(t, User.createRole({
	role_id='owner',
	parameter={
		{ name='lockID'},
		{ name = 'dwellingID'},
	}
}))
table.insert(t, User.createRole({
	role_id='guest',
	parameter={
		{ name='lockID'}
	}
}))

-- associate permission
table.insert(t, User.addRolePerm({
	role_id = 'owner',
	body = {
		{ method = 'GET', end_point = '/lock/{lockID}' },
		{ method = 'GET', end_point = '/dwelling/{dwellingID}' }
	}
}))
table.insert(t, User.addRolePerm({
	role_id = 'guest',
	body = {
		-- guest may only be assigned specific locks, 
		-- not dwelling-wide access
		{ method = 'GET', end_point = '/lock/{lockID}' }
	}
}))

-- assign roles to users (including parameters
-- for the role's permissions)
table.insert(t, User.assignUser({
	id = 3,
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
					value = 1
				}			
			}
		}		
	}
}))

-- frank gets guest access to lock 001
table.insert(t, User.assignUser({
	id = 4, -- frank
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
table.insert(t, User.listUsers())
table.insert(t, User.listPerms())
table.insert(t, User.listRoles())
table.insert(t, User.listUserRoles({
	id=3
}))
table.insert(t, User.listUserRoles({
	id=4
}))

-- check permissions
-- this one should be true
table.insert(t, User.hasUserPerm({
	id = 3,
	perm_id = 'GET%2Flock%2F%7BlockID%7D', -- urlencode('GET/lock/{lockID}'),
	parameters = { 'lockID::001' }
}))
-- this one should be false (no dwelling 3)
table.insert(t, User.hasUserPerm({
	id = 3,
	perm_id = 'GET%2Fdwelling%2F%7BdwellingID%7D', -- urlencode('GET/dwelling/{dwellingID}'),
	parameters = { 'dwellingID::3' }
}))
-- this one should be false (user 4 has no permissions to lock 001)
table.insert(t, User.hasUserPerm({
	id = 4,
	perm_id = 'GET%2Flock%2F%7BlockID%7D', -- urlencode('GET/lock/{lockID}'),
	parameters = { 'lockID::001' }
}))

return t

--#ENDPOINT GET /test
local r = User.createPermission({
	method='GET',
  end_point='info/{sn}'
})
local t = User.listPerms()
table.insert(t, r)
return t

--#ENDPOINT POST /lock/{sn}
-- control a particular lock
local pid = Config.solution().products[1]
local rid = Device.list({pid=pid})[1]['rid']

local r = Device.write({
  pid=pid, 
  device_sn=request.parameters.sn, 
  ['lock-command']=request.body['lock-command']
})

return rid

--#ENDPOINT PUT /user/{email}
local newUser = {
  email = request.parameters.email,
  name = request.parameters.email,
  password = request.body.password
}
local ret = User.createUser(newUser)
if ret.status_code ~= nil then
  response.code = ret.status_code
  response.message = ret.message
else
  local ret = User.activateUser({code = request.parameters.code})
  if ret == 'OK' then
    response.code = 200
    response.message = newUser
  else
    response.code = ret.status_code
    response.message = ret.message
  end
end
