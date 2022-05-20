local self = require('openmw.self')

local common = require('scripts.Imperial Stables.common')
local events = common.events
local activatorIds = common.activatorIds
if not activatorIds[self.recordId] then return end

local types = require('openmw.types')

local housed = nil

return {
  engineHandlers = {
    onActivated = function(obj)
      print('stable onActivated')
      if housed then
        housed.creature:sendEvent(events.Release, {
          actor = housed.owner,
        })
        housed = nil
      else
        if obj.type == types.Player then
          obj:sendEvent(events.Activated, {
            stable = self.object,
          })
        end
      end
    end,
    onLoad = function(saved)
      if saved then
        housed = saved.housed
      end
    end,
    onSave = function()
      return { housed = housed }
    end,
  },
  eventHandlers = {
    [events.House] = function(e)
      print('stable house')
      if not housed then
        housed = {
          creature = e.creature,
          owner = e.player,
        }
        housed.creature:sendEvent(events.Housed, {
          stable = self.object,
        })
      end
    end,
  }
}