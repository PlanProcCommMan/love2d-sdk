local json = require "sdk.json"

local sdk = {}

function sdk.init(gameid, username, password)
  sdk.creds = {gameid=gameid, username=username, password=password}
  sdk.thread = love.thread.newThread("sdk/thread.lua")
  sdk.out = love.thread.getChannel("out")
  sdk.inp = love.thread.getChannel("in")
  sdk.thread:start(gameid, username, password)
  sdk.entities = {}
  sdk.inp:push({Move={X=0, Y=0}})
  sdk.uuid = sdk.out:demand().UUID
end

function sdk.update()
  while true do
    local x = sdk.out:pop()
    if not x then break end
    for k,e in pairs(x) do
      if k == "Update" then
        sdk.entities[e.EntityID] = e
      end
      if k == "Delete" then
        sdk.entities[e.EntityID] = nil
      end
      if k == "Event" and e ~= "" then
        sdk.event(json.decode(e))
      end
    end
  end
  if not sdk.thread:isRunning() then
    local msg = {x=0, y=0}
    if sdk.entities[sdk.uuid] then
      msg.x, msg.y = sdk.entities[sdk.uuid].X, sdk.entities[sdk.uuid].Y
    end
    sdk.init(sdk.creds.gameid, sdk.creds.username, sdk.creds.password)
    sdk.inp:push(msg)
  end
end

function sdk.move(dx, dy)
  sdk.inp:push({Move={X=dx, Y=dy}})
end

function sdk.message(msg)
  local s = json.encode(msg)
  sdk.inp:push({Arbitrary=s})
end

function sdk.event(event)
end

return sdk
