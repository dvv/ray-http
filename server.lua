pcall(require, 'luarocks.loader') -- honor luarocks search path
local fiber = require('ray.fiber')
local http = require('ray.http')

local function p(x)
  for k, v in pairs(x) do
    print(k, v)
  end
end

local function handler(req, event, ...)
  print(req, event, ...)
  if event ~= 'end' then return end
  local response = ("Hello World!\n") --:rep(1000)
  local rc
  if req.should_keep_alive then
    rc = req.client:write("HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nContent-Length: " .. #response .. "\r\n\r\n" .. response)
  else
    rc = req.client:write("HTTP/1.0 200 OK\r\nConnection: close\r\nContent-Length: " .. #response .. "\r\n\r\n" .. response)
  end
  if rc < 0 then
    print("WRITE ERR:", rc)
  end
end

local main = fiber.create(function()
  local server = http.create_server(handler, 8080, '0.0.0.0', 32768)
end):ready()

print('HTTP server listening to http://0.0.0.0:8080/. Hit CTRL+C to exit.')
main:join()
