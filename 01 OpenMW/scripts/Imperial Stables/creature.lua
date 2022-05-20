local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')

local events = require('scripts.Imperial Stables.common').events

local followingPlayers = {}
local stable = nil
local minDistance = 50

local function filter(t, callback)
    local result = {}
    for k, v in pairs(t) do
        if callback(k, v) then
            result[k] = v
        end
    end
    return result
end

local function map(t, callback)
    local result = {}
    for k, v in pairs(t) do
        local newK, newV = callback(k, v)
        result[newK] = newV
    end
    return result
end

local function notifyPlayer(player, status)
    player:sendEvent(events.FollowerStatus, {
        actor = self.object,
        status = status,
    })
end

local function isDead()
    local health = self.type.stats.dynamic.health(self)
    return health.current == 0
end

local function moveToStable()
    local activeAI = I.AI.getActivePackage()
    if activeAI
        and (activeAI.type == 'Travel')
        and (activeAI.position == stable.position)
    then
        return
    end
    I.AI.filterPackages(function() return false end)
    I.AI.startPackage {
        type = 'Travel',
        destPosition = stable.position,
    }
end

local function stayAtStable()
    local activeAI = I.AI.getActivePackage()
    if activeAI and activeAI.type == 'Wander' then
        return
    end
    I.AI.filterPackages(function() return false end)
    I.AI.startPackage {
        type = 'Wander',
        distance = 0,
    }
end

local function follow(actor)
    I.AI.filterPackages(function() return false end)
    I.AI.startPackage {
        type = 'Follow',
        target = actor,
    }
end

local function isAtStable()
    if not stable:isValid() then return true end
    if (self.position - stable.position):length() < minDistance then return true end
end

local function updateFollowedPlayers()
    local playerTargets = map(
        filter(I.AI.getTargets('Follow'), function(_,target)
            return target and target.type == types.Player and target:isValid()
        end),
        function(_, target)
            return tostring(target), target
        end
    )
    local newPlayers = filter(playerTargets, function(k)
        return not followingPlayers[k]
    end)
    local removedPlayers = filter(followingPlayers, function(k)
        return not playerTargets[k]
    end)
    for _, player in pairs(removedPlayers) do
        followingPlayers[tostring(player)] = nil
        notifyPlayer(player, false)
    end
    for _, player in pairs(newPlayers) do
        followingPlayers[tostring(player)] = player
        notifyPlayer(player, true)
    end
end

return {
    engineHandlers = {
        onUpdate = function()
            if #followingPlayers > 0 and isDead() then
                print('creature dead')
                for _, player in pairs(followingPlayers) do
                    notifyPlayer(player, false)
                end
                followingPlayers = {}
            end
            if stable then
                if isAtStable() then
                    stayAtStable()
                else
                    moveToStable()
                end
            end
            updateFollowedPlayers()
        end,
        onSave = function()
            return { stable = stable }
        end,
        onLoad = function(saved)
            stable = saved.stable
        end,
    },
    eventHandlers = {
        [events.Housed] = function(e)
            print('creature housed')
            stable = e.stable
            moveToStable()
        end,
        [events.Release] = function(e)
            print('creature release')
            stable = nil
            follow(e.actor)
        end,
    },
}