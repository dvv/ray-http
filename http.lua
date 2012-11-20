local net = require('ray.net')
local fiber = require('ray.fiber')
local http_parser = require('ray.http.parser')
local p = require('ray.utils').prettyPrint

local http = { }

function http.create_server(handler, port, host, backlog)

  port = port or 8080
  host = host or '127.0.0.1'

  local server = net.tcp()
  print('SERVER:', server)
  server:bind(host, port)
  server:listen(backlog)

  while not server.done do
    print('ACCEPT LOOP TOP')

    -- accept client
    local client = net.tcp()
    local rc = server:accept(client) -- block here
    if not rc then
      handler(client, 'error', 'accept')
      -- continue?!
    end

    -- setup client reader
    fiber.create(function(client)
      print('CHILD')
      local request = { }
      -- setup http parser
      local parser
      parser = http_parser.request({
        on_message_begin = function()
          print('MSGBEGIN')
          request = { }
          request.client = client
          request.headers = { }
        end,
        on_url = function(url)
          print('URL', url)
          request.url = url
          -- TODO: parse url
        end,
        on_header = function(hkey, hval)
          print('HEADER', hkey, hval)
          request.headers[hkey:lower()] = hval
        end,
        on_headers_complete = function()
          print('HDRDONE')
          request.method = parser:method()
          request.upgrade = parser:is_upgrade()
          request.should_keep_alive = parser:should_keep_alive()
        end,
        on_body = function(chunk)
          print('BODY', chunk)
          if chunk ~= nil then
            handler(request, 'data', chunk)
          else
            print('MSGEND')
            --p(request)
            handler(request, 'end')
          end
        end,
        on_message_complete = function()
          print('MSGDONE')
          -- next request on same client expected?
          if request.should_keep_alive then
            -- reset parser
            parser:reset()
          -- connection should be closed
          else
            client:shutdown()
            client:close()
          end
        end
      })
      -- feed client data to http parser
      while true do
        p('READ LOOP TOP', client:readable(), client:writable())
        local nread, chunk = client:read()
        print('READ:', nread, chunk)
        if nread then
          local nparsed = parser:execute(chunk)
          -- parsed not the whole chunk?
          if nparsed < nread then
            -- pass unparsed data verbatim in case of upgrade mode
            if request.upgrade then
              handler(request, 'data', chunk:sub(nparsed + 1))
            -- report parse error unless upgrade mode
            else
              handler(request, 'error', 'parse error')
              -- and close the client
              client:close()
            end
          end
        else
          --print('CLOSING')
          -- read error?
          --if nread == false then
            -- report error
            --handler(request, 'error', 'short read', nread)
            handler(request, 'error', 'short read', chunk)
            -- and close the client
            client:close()
          --end
          break
        end
      end
    end, client):ready()
  end

  return server

end

-- export
return http
