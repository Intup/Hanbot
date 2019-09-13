local pred = module.internal("pred");
local TS = module.internal("TS");
local orb = module.internal("orb");
local common = module.load("ic", "common");

local Update = module.load('ic', "AutoUpdate");

local headshot = 'caitlynheadshot';
local caitlynshot = 'caitlynyordletrapsight';
local caitlynletal = 'caitlynyordletrapinternal';
local preAA = false;
local delaye = 0;
local Caitlyn = player;
local Vision = { };

local pred_input_q = {
    delay = 0.625,
    speed = 2200,
    width = 90,
    boundingRadiusMod = 1,
    range = 1250,
    collision = {
      minion = false, 
      wall = false, 
      hero = false, 
    },
}

local pred_input_e = {
    delay = 0.25,
    speed = math.huge,
    width = math.huge,
    boundingRadiusMod = 1,
    range = 750,
    collision = {
      minion = true, 
      wall = true, 
      hero = true, 
    },
}

local pred_input_w = {
    range = 800,
	delay = 0.50,
	speed = math.huge,
	radius = 20,
	boundingRadiusMod = 0
}

local function trace_filter(seg, obj, dist)
    if seg.startPos:dist(seg.endPos) > pred_input_e.range then
        return false
    end
    if pred.trace.newpath(obj, 0.033, 0.500) and dist < 1000 then
        return true
    end
    if pred.trace.linear.hardlock(pred_input_e, seg, obj) then
        return true
    end
    if pred.trace.linear.hardlockmove(pred_input_e, seg, obj) then
        return true
    end
end

--[[local function GetIsImmobile(target)
    local gerobuff = target.buff;
    local timebuff = {};
    local debugg = {};
    --if bool then
        if gerobuff and gerobuff.valid and (timebuff <= gerobuff.endTime) then
            debugg[gerobuff.type] = true;
        end
        --return
        if debugg[5] or debugg[8] or debugg[11] or debugg[18] or debugg[24] or debugg[29] then
            return true;
        end
    --end
end]]

local function OnVision(unit)
    if Vision[unit.networkID] == nil then 
        Vision[unit.networkID] = {state = unit.isVisible , tick = os.clock(), pos = unit.pos}
    end
    if Vision[unit.networkID].state == true and not unit.isVisible then
        Vision[unit.networkID].state = false Vision[unit.networkID].tick = os.clock()
    end
    if Vision[unit.networkID].state == false and unit.isVisible then
        Vision[unit.networkID].state = true Vision[unit.networkID].tick = os.clock()
    end
	return Vision[unit.networkID]
end

local function HeadShot()
    return orb.core.can_attack() and not orb.core.is_paused() and not orb.core.is_attack_paused()
end

local menu = menu("ic", "Int Caitlyn");

menu:menu('combo', 'Combo');
menu.combo:menu('qset', "Peacemaker Settings"); --Snap Trap(800), Caliber Net(750), Ace in the Hol(3500).
menu.combo.qset:boolean("comboq", "Use Q in Combo", true);
menu.combo.qset:header("q1", "Peacemaker modules");
menu.combo.qset:dropdown("qrange", "^ Min. Q Range", 2, {"Always", "Only out AA"});
menu.combo.qset:boolean("qcc", "Auto Q on CC", true);
menu.combo.qset:boolean("qkill", "Q Kill Steal", true);
menu.combo.qset:header("q2", "Peacemaker Drawing");
menu.combo.qset:boolean("qdrawing", "Range Q spell", true);

menu.combo:menu('wset', "Snap Trap");
menu.combo.wset:boolean("combow", "Use W in Combo", true);
menu.combo.wset:header("w1", "Snap Trap modules");
menu.combo.wset:boolean("Wcc", "Auto W on hard CC", true);
menu.combo.wset:boolean("FORCE", "Force W before E", true);
menu.combo.wset:header("W2", "Snap Trap Drawing");
menu.combo.wset:boolean("wdra", "Range W spell", false);

menu.combo:menu('eset', "Caliber Net");
menu.combo.eset:boolean("comboe", "Use E in Combo", true);
menu.combo.eset:header("e1", "Caliber Net modules");
menu.combo.eset:boolean("eim", "Auto E immobile target", false);
menu.combo.eset:boolean("egp", "Gap Closer", true);
menu.combo.eset:header("e2", "Caliber Net Drawing");
menu.combo.eset:boolean("edra", "Range E spell", true);

