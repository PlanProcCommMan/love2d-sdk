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
    sdk.chunks = {}
    sdk.server_to_client = nil
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
                if sdk.server_to_client ~= nil then
                    sdk.server_to_client(json.decode(e))
                end
            end
            if k == "Chunk" then
               e.Data = json.decode(e.Data)
               sdk.chunks[e.ID] = e
               local remove = {}
               for k,v in pairs(sdk.chunks) do
                   if math.abs(v.X-e.X) > 3 or math.abs(v.Y-e.Y) > 3 then
                       remove[k] = true
                   end
               end
               for k,_ in pairs(remove) do
                   sdk.chunks[k] = nil
               end
            end
        end
    end
    if not sdk.thread:isRunning() and sdk.creds then
        sdk.init(sdk.creds.gameid, sdk.creds.username, sdk.creds.password) 
        sdk.join()
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
  sdk.uuid = nil
  sdk.entities = {}
end

function sdk.message(msg)
    local s = json.encode(msg)
    sdk.inp:push({Arbitrary = s})
end

return sdk
