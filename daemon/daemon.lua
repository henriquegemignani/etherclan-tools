require 'etherclan.server'
require 'etherclan.database'

local db = etherclan.database.create()

local serv = etherclan.server.create(db, 1, 8001)
serv:start()
while true do
  serv:step()
end
serv:close()