menu.combo:menu('rset', "Ace in the Hol");
menu.combo.rset:boolean("combor", "Use R to finish", true);
menu.combo.rset:header("r1", "Ace in the Hol modules");
menu.combo.rset:boolean("eim", "Auto R immobile target", false);
menu.combo.rset:slider("range", " ^ Min. Range safe", 950, 1, 1500, 1)
menu.combo.rset:header("r2", "Ace in the Hol Drawing");
menu.combo.rset:boolean("edra", "Range R spell (Minimap)", true);

menu:menu('harass', 'Harass');
menu.harass:header("hset", "Caitlyn Harass modules");
menu.harass:boolean("harassq", "Use Q in Harass", true);
menu.harass:dropdown("qrange", "^ Min. Q Range", 2, {"Always", "Only out AA"});
menu.harass:boolean("harasse", "Use E in Harass", true);
menu.harass:header("hset1", "Caitlyn Harass Mana");
menu.harass:slider("mana", " ^ Min. Mana", 50, 1, 100, 1);

menu:menu('misc', 'Misc');
menu.misc:header("mset", "Caitlyn Misc modules");
menu.misc:boolean("faa", "Force AA", true);
menu.misc:boolean("ends", "Auto spell on End Dash", true);
menu.misc:header("mset1", "Misc special spells");
menu.misc:boolean("useWs", "Use W for special spells", true);

menu:menu('key', 'Keys');
menu.key:header("kset", "Caitlyn keys modules");
menu.key:keybind("combokey", "Combo Key", "Space", nil)
menu.key:keybind("harakey", "Harass Key", "C", nil)
menu.key:keybind("lanekey", "Lane Clear Key", "V", nil)
menu.key:keybind("lastkey", "Last Hit", "X", nil)

TS.load_to_menu(menu)
local TargetSelection = function(res, obj, dist)
	if dist < 1200 then
		res.obj = obj
		return true
	end
end
local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end


--[[cb.add(cb.tick, function()
    if player.buff[headshot] then 
        print('Working');
    end
    local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and not common.CheckBuffType(enemies, 17) then
            if enemies.buff["caitlynyordletrapinternal"] then 
                print("ddd")
            end
            if enemies.charName == 'Shen' then 
                for i = 0, enemies.buffManager.count - 1 do
                    local buff = enemies.buffManager:get(i)
                    if buff and buff.valid then
                        print(buff.name)
                    end 
                end 
            end
        end 
    end
    return;
end)]]

local function OnDraw()
    if Caitlyn.isOnScreen and common.IsValidTarget(Caitlyn) then 
        if Caitlyn:spellSlot(0).state == 0 then 
            if menu.combo.qset.qdrawing:get() then 
                graphics.draw_circle(Caitlyn.pos, 1250, 2, 0xFFFFFFFF, 32)
            end
        end

        if Caitlyn:spellSlot(1).state == 0 then 
            if menu.combo.wset.wdra:get() then 
                graphics.draw_circle(Caitlyn.pos, 800, 2, 0xFFFFFFFF, 32)
            end
        end


        if Caitlyn:spellSlot(2).state == 0 then 
            if menu.combo.eset.edra:get() then 
                graphics.draw_circle(Caitlyn.pos, 750, 2, 0xFFFFFFFF, 32)
            end
        end
    end

    if Caitlyn:spellSlot(3).state == 0 and common.IsValidTarget(Caitlyn) then  
        if menu.combo.rset.edra:get() then
            minimap.draw_circle(Caitlyn.pos, 3500, 2.4, 0xFFFFFFFF, 16);
        end
    end
end

