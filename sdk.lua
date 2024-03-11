local json = require "sdk.json"

local sdk = {}

function sdk.init(gameid, username, password)
    sdk.creds = {gameid = gameid, username = username, password = password}
    sdk.thread = love.thread.newThread("sdk/thread.lua")
    sdk.out = love.thread.getChannel("out")
    sdk.inp = love.thread.getChannel("in")
    sdk.kil = love.thread.getChannel("kill")
    sdk.thread:start(gameid, username, password)
    sdk.entities = {}
--    sdk.inp:push({Move = {X = 0, Y = 0}})
    local initResult = sdk.out:demand()
    sdk.uuid = initResult.UUID
end

function sdk.update()
    while true do
        local x = sdk.out:pop()
        if not x then break end
        for k, e in pairs(x) do
            if k == "Update" then
                e.Data = json.decode(e.Data)
                sdk.entities[e.EntityID] = e
            end
            if k == "Delete" then sdk.entities[e.EntityID] = nil end
            if k == "Event" and e ~= "" then
                sdk.event(json.decode(e))
            end
        end
    end
end

function sdk.join()
  sdk.inp:push({Move={X=0, Y=0}})
end

function sdk.leave()
  sdk.inp:push({Leave=true})
end

function sdk.quit()
  sdk.creds = nil
  sdk.kil:push({})
  sdk.uuid = ""
  sdk.entities = {}
end

function sdk.move(dx, dy) sdk.inp:push({Move = {X = dx, Y = dy}}) end

function sdk.message(msg)
    local s = json.encode(msg)
    sdk.inp:push({Arbitrary = s})
end

function sdk.event(event) end

return sdk
