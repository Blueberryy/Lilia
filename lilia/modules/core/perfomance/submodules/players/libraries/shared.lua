﻿---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:PlayerInitialSpawn(client)
    self:RegisterPlayer(client)
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:EntityRemoved(entity)
    if entity:IsPlayer() then self:RemovePlayer(entity) end
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:GetPlayerData(client)
    return PerfomanceCore.tblPlayers[client:EntIndex()]
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:RemovePlayer(client)
    PerfomanceCore.tblPlayers[client:EntIndex()] = nil
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:RegisterPlayer(client)
    PerfomanceCore.tblPlayers[client:EntIndex()] = {
        Player = client,
        Expanding = false,
        Expanded = false,
        EntBuffer = {},
    }

    self:PlayerUpdateTransmitStates(client)
    timer.Simple(8, function() self:BeginExpand(client) end)
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:PlayerUpdateTransmitStates(client, intRange)
    if intRange then
        for _, v in pairs(ents.GetAll()) do
            if table.HasValue(self.tblAlwaysSend, v:GetClass()) then
                v:SetPreventTransmit(client, false)
                continue
            end

            if v.UpdateTransmitState and v:UpdateTransmitState() == TRANSMIT_ALWAYS then
                v:SetPreventTransmit(client, false)
                continue
            end

            if v:GetPos():Distance(client:GetPos()) > 5500 then
                v:SetPreventTransmit(client, true)
            else
                v:SetPreventTransmit(client, false)
            end
        end
    else
        for _, v in pairs(ents.GetAll()) do
            if table.HasValue(self.tblAlwaysSend, v:GetClass()) then
                v:SetPreventTransmit(client, false)
                continue
            end

            if v.UpdateTransmitState and v:UpdateTransmitState() == TRANSMIT_ALWAYS then
                v:SetPreventTransmit(client, false)
                continue
            end

            v:SetPreventTransmit(client, true)
        end
    end
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:BeginExpand(client)
    local data = self:GetPlayerData(client)
    if not data then return end
    data.Expanding = true
    local timerID = "PerfomanceTicks:" .. client:EntIndex()
    local currentRange = 0
    timer.Create(timerID, 1, 0, function()
        if not IsValid(client) then
            timer.Remove(timerID)
            return
        end

        currentRange = math.min(5500, currentRange + 512)
        self:PlayerUpdateTransmitStates(client, currentRange)
        if currentRange == 5500 then
            timer.Remove(timerID)
            data.Expanded = true
            data.Expanding = false
        end
    end)
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function EntityPerfomanceCore:PlayerExpandedUpdate()
    for k, data in pairs(PerfomanceCore.tblPlayers) do
        if not data or not data.Expanded then continue end
        if not IsValid(data.Player) then
            PerfomanceCore.tblPlayers[k] = nil
            continue
        end

        self:PlayerUpdateTransmitStates(data.Player, 5500)
    end
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
timer.Create("PlayerExpandedUpdate", 1, 0, function() EntityPerfomanceCore:PlayerExpandedUpdate() end)
---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