local function Combo()
    local target = GetTarget();
    local qmode = menu.combo.qset.qrange:get();
    if target == nil then return end
    if target and common.IsValidTarget(target) then
        if (menu.combo.eset.comboe:get()) and vec3(target.x, target.y, target.z):dist(Caitlyn) < 750 and Caitlyn.path.serverPos:distSqr(target.path.serverPos) > Caitlyn.path.serverPos:distSqr(target.path.serverPos + target.direction) then
            if Caitlyn:spellSlot(2).state == 0 then
                --pred
                local pos = pred.linear.get_prediction(pred_input_e, target)
                if pos and pos.startPos:dist(pos.endPos) < pred_input_e.range then
                    if pred.collision.get_prediction(pred_input_e, pos, target) then return false end
                    if trace_filter(pos, target, 750) then
                        Caitlyn:castSpell("pos", 2, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
                        delaye = game.time;
                    end
                end
            end
        end
        if Caitlyn:spellSlot(1).state == 0 and (menu.combo.wset.combow:get()) then
            --local Distancia = (target.pos - player.pos):len() not recmend
            if vec3(target.x, target.y, target.z):dist(Caitlyn) < 800 then
                if preAA == true and (target.buff[caitlynletal] or Caitlyn.path.isDashing) then 
                    local pos = pred.circular.get_prediction(pred_input_w, target)
                    if pos and pos.startPos:dist(pos.endPos) <= pred_input_w.range then
                        Caitlyn:castSpell("pos", 1, vec3(pos.endPos.x, pos.endPos.y, pos.endPos.y))
                    end
                end
            end
        end
        if (menu.combo.qset.comboq:get()) then
            if qmode == 1 then
                --if (menu.combo.qset.comboq:get()) then
                    if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 then
                        if (target.buff[caitlynletal] or target.buff[18] or target.buff[5]) then
                            local pos = pred.linear.get_prediction(pred_input_q, target)
                            if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                                if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                                if pred.trace.newpath(target, 0.033, 0.500) and 1250 < 1300 then return true end
                                if pred.trace.linear.hardlock(pred_input_q, pos, target) then return true end
                                if pred.trace.linear.hardlockmove(pred_input_q, pos, target) then return true end
                                Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,   game.mousePos.y, pos.endPos.y))
                            end
                        end
                    end
                --end
            elseif qmode == 2 then 
                if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 and vec3(Caitlyn.x, Caitlyn.y, Caitlyn.z):dist(target) > common.GetAARange(Caitlyn) then
                    if (target.buff[caitlynletal] or target.buff[10] or target.buff[18] or target.buff[5]) then
                        local pos = pred.linear.get_prediction(pred_input_q, target)
                        if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                            if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                            if pred.trace.newpath(target, 0.033, 0.500) and 1250 < 1300 then return true end
                            if pred.trace.linear.hardlock(pred_input_q, pos, target) then return true end
                            if pred.trace.linear.hardlockmove(pred_input_q, pos, target) then return true end
                            Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,   game.mousePos.y, pos.endPos.y))
                        end
                    end
                end
            end
        end
        if HeadShot() and Caitlyn.buff[headshot] and Caitlyn:spellSlot(2).state == 0 then 
            orb.core.set_pause_attack(math.huge)
            local pos = pred.linear.get_prediction(pred_input_e, target)
            if pos and pos.startPos:dist(pos.endPos) < pred_input_e.range then
                if pred.collision.get_prediction(pred_input_e, pos, target) then return false end
                Caitlyn:castSpell("pos", 2, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
            end
            Caitlyn:attack(target);
        end
        orb.core.set_pause_attack(0)
    end
end

local function Harass()
    if common.GetPercentMana(player) >= menu.harass.mana:get() then
        local target = GetTarget();
        local qmode = menu.harass.qrange:get();
        if target == nil then return end
        if target and common.IsValidTarget(target) then
            if (menu.harass.harasse:get()) and vec3(target.x, target.y, target.z):dist(Caitlyn) < 750 and Caitlyn.path.serverPos:distSqr(target.path.serverPos) > Caitlyn.path.serverPos:distSqr(target.path.serverPos + target.direction) then
                if Caitlyn:spellSlot(2).state == 0 then
                    --pred
                    local pos = pred.linear.get_prediction(pred_input_e, target)
                    if pos and pos.startPos:dist(pos.endPos) < pred_input_e.range then
                        if pred.collision.get_prediction(pred_input_e, pos, target) then return false end
                        if trace_filter(pos, target, 750) then
                            Caitlyn:castSpell("pos", 2, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
                        end
                    end
                end
            end
            if (menu.harass.harassq:get()) then
                if qmode == 1 then
                    --if (menu.combo.qset.comboq:get()) then
                        if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 then
                            if (target.buff[caitlynletal] or target.buff[18] or target.buff[5]) then
                                local pos = pred.linear.get_prediction(pred_input_q, target)
                                if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                                    if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                                    if pred.trace.newpath(target, 0.033, 0.500) and 1250 < 1300 then return true end
                                    if pred.trace.linear.hardlock(pred_input_q, pos, target) then return true end
                                    if pred.trace.linear.hardlockmove(pred_input_q, pos, target) then return true end
                                    Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,   game.mousePos.y, pos.endPos.y))
                                end
                            end
                        end
                    --end
                elseif qmode == 2 then 
                    if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 and vec3(Caitlyn.x, Caitlyn.y, Caitlyn.z):dist(target) > common.GetAARange(Caitlyn) then
                        if (target.buff[caitlynletal] or target.buff[10] or target.buff[18] or target.buff[5]) then
                            local pos = pred.linear.get_prediction(pred_input_q, target)
                            if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                                if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                                if pred.trace.newpath(target, 0.033, 0.500) and 1250 < 1300 then return true end
                                if pred.trace.linear.hardlock(pred_input_q, pos, target) then return true end
                                if pred.trace.linear.hardlockmove(pred_input_q, pos, target) then return true end
                                Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,   game.mousePos.y, pos.endPos.y))
                            end
                        end
                    end
                end
            end
        end
    end
    --chat.print('Press')
