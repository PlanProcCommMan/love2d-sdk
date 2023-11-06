local json = require "sdk.json"

local sdk = {}

function sdk.init(gameid, username, password)
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
        sdk.msg(json.decode(e))
      end
    end
  end
  if not sdk.thread:isRunning() then
    love.event.quit()
  end
end

function sdk.move(dx, dy)
  sdk.inp:push({Move={X=dx, Y=dy}})
end

function sdk.message(msg)
  local s = json.encode(msg)
  sdk.inp:push({Arbitrary=s})
end

function sdk.onevent(event)
end

return sdk
