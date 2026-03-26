local HPBarSystem = {}

HPBarSystem.bgId = nil
HPBarSystem.fillId = nil
HPBarSystem.textId = nil
HPBarSystem.maxWidth = 260
HPBarSystem.height = 24
HPBarSystem.lastHP = -1
HPBarSystem.lastMax = -1

local function ensureUI()
    if HPBarSystem.bgId and HPBarSystem.fillId and HPBarSystem.textId then
        return
    end

    local x = 24
    local y = 64
    HPBarSystem.bgId = ECS.createRect(x, y, HPBarSystem.maxWidth, HPBarSystem.height, 0.12, 0.12, 0.12, 0.82, 70)
    HPBarSystem.fillId = ECS.createRect(x + 2, y + 2, HPBarSystem.maxWidth - 4, HPBarSystem.height - 4, 0.2, 0.85, 0.2, 0.95, 71)
    HPBarSystem.textId = ECS.createUIText("HP: 100/100", x + 6, y + 2, 16, 1.0, 1.0, 1.0, 72)
end

local function getLocalPlayerLife()
    -- Prefer explicitly local player in network mode.
    if ECS.capabilities.hasNetworkSync and _G.NetworkSystem and _G.NetworkSystem.myServerId and _G.NetworkSystem.serverEntities then
        local localId = _G.NetworkSystem.serverEntities[_G.NetworkSystem.myServerId]
        if localId and ECS.hasComponent(localId, "Life") then
            local life = ECS.getComponent(localId, "Life")
            if life then
                return life.amount or 0, life.max or 100
            end
        end
    end

    local players = ECS.getEntitiesWith({"Player", "Life"})
    if #players > 0 then
        local life = ECS.getComponent(players[1], "Life")
        if life then
            return life.amount or 0, life.max or 100
        end
    end

    return nil, nil
end

local function hpColor(ratio)
    if ratio > 0.6 then return 0.2, 0.85, 0.2 end
    if ratio > 0.3 then return 0.95, 0.75, 0.15 end
    return 0.9, 0.2, 0.2
end

function HPBarSystem.init()
    print("[HPBarSystem] Initialized")
end

function HPBarSystem.update(dt)
    if not ECS.capabilities.hasRendering then return end
    if not ECS.isGameRunning then return end

    ensureUI()

    local hp, maxHp = getLocalPlayerLife()
    if hp == nil or maxHp == nil then
        return
    end

    hp = math.max(0, hp)
    maxHp = math.max(1, maxHp)

    if hp == HPBarSystem.lastHP and maxHp == HPBarSystem.lastMax then
        return
    end

    HPBarSystem.lastHP = hp
    HPBarSystem.lastMax = maxHp

    local ratio = math.max(0, math.min(1, hp / maxHp))
    local fillW = math.max(2, (HPBarSystem.maxWidth - 4) * ratio)
    local r, g, b = hpColor(ratio)

    ECS.setRect(HPBarSystem.fillId, 26, 66, fillW, HPBarSystem.height - 4)
    ECS.setUIColor(HPBarSystem.fillId, r, g, b)
    ECS.setUIText(HPBarSystem.textId, "HP: " .. tostring(math.floor(hp)) .. "/" .. tostring(maxHp))
end

ECS.registerSystem(HPBarSystem)
return HPBarSystem
