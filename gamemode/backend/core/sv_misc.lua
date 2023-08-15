--------------------------------------------------------------------------------------------------------
lia.config.CarRagdoll = true
lia.config.HeadShotDamage = 2

--------------------------------------------------------------------------------------------------------
function GM:ModuleShouldLoad(module)
    return not lia.module.isDisabled(module)
end

--------------------------------------------------------------------------------------------------------
function GM:PlayerDeathSound()
    return true
end

--------------------------------------------------------------------------------------------------------
function GM:CanPlayerSuicide(client)
    return false
end

--------------------------------------------------------------------------------------------------------
function GM:AllowPlayerPickup(client, entity)
    return false
end

--------------------------------------------------------------------------------------------------------
function GM:PlayerShouldTakeDamage(client, attacker)
    return client:getChar() ~= nil
end

--------------------------------------------------------------------------------------------------------
function GM:EntityTakeDamage(entity, dmgInfo)
    if IsValid(entity) and entity:IsPlayer() and dmgInfo:IsDamageType(DMG_CRUSH) and not IsValid(entity.liaRagdoll) then return true end

    if IsValid(entity.liaPlayer) then
        if dmgInfo:IsDamageType(DMG_CRUSH) then
            if (entity.liaFallGrace or 0) < CurTime() then
                if dmgInfo:GetDamage() <= 10 then
                    dmgInfo:SetDamage(0)
                end

                entity.liaFallGrace = CurTime() + 0.5
            else
                return
            end
        end

        entity.liaPlayer:TakeDamageInfo(dmgInfo)
    end

    if not IsValid(target) or not target:IsPlayer() then return end
    local inflictor = dmginfo:GetInflictor()
    local attacker = dmginfo:GetAttacker()

    if not dmginfo:IsFallDamage() and IsValid(attacker) and attacker:IsPlayer() and attacker ~= target and target:Team() ~= FACTION_STAFF then
        target.LastDamaged = CurTime()
    end

    if lia.config.CarRagdoll and IsValid(inflictor) and (inflictor:GetClass() == "gmod_sent_vehicle_fphysics_base" or inflictor:GetClass() == "gmod_sent_vehicle_fphysics_wheel") and not IsValid(target:GetVehicle()) then
        dmginfo:ScaleDamage(0)

        if not IsValid(target.liaRagdoll) then
            target:setRagdolled(true, 5)
        end
    end
end

--------------------------------------------------------------------------------------------------------
function GM:ScalePlayerDamage(ply, hitgroup, dmgInfo)
    if hitgroup == HITGROUP_HEAD then
        dmgInfo:ScaleDamage(lia.config.HeadShotDamage)
    end
end

--------------------------------------------------------------------------------------------------------
function GM:PreCleanupMap()
    lia.shuttingDown = true
    hook.Run("SaveData")
    hook.Run("PersistenceSave")
end

--------------------------------------------------------------------------------------------------------
function GM:PostCleanupMap()
    lia.shuttingDown = false
    hook.Run("LoadData")
    hook.Run("PostLoadData")
end

--------------------------------------------------------------------------------------------------------
function GM:OnItemSpawned(ent)
    ent.health = 250
end

--------------------------------------------------------------------------------------------------------
hook.Remove("PlayerInitialSpawn", "VJBaseSpawn")
--------------------------------------------------------------------------------------------------------