end
orb.combat.register_f_after_attack(function()
    if (menu.key.combokey:get()) then
        Combo();
    end
end)

local function SpellEndDash()
    if player:spellSlot(2).state == 0 then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) and enemiess.path.isActive and enemiess.path.isDashing and Caitlyn.pos:dist(enemiess.path.point[1]) < 800 then
                if Caitlyn.pos2D:dist(enemiess.path.point2D[1]) < Caitlyn.pos2D:dist(enemiess.path.point2D[0]) then
                    player:castSpell("pos", 2, enemiess.path.point2D[1])
                end
            end
            if enemiess.path.isActive and enemiess.path.isDashing and Caitlyn.pos:dist(enemiess.path.point[1]) < 800 then
                if Caitlyn.pos2D:dist(enemiess.path.point2D[1]) < Caitlyn.pos2D:dist(enemiess.path.point2D[0]) then
                    player:castSpell("pos", 1, enemiess.path.point2D[1])
                end
            end
        end
    end
end

local function OnPreTick()
    if Caitlyn.isDead or common.CheckBuffType(Caitlyn, 17) then return end
    local target = GetTarget();

    if target and common.IsValidTarget(target) then
        if vec3(target.x, target.y, target.z):dist(Caitlyn) <= 1300  and HeadShot() then
            if target.buff['caitlynyordletrapinternal'] then
                Caitlyn:attack(target);
                orb.core.set_server_pause();
            end
        end
    end
    --Caitlyn:attack(target)
    if menu.misc.faa:get() then
        if (menu.key.lanekey:get() or menu.key.lastkey:get()) then 
            --print('Attack');
            local enemy = common.GetEnemyHeroes()
            for i, enemies in ipairs(enemy) do
                if enemies and common.IsValidTarget(enemies) then
                    if Caitlyn.buff[headshot] and HeadShot() and vec3(enemies.x, enemies.y, enemies.z):dist(Caitlyn) <= common.GetAARange(Caitlyn) then
                        Caitlyn:attack(enemies);
                        orb.core.set_server_pause();
                    end
                end
            end
        end
    end
    if delaye > 0 then 
        preAA = true;
    else 
        preAA = false;
    end

    if (menu.combo.qset.qcc:get()) then 
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                if Caitlyn:spellSlot(0).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) < 1250 then
                    if enemiess.buff[caitlynshot] or (enemiess.buff[5] or enemiess.buff[8] or enemiess.buff[11] or enemiess.buff[18] or enemiess.buff[21] or enemiess.buff[22] or enemiess.buff[24] or enemiess.buff[28] or enemiess.buff[29]) then
                        local pos = pred.linear.get_prediction(pred_input_q, enemiess)
                        if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                            Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,  game.mousePos.y, pos.endPos.y))
                        end
                    end
                end
            end
        end
    end

    if (menu.combo.wset.Wcc:get())  then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                if Caitlyn:spellSlot(1).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) < 800 then
                    if enemiess.buff[caitlynshot] or (enemiess.buff[5] or enemiess.buff[8] or enemiess.buff[11] or enemiess.buff[18] or enemiess.buff[21] or enemiess.buff[22] or enemiess.buff[24] or enemiess.buff[28] or enemiess.buff[29]) then
                        local pos = pred.circular.get_prediction(pred_input_w, target)
                        if pos and pos.startPos:dist(pos.endPos) <= pred_input_w.range then
                            Caitlyn:castSpell("pos", 1, vec3(pos.endPos.x, pos.endPos.y, pos.endPos.y))
                        end
                    end
                end
            end
        end
    end

    if (menu.misc.ends:get()) then 
        SpellEndDash();
    end
    for t = 6, 12 do
        if Caitlyn.levelRef > 8 then
            Caitlyn:buyItem(3363)
        end
        if (Caitlyn:spellSlot(t).name == "TrinketOrbLvl3") and Caitlyn:spellSlot(t).state == 0 then
            local enemy = common.GetEnemyHeroes()
            for i, unit in ipairs(enemy) do
                if unit and vec3(unit.x, unit.y, unit.z):dist(Caitlyn) < 3500 then
                    if OnVision(unit).state == false then
                        Caitlyn:castSpell("pos", t, unit.pos)
                    end
                end
            end
        end
        if Caitlyn:spellSlot(t).name == "TrinketTotemLvl1" and  Caitlyn:spellSlot(t).state == 0 then
            local enemy = common.GetEnemyHeroes()
            for i, unit in ipairs(enemy) do
                if unit and vec3(unit.x, unit.y, unit.z):dist(Caitlyn) < 550 then
                    if OnVision(unit).state == false then
                        Caitlyn:castSpell("pos", t, unit.pos)
                    end
                end
            end
        end
       --chat.print(Caitlyn:spellSlot(t).name)
    end

    if (menu.key.harakey:get()) then
        Harass();
    end

    if (menu.combo.rset.combor:get() and Caitlyn:spellSlot(3).state == 0) then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                local RBaseDamage = ({ 250, 475, 700 })[Caitlyn:spellSlot(3).level] + 1  * common.GetTotalAD()
                local RDamage = common.CalculatePhysicalDamage(enemiess, RBaseDamage)
                if RDamage - enemiess.healthRegenRate > common.GetShieldedHealth("AD", enemiess) then
                    if Caitlyn:spellSlot(3).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) > menu.combo.rset.range:get() and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) <= 3500 then 
                        if #common.CountEnemyChampAroundObject(player.pos, menu.combo.rset.range:get()) == 0  and #common.CountAllyChampAroundObject(enemiess.pos, 500) == 0 then
                            Caitlyn:castSpell('obj', 3, enemiess);
                            orb.core.set_server_pause();
                        end
                    end
                end
                if (menu.combo.rset.eim:get()) then
                    if (enemiess.buff[5] or enemiess.buff[8] or enemiess.buff[11] or enemiess.buff[18] or enemiess.buff[21] or enemiess.buff[22] or enemiess.buff[24] or enemiess.buff[28] or enemiess.buff[29])  and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) <= 3500 then 
                        if #common.CountEnemyChampAroundObject(player.pos, menu.combo.rset.range:get()) == 0 and #common.CountAllyChampAroundObject(enemiess.pos, 500) > 0 then
                            Caitlyn:castSpell('obj', 3, enemiess);
                        end
                    end
                end
            end
        end
    end

    if (menu.combo.qset.qkill:get() and Caitlyn:spellSlot(0).state == 0) then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                local QBaseDamage = ({ 30, 70, 110, 150, 190 })[Caitlyn:spellSlot(0).level] + ({1.3, 1.4, 1.5, 1.6, 1.7})[Caitlyn:spellSlot(0).level]  * common.GetTotalAD()
                local QDamage = common.CalculatePhysicalDamage(enemiess, QBaseDamage)
                if QDamage - enemiess.healthRegenRate > common.GetShieldedHealth("AD", enemiess) then
                    if Caitlyn:spellSlot(0).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) < 1250 and vec3(Caitlyn.x, Caitlyn.y, Caitlyn.z):dist(enemiess) > common.GetAARange(Caitlyn) then
                        local pos = pred.linear.get_prediction(pred_input_q, enemiess)
                        if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                            if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                            if pred.trace.newpath(enemiess, 0.033, 0.500) and 1250 < 1300 then return true end
                            if pred.trace.linear.hardlock(pred_input_q, pos, enemiess) then return true end
                            if pred.trace.linear.hardlockmove(pred_input_q, pos, enemiess) then return true end
                            Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,  game.mousePos.y, pos.endPos.y))
                        end
                    end
                end
            end
        end
    end
end

local function WSpell(spell)
    if (menu.misc.useWs:get()) then
        if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.owner.charName == "MasterYi" and (spell.name == "Meditate" or spell.name == "ShenR") then
            if Caitlyn.pos2D:dist(spell.owner.pos2D) < pred_input_w.range and common.IsValidTarget(spell.owner) then 
                if Caitlyn:spellSlot(1).state == 0 then 
                    Caitlyn:castSpell("pos", 1, spell.owner.pos)
                end
            end
        end
    end
end

chat.print('[Int]' .. 'Welcome Hanbot');


orb.combat.register_f_pre_tick(OnPreTick)
cb.add(cb.draw, OnDraw);
cb.add(cb.spell, WSpell)
