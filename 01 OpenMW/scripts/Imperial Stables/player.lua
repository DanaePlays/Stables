local self = require('openmw.self')

local events = require('scripts.Imperial Stables.common').events

local followingCreatures = {}
local distance = 1000

return {
  eventHandlers = {
    [events.FollowerStatus] = function(e)
      print('player followerStatus')
      local index = nil
      for i, f in pairs(followingCreatures) do
        if f.actor == e.actor then
          index = i
          break
        end
      end
      if e.status and not index then
        table.insert(followingCreatures, e.actor)
      end
      if not e.status and index then
        table.remove(followingCreatures, index)
      end
    end,
    [events.Activated] = function(e)
      print('player activated')
      local creature = nil
      for _, c in ipairs(followingCreatures) do
        if (c.position - e.stable.position):length() < distance then
          creature = c
          break
        end
      end
      if creature then
        e.stable:sendEvent(events.House, {
          creature = creature,
          player = self.object,
        })
      end
    end,
  }
}