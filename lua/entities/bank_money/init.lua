AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:Initialize()
	self:SetModel("models/props_junk/wood_pallet001a.mdl")
	self:PhysicsInit(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetUseType(0)
	self.ColMin, self.ColMax = self:GetCollisionBounds()
	self:RefreshModel()
end

function ENT:RefreshModel()
	self:SetCollisionBounds(self.ColMin, self.ColMax + Vector(0, 0, GetGlobalInt("BankMoney", 0)/BANK.MoneyMax * 50))
end

local BankDebounces = {}
function ENT:AcceptInput(InputName, Plr)
	if IsValid(Plr) and Plr:IsPlayer() and not BankDebounces[Plr] and BeginBankRobbery then
		BankDebounces[Plr] = true
		timer.Simple(1, function() BankDebounces[Plr] = nil end)
		BeginBankRobbery(Plr)
	end
end

local LastPressTime = 0
local SmallProgress = 0
function ENT:Use(Activator, Caller, UseType, Value)
	if GetGlobalBool("BankRobbery", false) and BankRobber == Caller then
		local TimeDiff = CurTime() - LastPressTime
		LastPressTime = CurTime()
		if TimeDiff < 0.1 then
			SmallProgress = SmallProgress + TimeDiff
			if SmallProgress > 0.5 then
				AddBankTakeaway()
				SmallProgress = 0
			end
		else
			SmallProgress = 0
		end
	end
end