﻿------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CVAR_THIRDPERSON = CreateClientConVar("lia_tp_enabled", "0", true)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CVAR_TP_CLASSIC = CreateClientConVar("lia_tp_classic", "0", true)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CVAR_TP_VERT = CreateClientConVar("lia_tp_vertical", 10, true)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CVAR_TP_HORI = CreateClientConVar("lia_tp_horizontal", 0, true)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CVAR_TP_DIST = CreateClientConVar("lia_tp_distance", 50, true)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local view, traceData, traceData2, aimOrigin, crouchFactor, ft, curAng, diff, fm, sm
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local playerMeta = FindMetaTable("Player")
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
crouchFactor = 0
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local maxValues = {
    height = 30,
    horizontal = 30,
    distance = 100
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ThirdPersonCore:SetupQuickMenu(menu)
    if self.ThirdPersonEnabled then
        menu:addCheck(
            L"thirdpersonToggle",
            function(_, state)
                if state then
                    RunConsoleCommand("lia_tp_enabled", "1")
                else
                    RunConsoleCommand("lia_tp_enabled", "0")
                end
            end, CVAR_THIRDPERSON:GetBool()
        )

        menu:addCheck(
            L"thirdpersonClassic",
            function(_, state)
                if state then
                    RunConsoleCommand("lia_tp_classic", "1")
                else
                    RunConsoleCommand("lia_tp_classic", "0")
                end
            end, CVAR_TP_CLASSIC:GetBool()
        )

        menu:addButton(
            L"thirdpersonConfig",
            function()
                if lia.gui.tpconfig and lia.gui.tpconfig:IsVisible() then
                    lia.gui.tpconfig:Close()
                    lia.gui.tpconfig = nil
                end

                lia.gui.tpconfig = vgui.Create("liaTPConfig")
            end
        )

        menu:addSpacer()
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ThirdPersonCore:CalcView(client)
    ft = FrameTime()
    if client:CanOverrideView() then
        if (client:OnGround() and client:KeyDown(IN_DUCK)) or client:Crouching() then
            crouchFactor = Lerp(ft * 5, crouchFactor, 1)
        else
            crouchFactor = Lerp(ft * 5, crouchFactor, 0)
        end

        curAng = owner.camAng or Angle(0, 0, 0)
        view = {}
        traceData = {}
        traceData.start = client:GetPos() + client:GetViewOffset() + curAng:Up() * math.Clamp(CVAR_TP_VERT:GetInt(), 0, maxValues.height) + curAng:Right() * math.Clamp(CVAR_TP_HORI:GetInt(), -maxValues.horizontal, maxValues.horizontal) - client:GetViewOffsetDucked() * .5 * crouchFactor
        traceData.endpos = traceData.start - curAng:Forward() * math.Clamp(CVAR_TP_DIST:GetInt(), 0, maxValues.distance)
        traceData.filter = client
        view.origin = util.TraceLine(traceData).HitPos
        aimOrigin = view.origin
        view.angles = curAng + client:GetViewPunchAngles()
        traceData2 = {}
        traceData2.start = aimOrigin
        traceData2.endpos = aimOrigin + curAng:Forward() * 65535
        traceData2.filter = client
        if CVAR_TP_CLASSIC:GetBool() or (owner.isWepRaised and owner:isWepRaised() or (owner:KeyDown(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)) and owner:GetVelocity():Length() >= 10)) then
            client:SetEyeAngles((util.TraceLine(traceData2).HitPos - client:GetShootPos()):Angle())
        end

        return view
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ThirdPersonCore:CreateMove(cmd)
    owner = LocalPlayer()
    if owner:CanOverrideView() and owner:GetMoveType() ~= MOVETYPE_NOCLIP and LocalPlayer():GetViewEntity() == LocalPlayer() then
        fm = cmd:GetForwardMove()
        sm = cmd:GetSideMove()
        diff = (owner:EyeAngles() - (owner.camAng or Angle(0, 0, 0)))[2] or 0
        diff = diff / 90
        cmd:SetForwardMove(fm + sm * diff)
        cmd:SetSideMove(sm + fm * diff)

        return false
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ThirdPersonCore:InputMouseApply(_, x, y)
    owner = LocalPlayer()
    if not owner.camAng then
        owner.camAng = Angle(0, 0, 0)
    end

    if owner:CanOverrideView() and LocalPlayer():GetViewEntity() == LocalPlayer() then
        owner.camAng.p = math.Clamp(math.NormalizeAngle(owner.camAng.p + y / 50), -85, 85)
        owner.camAng.y = math.NormalizeAngle(owner.camAng.y - x / 50)

        return true
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ThirdPersonCore:ShouldDrawLocalPlayer()
    if LocalPlayer():GetViewEntity() == LocalPlayer() and not IsValid(LocalPlayer():GetVehicle()) and LocalPlayer():CanOverrideView() then return true end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function playerMeta:CanOverrideView()
    local ragdoll = Entity(self:getLocalVar("ragdoll", 0))
    if IsValid(lia.gui.char) and lia.gui.char:IsVisible() then return false end

    return CVAR_THIRDPERSON:GetBool() and not IsValid(self:GetVehicle()) and IsValid(self) and self:getChar() and not IsValid(ragdoll) and LocalPlayer():Alive()
end

--------------------------------------------------------------------------------------------------------------------------
function ThirdPersonCore:PlayerButtonDown(_, button)
    if button == KEY_F4 and IsFirstTimePredicted() then
        local toggle = CVAR_THIRDPERSON
        if toggle:GetInt() == 1 then
            toggle:SetInt(0)
        else
            toggle:SetInt(1)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
concommand.Add(
    "lia_tp_toggle",
    function()
        CVAR_THIRDPERSON:SetInt(CVAR_THIRDPERSON:GetInt() == 0 and 1 or 0)
    end
)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------