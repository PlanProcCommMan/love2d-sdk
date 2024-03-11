require "love.timer"

local gid,un,pw = ...

local luapb = require("sdk.luapb.luapb")
local socket = require("socket")
local base64 = require("sdk.base64")
local rc4 = require("sdk.rc4")
local json = require("sdk.json")
local https = require("https")

local out = love.thread.getChannel("out")
local inp = love.thread.getChannel("in")
local kill = love.thread.getChannel("kill")

opts = {data=json.encode({GameID=tonumber(gid), Username=un, Password=pw})}
code, body, _ = https.request("https://api.planetaryprocessing.io//_api/golang.planetaryprocessing.io/apis/httputils/HTTPUtils/GetKey", opts)
if code ~= 200 then
  print("failed to authenticate")
  out:push("")
  return
end
resp = json.decode(body)
uuid = resp.UUID
key = base64.decode(resp.Key)
local rc4in = rc4(key)
local rc4out = rc4(key)

local loginproto = {
  [1]={type="string", name="Token"},
  [2]={type="uint64", name="GameID"},
  [3]={type="string", name="UUID"},
  [4]={type="string", name="Email"},
  [5]={type="string", name="Password"}
}

local packetproto = {
  [1]={type="proto", name="Move", proto={
    [1]={type="double", name="X"},
    [2]={type="double", name="Y"},
    [3]={type="double", name="Z"}
  }},
  [2]={type="proto", name="Update", proto={
    [1]={type="string", name="EntityID"},
    [2]={type="double", name="X"},
    [3]={type="double", name="Y"},
    [4]={type="double", name="Z"},
    [5]={type="string", name="Data"},
    [6]={type="string", name="Type"}
  }},
  [3]={type="proto", name="Delete", proto={
    [1]={type="string", name="EntityID"}
  }},
  [4]={type="bool", name="Leave"},
  [5]={type="string", name="Arbitrary"},
  [6]={type="string", name="Event"}
}

s = socket.tcp()
i, _ = s:connect("planetaryprocessing.io", 42)
if i ~= 1 then
  print("failed connection")
  out:push("")
  return
end

_,err,_ = s:send(base64.encode(luapb.serialise({UUID=uuid, GameID=tonumber(gid)}, loginproto)).."\n")
if err then
  print(err)
  out:push("")
  return
end

res,err,_ = s:receive("*l")
if err then
  print(err)
  out:push("")
  return
end

out:push(luapb.deserialise(base64.decode(res), loginproto))

s:settimeout(0.05)

local tmp = ""

while true do
  res,err,_ = s:receive("*l")
  if err then
    if err ~= "timeout" then
      print(err)
      return
    end
  else
    ok, bts = pcall(base64.decode, res)
    if ok then
      bts = rc4in(bts)
      ok, msg = pcall(luapb.deserialise, bts, packetproto)
      if ok then
        out:push(msg)
      end
    end
  end
  msg = inp:pop()
  if msg then
    local d = base64.encode(rc4out(luapb.serialise(msg, packetproto)))
    --print(d)
    s:send(d.."\n")
  end
  msg = kill:pop()
  if msg then
    s:close()
  end
end
