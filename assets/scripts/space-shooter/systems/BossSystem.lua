local Spawns = dofile("assets/scripts/space-shooter/spawns.lua")

local BossSystem = {
    spawned = false,
    defeated = false,
    spawnScoreThreshold = 1400
}

local function getGlobalScore()
    local scoreEntities = ECS.getEntitiesWith({"Score"})
    if #scoreEntities == 0 then return 0 end
    local score = ECS.getComponent(scoreEntities[1], "Score")
    return (score and score.value) or 0
end

local function hasBossEntity()
    local bosses = ECS.getEntitiesWith({"Boss", "Life", "Transform"})
    return #bosses > 0, bosses
end

local function spawnBossIfNeeded()
    if BossSystem.spawned or BossSystem.defeated then return end
    local currentLevel = _G.CurrentLevel or 1
    if currentLevel < 2 then return end

    if getGlobalScore() >= BossSystem.spawnScoreThreshold then
        Spawns.spawnBoss(16, 0, 0)
        BossSystem.spawned = true
        print("[BossSystem] Boss spawned for level 2")
    end
end

local function updateBossPattern(bossId, dt)
    local boss = ECS.getComponent(bossId, "Boss")
    local transform = ECS.getComponent(bossId, "Transform")
    local phys = ECS.getComponent(bossId, "Physic")
    local life = ECS.getComponent(bossId, "Life")
    if not boss or not transform or not phys or not life then return end

    boss.attackTimer = (boss.attackTimer or 0) + dt
    boss.moveTimer = (boss.moveTimer or 0) + dt

    if life.amount <= life.max * 0.5 then
        boss.phase = 2
    end

    phys.vx = (transform.x > 10) and -1.8 or 0
    phys.vy = math.sin(boss.moveTimer * (boss.phase == 1 and 1.5 or 2.5)) * (boss.phase == 1 and 1.8 or 3.2)

    local attackInterval = (boss.phase == 1) and 1.2 or 0.7
    if boss.attackTimer >= attackInterval then
        boss.attackTimer = 0
        Spawns.spawnBullet(transform.x - 1.5, transform.y, transform.z, true)
        if boss.phase == 2 then
            Spawns.spawnBullet(transform.x - 1.5, transform.y + 0.6, transform.z, true)
            Spawns.spawnBullet(transform.x - 1.5, transform.y - 0.6, transform.z, true)
        end
    end

    ECS.addComponent(bossId, "Boss", boss)
    ECS.addComponent(bossId, "Physic", phys)
end

function BossSystem.init()
    print("[BossSystem] Initialized")
end

function BossSystem.update(dt)
    if ECS.isPaused then return end
    if not ECS.capabilities.hasAuthority then return end
    if not ECS.isGameRunning then return end

    spawnBossIfNeeded()

    local hasBoss, bosses = hasBossEntity()
    if not hasBoss then
        if BossSystem.spawned and not BossSystem.defeated then
            BossSystem.defeated = true
            ECS.broadcastNetworkMessage("GAME_WON", "boss_defeated")
            ECS.sendMessage("GAME_WON", "boss_defeated")
            print("[BossSystem] Boss defeated, game won")
        end
        return
    end

    for _, id in ipairs(bosses) do
        updateBossPattern(id, dt)
    end
end

ECS.registerSystem(BossSystem)
return BossSystem
