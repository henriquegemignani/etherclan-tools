module ('chat', package.seeall) do

  require 'etherclan.database'
  require 'etherclan.server'
  local socket = require 'socket'

  local db
  local server

  local inc = 0.0
  local previous_messages = {}
  local prompt_cursor = 1
  local prompt_message_cache = "> "
  local prompt_message = {}

  local text_height = 10

  function update_prompt_cache()
    prompt_message_cache = "> " .. table.concat(prompt_message)
  end

  function send_message(msg)
    table.insert(previous_messages, 1, "You: " .. msg)
    for _, node in pairs(db.known_nodes) do
      if node.services.chat then
        local s = socket.tcp()
        if s:connect(node.ip, node.port) then
          s:send("SERVICE CHAT " .. msg .. "\n")
          s:close()
        end
      end
    end
  end

  function love.load (args)
    --love.graphics.setMode(800, 400, false, false, 0)
    love.graphics.setNewFont(18)
    text_height = love.graphics.getFont():getHeight()

    db = etherclan.database.create()
    db:add_node{ uuid = "??", ip = "localhost", port = 8001 }

    server = etherclan.server.create(db, 0.01)
    server:start()
    function server.node.services.chat(self, msg)
      table.insert(previous_messages, 1, self.ip .. ": " .. msg)
    end
  end

  function love.update (dt)
    inc = inc + dt
    if inc > 10.0 then
      inc = 0.0
    end

    server:step()
  end

  function love.keypressed (button)
    if button == "escape" then
      love.event.push "quit"

    elseif button == "end" then
      server:create_new_out_connections()

    elseif button == 'return' then
      if #prompt_message == 0 then return end
      send_message(table.concat(prompt_message))

      prompt_message = {}
      prompt_cursor = 1
      update_prompt_cache()

    elseif button == 'left' then
      if prompt_cursor > 1 then
        prompt_cursor = prompt_cursor - 1
      end

    elseif button == 'right' then
      if prompt_cursor <= #prompt_message then
        prompt_cursor = prompt_cursor + 1
      end

    elseif button == 'backspace' then
      if prompt_cursor > 1 then
        table.remove(prompt_message, prompt_cursor - 1)
        prompt_cursor = prompt_cursor - 1
        update_prompt_cache()
      end

    elseif button == 'delete' then
      if prompt_cursor <= #prompt_message then
        table.remove(prompt_message, prompt_cursor)
        update_prompt_cache()
      end

    elseif #button == 1 then
      table.insert(prompt_message, prompt_cursor, button)
      prompt_cursor = prompt_cursor + 1
      update_prompt_cache()

    end
  end

  function love.keyreleased (button)
  end

  function love.mousepressed (x, y, button)
  end

  function love.mousereleased (x, y, button)
  end

  function love.draw ()
    local y = love.graphics.getHeight() - text_height
    love.graphics.print(prompt_message_cache, 0, y)

    local before_cursor = prompt_message_cache:sub(0, prompt_cursor + 1)
    local before_size = love.graphics.getFont():getWidth(before_cursor)
    local box_size = (prompt_cursor <= #prompt_message) 
                      and love.graphics.getFont():getWidth(prompt_message[prompt_cursor])
                      or 10

    love.graphics.setColor(0, 255, 0, 127)
    love.graphics.rectangle('fill', before_size, y, 10, text_height)
    love.graphics.setColor(255, 255, 255, 255)

    for _, msg in ipairs(previous_messages) do
      y = y - text_height
      love.graphics.print(msg, 0, y)
    end
  end

end