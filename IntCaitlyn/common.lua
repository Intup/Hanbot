--Common DevAIO. 
local pred = module.internal("pred");

local common = {}
-- Delay Functions Call
local delayedActions, delayedActionsExecuter = {}, nil
function common.DelayAction(func, delay, args) --delay in seconds
  if not delayedActionsExecuter then
    function delayedActionsExecuter()
      for t, funcs in pairs(delayedActions) do
        if t <= os.clock() then
          for i = 1, #funcs do
            local f = funcs[i]
            if f and f.func then
              f.func(unpack(f.args or {}))
            end
          end
          delayedActions[t] = nil
        end
      end
    end
    cb.add(cb.tick, delayedActionsExecuter)
  end
  local t = os.clock() + (delay or 0)
  if delayedActions[t] then
    delayedActions[t][#delayedActions[t] + 1] = {func = func, args = args}
  else
    delayedActions[t] = {{func = func, args = args}}
  end
end

local _intervalFunction
function common.SetInterval(userFunction, timeout, count, params)
  if not _intervalFunction then
    function _intervalFunction(userFunction, startTime, timeout, count, params)
      if userFunction(unpack(params or {})) ~= false and (not count or count > 1) then
        common.DelayAction(
          _intervalFunction,
          (timeout - (os.clock() - startTime - timeout)),
          {userFunction, startTime + timeout, timeout, count and (count - 1), params}
        )
      end
    end
  end
  common.DelayAction(_intervalFunction, timeout, {userFunction, os.clock(), timeout or 0, count, params})
end

-- Print Function
function common.print(msg, color)
  local color = color or 42
  console.set_color(color)
  print(msg)
  console.set_color(15)
end

-- Returns percent health of @obj or player
function common.GetPercentHealth(obj)
  local obj = obj or player
  return (obj.health / obj.maxHealth) * 100
end

-- Returns percent mana of @obj or player
function common.GetPercentMana(obj)
  local obj = obj or player
  return (obj.mana / obj.maxMana) * 100
end

-- Returns percent par (mana, energy, etc) of @obj or player
function common.GetPercentPar(obj)
  local obj = obj or player
  return (obj.par / obj.maxPar) * 100
end

function common.CheckBuff(obj, buffname)
  if obj then
    for i = 0, obj.buffManager.count - 1 do
      local buff = obj.buffManager:get(i)

      if buff and buff.valid and buff.name == buffname and buff.stacks == 1 then
        return true
      end
    end
  end
end
function common.CheckBuff2(obj, buffname)
  if obj then
    for i = 0, obj.buffManager.count - 1 do
      local buff = obj.buffManager:get(i)

      if buff and buff.valid and buff.name:find(buffname) and (buff.stacks > 0 or buff.stacks2 > 0) then
        return true
      end
    end
  end
end
function common.StartTime(obj, buffname)
  if obj then
    for i = 0, obj.buffManager.count - 1 do
      local buff = obj.buffManager:get(i)

      if buff and buff.valid and buff.name:find(buffname) and (buff.stacks > 0 or buff.stacks2 > 0) then
        return buff.startTime
      end
    end
  end
end
function common.EndTime(obj, buffname)
  if obj then
    for i = 0, obj.buffManager.count - 1 do
      local buff = obj.buffManager:get(i)

      if buff and buff.valid and buff.name:find(buffname) and (buff.stacks > 0 or buff.stacks2 > 0) then
        return buff.endTime
      end
    end
  end
end
-- Potato API >:c
function common.CountBuff(obj, buffname)
  if obj then
    for i = 0, obj.buffManager.count - 1 do
      local buff = obj.buffManager:get(i)

      if buff and buff.valid and buff.name == buffname and buff.stacks2 > 0 then
        return buff.stacks2
      end
    end
  end
  return 0
end
function common.CheckBuffType(obj, bufftype)
  if obj then
    for i = 0, obj.buffManager.count - 1 do
      local buff = obj.buffManager:get(i)
      if buff and buff.valid and buff.type == bufftype and (buff.stacks > 0 or buff.stacks2 > 0) then
        return true
      end
    end
  end
end
-- Returns @target health+shield

local yasuoShield = {100, 105, 110, 115, 120, 130, 140, 150, 165, 180, 200, 225, 255, 290, 330, 380, 440, 510}
function common.GetShieldedHealth(damageType, target)
  local shield = 0
  if damageType == "AD" then
    shield = target.physicalShield
  elseif damageType == "AP" then
    shield = target.magicalShield
  elseif damageType == "ALL" then
    shield = target.allShield
  end
  return target.health + shield
end

-- Returns total AD of @obj or player
function common.GetTotalAD(obj)
  local obj = obj or player
  return (obj.baseAttackDamage + obj.flatPhysicalDamageMod) * obj.percentPhysicalDamageMod
end

-- Returns bonus AD of @obj or player
function common.GetBonusAD(obj)
  local obj = obj or player
  return ((obj.baseAttackDamage + obj.flatPhysicalDamageMod) * obj.percentPhysicalDamageMod) - obj.baseAttackDamage
end

-- Returns total AP of @obj or player
function common.GetTotalAP(obj)
  local obj = obj or player
  return obj.flatMagicDamageMod * obj.percentMagicDamageMod
end

-- Returns physical damage multiplier on @target from @damageSource or player
function common.PhysicalReduction(target, damageSource)
  local damageSource = damageSource or player
  local armor =
    ((target.bonusArmor * damageSource.percentBonusArmorPenetration) + (target.armor - target.bonusArmor)) *
    damageSource.percentArmorPenetration
  local lethality =
    (damageSource.physicalLethality * .4) + ((damageSource.physicalLethality * .6) * (damageSource.levelRef / 18))
  return armor >= 0 and (100 / (100 + (armor - lethality))) or (2 - (100 / (100 - (armor - lethality))))
end

-- Returns magic damage multiplier on @target from @damageSource or player
function common.MagicReduction(target, damageSource)
  local damageSource = damageSource or player
  local magicResist = (target.spellBlock * damageSource.percentMagicPenetration) - damageSource.flatMagicPenetration
  return magicResist >= 0 and (100 / (100 + magicResist)) or (2 - (100 / (100 - magicResist)))
end

-- Returns damage reduction multiplier on @target from @damageSource or player
function common.DamageReduction(damageType, target, damageSource)
  local damageSource = damageSource or player
  local reduction = 1
  -- Ryan Fix Please ♥
  if damageType == "AD" then
  end
  if damageType == "AP" then
  end
  return reduction
end

-- Calculates AA damage on @target from @damageSource or player
function common.CalculateAADamage(target, damageSource)
  local damageSource = damageSource or player
  if target then
    return common.GetTotalAD(damageSource) * common.PhysicalReduction(target, damageSource)
  end
  return 0
end

-- Calculates physical damage on @target from @damageSource or player
function common.CalculatePhysicalDamage(target, damage, damageSource)
  local damageSource = damageSource or player
  if target then
    return (damage * common.PhysicalReduction(target, damageSource)) *
      common.DamageReduction("AD", target, damageSource)
  end
  return 0
end

-- Calculates magic damage on @target from @damageSource or player
function common.CalculateMagicDamage(target, damage, damageSource)
  local damageSource = damageSource or player
  if target then
    return (damage * common.MagicReduction(target, damageSource)) * common.DamageReduction("AP", target, damageSource)
  end
  return 0
end

-- Returns @target attack range (@target is optional; will consider @target boundingRadius into calculation)
function common.GetAARange(target)
  return player.attackRange + player.boundingRadius + (target and target.boundingRadius or 0)
end

-- Returns @obj predicted pos after @delay secs
function common.GetPredictedPos(obj, delay)
  if not common.IsValidTarget(obj) or not obj.path or not delay or not obj.moveSpeed then
    return obj
  end
  local pred_pos = pred.core.lerp(obj.path, network.latency + delay, obj.moveSpeed)
  return vec3(pred_pos.x, player.y, pred_pos.y)
end

-- Returns ignite damage
function common.GetIgniteDamage(target)
  local damage = 55 + (25 * player.levelRef)
  if target then
    damage = damage - (common.GetShieldedHealth("AD", target) - target.health)
  end
  return damage
end

common.enum = {}
common.enum.slots = {
  q = 0,
  w = 1,
  e = 2,
  r = 3
}
common.enum.buff_types = {
  Internal = 0,
  Aura = 1,
  CombatEnchancer = 2,
  CombatDehancer = 3,
  SpellShield = 4,
  Stun = 5,
  Invisibility = 6,
  Silence = 7,
  Taunt = 8,
  Polymorph = 9,
  Slow = 10,
  Snare = 11,
  Damage = 12,
  Heal = 13,
  Haste = 14,
  SpellImmunity = 15,
  PhysicalImmunity = 16,
  Invulnerability = 17,
  AttackSpeedSlow = 18,
  NearSight = 19,
  Currency = 20,
  Fear = 21,
  Charm = 22,
  Poison = 23,
  Suppression = 24,
  Blind = 25,
  Counter = 26,
  Shred = 27,
  Flee = 28,
  Knockup = 29,
  Knockback = 30,
  Disarm = 31,
  Grounded = 32,
  Drowsy = 33,
  Asleep = 34
}

-- Returns true if @unit has buff.type btype

local hard_cc = {
  [5] = true, -- stun
  [8] = true, -- taunt
  [11] = true, -- snare
  [18] = true, -- sleep
  [21] = true, -- fear
  [22] = true, -- charm
  [24] = true, -- suppression
  [28] = true, -- flee
  [29] = true, -- knockup
  [30] = true -- knockback
}

-- Returns true if @object is valid target
function common.IsValidTarget(object)
  return (object and not object.isDead and object.isVisible and object.isTargetable and
    not common.CheckBuffType(object, 17))
end

common.units = {}
common.units.minions, common.units.minionCount = {}, 0
common.units.enemyMinions, common.units.enemyMinionCount = {}, 0
common.units.allyMinions, common.units.allyMinionCount = {}, 0
common.units.jungleMinions, common.units.jungleMinionCount = {}, 0
common.units.enemies, common.units.allies = {}, {}

-- Returns true if enemy @minion is targetable
function common.can_target_minion(minion)
  return minion and not minion.isDead and minion.team ~= TEAM_ALLY and minion.moveSpeed > 0 and minion.health and
    minion.maxHealth > 100 and
    minion.isVisible and
    minion.isTargetable
end

local excluded_minions = {
  ["CampRespawn"] = true,
  ["PlantMasterMinion"] = true,
  ["PlantHealth"] = true,
  ["PlantSatchel"] = true,
  ["PlantVision"] = true
}

local function valid_minion(minion)
  return minion and minion.type == TYPE_MINION and not minion.isDead and minion.health > 0 and minion.maxHealth > 100 and
    minion.maxHealth < 10000 and
    not minion.name:find("Ward") and
    not excluded_minions[minion.name]
end

local function valid_hero(hero)
  return hero and hero.type == TYPE_HERO
end

local function find_place_and_insert(t, c, o, v)
  local dead_place = nil
  for i = 1, c do
    local tmp = t[i]
    if not v(tmp) then
      dead_place = i
      break
    end
  end
  if dead_place then
    t[dead_place] = o
  else
    c = c + 1
    t[c] = o
  end
  return c
end

function common.CountEnemyChampAroundObject(pos, range) 
	local enemies_in_range = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end
function common.CountAllyChampAroundObject(pos, range) 
	local aleds_in_range = {}
	for i = 0, objManager.allies_n - 1 do
		local aled = objManager.allies[i]
		if pos:dist(aled.pos) < range and common.IsValidTarget(aled) then
			aleds_in_range[#aleds_in_range + 1] = aled
		end
	end
	return aleds_in_range
end

local function check_add_minion(o)
  if valid_minion(o) then
    if o.team == TEAM_ALLY then
      common.units.allyMinionCount =
        find_place_and_insert(common.units.allyMinions, common.units.allyMinionCount, o, valid_minion)
    elseif o.team == TEAM_ENEMY then
      common.units.enemyMinionCount =
        find_place_and_insert(common.units.enemyMinions, common.units.enemyMinionCount, o, valid_minion)
    else
      common.units.jungleMinionCount =
        find_place_and_insert(common.units.jungleMinions, common.units.jungleMinionCount, o, valid_minion)
    end
    common.units.minionCount = find_place_and_insert(common.units.minions, common.units.minionCount, o, valid_minion)
  end
end

local function check_add_hero(o)
  if valid_hero(o) then
    if o.team == TEAM_ALLY then
      find_place_and_insert(common.units.allies, #common.units.allies, o, valid_hero)
    else
      find_place_and_insert(common.units.enemies, #common.units.enemies, o, valid_hero)
    end
  end
end

cb.add(cb.create_minion, check_add_hero)
cb.add(cb.create_minion, check_add_minion)

objManager.loop(
  function(obj)
    check_add_hero(obj)
    check_add_minion(obj)
  end
)

-- Returns table of ally hero.obj in @range from @pos
function common.GetAllyHeroesInRange(range, pos)
  local pos = pos or player
  local h = {}
  local allies = common.GetAllyHeroes()
  for i = 1, #allies do
    local hero = allies[i]
    if common.IsValidTarget(hero) and hero.pos:distSqr(pos) < range * range then
      h[#h + 1] = hero
    end
  end
  return h
end

-- Returns table of hero.obj in @range from @pos
function common.GetEnemyHeroesInRange(range, pos)
  local pos = pos or player
  local h = {}
  local enemies = common.GetEnemyHeroes()
  for i = 1, #enemies do
    local hero = enemies[i]
    if common.IsValidTarget(hero) and hero.pos:distSqr(pos) < range * range then
      h[#h + 1] = hero
    end
  end
  return h
end

-- Returns table and number of objects near @pos
function common.CountObjectsNearPos(pos, radius, objects, validFunc)
  local n, o = 0, {}
  for i, object in pairs(objects) do
    if validFunc(object) and pos:dist(object.pos) <= radius then
      n = n + 1
      o[n] = object
    end
  end
  return n, o
end

-- Returns table of @team minion.obj in @range
function common.GetMinionsInRange(range, team, pos)
  pos = pos or player.pos
  range = range or math.huge
  team = team or TEAM_ENEMY
  local validFunc = function(obj)
    return obj and obj.type == TYPE_MINION and obj.team == team and not obj.isDead and obj.health and obj.health > 0 and
      obj.isVisible
  end
  local n, o = common.CountObjectsNearPos(pos, range, common.units.minions, validFunc)
  return o
end

-- Returns table of enemy hero.obj
function common.GetEnemyHeroes()
  return common.units.enemies
end

-- Returns table of ally hero.obj
function common.GetAllyHeroes()
  return common.units.allies
end

-- Returns ally fountain object
common._fountain = nil
common._fountainRadius = 750
function common.GetFountain()
  if common._fountain then
    return common._fountain
  end

  local map = common.GetMap()
  if map and map.index and map.index == 1 then
    common._fountainRadius = 1050
  end

  if common.GetShop() then
    objManager.loop(
      function(obj)
        if
          obj and obj.team == TEAM_ALLY and obj.name:lower():find("spawn") and not obj.name:lower():find("troy") and
            not obj.name:lower():find("barracks")
         then
          common._fountain = obj
          return common._fountain
        end
      end
    )
  end
  return nil
end

-- Returns true if you are near fountain
function common.NearFountain(distance)
  local d = distance or common._fountainRadius or 0
  local fountain = common.GetFountain()
  if fountain then
    return (player.pos2D:distSqr(fountain.pos2D) <= d * d), fountain.x, fountain.y, fountain.z, d
  else
    return false, 0, 0, 0, 0
  end
end

-- Returns true if you are near fountain
function common.InFountain()
  return common.NearFountain()
end

-- Returns the ally shop object
common._shop = nil
common._shopRadius = 1250
function common.GetShop()
  if common._shop then
    return common._shop
  end
  objManager.loop(
    function(obj)
      if obj and obj.team == TEAM_ALLY and obj.name:lower():find("shop") then
        common._shop = obj
        return common._shop
      end
    end
  )
  return nil
end

return common
