local Spawns = dofile("assets/scripts/space-shooter/spawns.lua")

local PowerUpSystem = {
    spawnTimer = 0,
    spawnInterval = 14.0,
    powerUpTypes = {"RAPID", "SPREAD"}
}

local function randomPowerType()
    local idx = math.random(1, #PowerUpSystem.powerUpTypes)
    return PowerUpSystem.powerUpTypes[idx]
end

function PowerUpSystem.init()
    print("[PowerUpSystem] Initialized")
end

function PowerUpSystem.applyPowerUp(playerId, powerType, duration)
    local weapon = ECS.getComponent(playerId, "Weapon")
    local profile = ECS.getComponent(playerId, "WeaponProfile")
    if not weapon then return end

    if not profile then
        profile = WeaponProfile("STANDARD", weapon.cooldown or 0.2)
    end

    local buffDuration = duration or 8.0
    local now = os.clock()

    if powerType == "RAPID" then
        weapon.cooldown = 0.12
        profile.weaponType = "STANDARD"
    elseif powerType == "SPREAD" then
        weapon.cooldown = 0.22
        profile.weaponType = "SPREAD"
    end

    profile.bonusUntil = now + buffDuration
    ECS.addComponent(playerId, "Weapon", weapon)
    ECS.addComponent(playerId, "WeaponProfile", profile)
    ECS.addComponent(playerId, "PowerUp", { timeRemaining = buffDuration, originalCooldown = profile.baseCooldown, powerType = powerType })
end

function PowerUpSystem.update(dt)
    if ECS.isPaused then return end
    if not ECS.capabilities.hasAuthority then return end
    if not ECS.isGameRunning then return end

    PowerUpSystem.spawnTimer = PowerUpSystem.spawnTimer + dt
    if PowerUpSystem.spawnTimer >= PowerUpSystem.spawnInterval then
        PowerUpSystem.spawnTimer = 0
        Spawns.spawnPowerUp(20, math.random(-6, 6), 0, randomPowerType())
    end

    local poweredPlayers = ECS.getEntitiesWith({"Player", "PowerUp", "Weapon", "WeaponProfile"})
    for _, id in ipairs(poweredPlayers) do
        local power = ECS.getComponent(id, "PowerUp")
        local weapon = ECS.getComponent(id, "Weapon")
        local profile = ECS.getComponent(id, "WeaponProfile")

        power.timeRemaining = (power.timeRemaining or 0) - dt
        if power.timeRemaining <= 0 then
            weapon.cooldown = profile.baseCooldown or 0.2
            profile.weaponType = "STANDARD"
            ECS.removeComponent(id, "PowerUp")
        else
            ECS.addComponent(id, "PowerUp", power)
        end
    end

    local powerUps = ECS.getEntitiesWith({"Bonus", "Transform"})
    for _, id in ipairs(powerUps) do
        local t = ECS.getComponent(id, "Transform")
        if t and t.x < -18 then
            ECS.destroyEntity(id)
        end
    end
end

ECS.registerSystem(PowerUpSystem)
return PowerUpSystem
