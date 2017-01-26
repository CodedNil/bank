SetGlobalBool("BankRobbery", false)
SetGlobalFloat("BankTakeaway", 0)
BankRobber = nil
local NotifiedRobber = false

-- Reward for killing robber?
-- Reward for all police for stopping robber?

local function SpecialPrint(Plr, Text)
	if Plr then
		Plr:PrintMessage(HUD_PRINTCONSOLE, Text)
	else
		print(Text)
	end
end

hook.Add("InitPostEntity", "BankPostEntity", function()
	if not file.IsDir("codenil", "DATA") then
		file.CreateDir("codenil", "DATA")
	end
	if not file.IsDir("codenil/bank/"..game.GetMap():lower().."", "DATA") then
		file.CreateDir("codenil/bank/"..game.GetMap():lower().."", "DATA")
	end
	if not file.Exists("codenil/bank/"..game.GetMap():lower().."/bankpos.txt", "DATA" ) then
		file.Write("codenil/bank/"..game.GetMap():lower().."/bankpos.txt", "0,0,0,0,0,0", "DATA")
	end
	local VectorAngle = string.Explode(",", file.Read("codenil/bank/"..game.GetMap():lower().."/bankpos.txt", "DATA"))
	
	BankMoneyEntity = ents.Create("bank_money")
	BankMoneyEntity:SetPos(Vector(VectorAngle[1], VectorAngle[2], VectorAngle[3]))
	BankMoneyEntity:SetAngles(Angle(VectorAngle[4], VectorAngle[5], VectorAngle[6]))
	BankMoneyEntity:Spawn()
	
	concommand.Add("setbankpos", function(Plr)
		if IsValid(Plr) and Plr:IsAdmin() then
			SpecialPrint(Plr, "Bank position set.")
			local Pos, Ang = Plr:GetPos() + Vector(0, 0, 4), Plr:GetAngles()
			BankMoneyEntity:SetPos(Pos)
			BankMoneyEntity:SetAngles(Ang)
			file.Write("codenil/bank/"..game.GetMap():lower().."/bankpos.txt", Pos.x..","..Pos.y..","..Pos.z..","..Ang.p..","..Ang.y..","..Ang.r, "DATA")
		else
			SpecialPrint(Plr, "Cannot do that, must be admin, also can't be console.")
		end
	end)
end)

concommand.Add("setbankpos", function(Plr)
	if IsValid(BankMoneyEntity) then
		if IsValid(Plr) and Plr:IsAdmin() then
			SpecialPrint(Plr, "Bank position set.")
			local Pos, Ang = Plr:GetPos() + Vector(0, 0, 4), Plr:GetAngles()
			BankMoneyEntity:SetPos(Pos)
			BankMoneyEntity:SetAngles(Ang)
			file.Write("codenil/bank/"..game.GetMap():lower().."/bankpos.txt", Pos.x..","..Pos.y..","..Pos.z..","..Ang.p..","..Ang.y..","..Ang.r, "DATA")
		else
			SpecialPrint(Plr, "Cannot do that, must be admin, also can't be console.")
		end
	end
end)

local function SetBankMoney(Money)
	SetGlobalInt("BankMoney", Money)
	if BankMoneyEntity then
		BankMoneyEntity:RefreshModel()
	end
	if RPExtraTeams then
		for i, v in pairs(RPExtraTeams) do
			if v.banker then
				if not v.defaultsalary then
					v.defaultsalary = v.salary
				end
				v.salary = v.defaultsalary + BANK.BankerSalaryAddition * (Money/BANK.MoneyMax)
				for _, x in pairs(player.GetAll()) do
					if x:Team() == i then
						x:setDarkRPVar("salary", v.salary)
					end
				end
			end
		end
	end
end

local function CompleteRobbery()
	local Takeaway = GetGlobalFloat("BankTakeaway")
	SetBankMoney(math.max(GetGlobalInt("BankMoney", 0) - Takeaway, 0))
	if IsValid(BankRobber) then
		BankRobber:addMoney(Takeaway)
	end
	EndBankRobbery("You have successfully stolen $"..Takeaway.." from the bank.", true)
end

function AddBankTakeaway()
	SetGlobalFloat("BankTakeaway", math.min(GetGlobalFloat("BankTakeaway") + BANK.MoneyMax/(BANK.RobberyTime * 20), GetGlobalInt("BankMoney", 0)))
	if GetGlobalFloat("BankTakeaway") == GetGlobalInt("BankMoney", 0)then
		if not NotifiedRobber then
			NotifiedRobber = true
			DarkRP.notify(BankRobber, 1, 8, "You have grabbed all the money in the bank, flee now and it is yours.")
		end
	end
end

function EndBankRobbery(Message, Success)
	if IsValid(BankRobber) then
		DarkRP.notify(BankRobber, 1, 8, Message)
		BankRobber:SetNWBool("Robber", false)
		
		BankRobber:setDarkRPVar("wanted", nil)
		BankRobber:setDarkRPVar("wantedReason", nil)
	end
	
	if BANK.NotifyPolice then
		for _, v in pairs(player.GetAll()) do
			if v:isCP() then
				DarkRP.notify(v, 1, 8, Success and "The bank robbery has been robbed, the perpetrator is still out there, catch him!" or "The bank robber has been stopped!")
			end
			if RPExtraTeams and RPExtraTeams[v:Team()] and RPExtraTeams[v:Team()].banker then
				DarkRP.notify(v, 1, 8, "The bank is being robbed!")
				for _, x in pairs(player.GetAll()) do
					if v == x:GetEmployer() then
						DarkRP.notify(x, 1, 8, Success and "The bank robbery has been robbed, the perpetrator is still out there, catch him!" or "The bank robber has been stopped!")
					end
				end
			end
		end
	end
	
	SetGlobalBool("BankRobbery", false)
	BankRobber = nil
end

hook.Add("PlayerDeath", "BankPlayerDeath", function(Plr)
	if BankRobber == Plr then
		EndBankRobbery("Your bank robbery attempt has ended, all money has been returned.", false)
	end
end)

hook.Add("PlayerDisconnected", "BankPlayerDisconnected", function(Plr)
	if BankRobber == Plr then
		EndBankRobbery("Your bank robbery attempt has ended, all money has been returned.", false)
	end
end)

hook.Add("playerArrested", "BankPlayerArrested", function(Plr)
	if BankRobber == Plr then
		EndBankRobbery("Your bank robbery attempt has ended, all money has been returned.", false)
	end
end)

hook.Add("Think", "BankThink", function(Plr)
	if IsValid(BankRobber) and IsValid(BankMoneyEntity) then
		if BankMoneyEntity:GetPos():Distance(BankRobber:GetPos()) > BANK.RobberyDistance then
			if GetGlobalFloat("BankTakeaway", 0) == 0 then
				EndBankRobbery("You have ran with nothing, bank robbery failed.", true)
			else
				CompleteRobbery()
			end
		end
	else
		EndBankRobbery("Your bank robbery attempt has ended, all money has been returned.", false)
	end
end)

function BeginBankRobbery(Plr)
	if GetGlobalInt("BankMoney", 0) <= 0 then
		return
	end
	
	if GetGlobalBool("BankRobbery", false) then
		--DarkRP.notify(Plr, 1, 4, "A robbery is already in progress.")
		return
	end
	
	if RPExtraTeams and RPExtraTeams[Plr:Team()] and RPExtraTeams[Plr:Team()].category == "Civil Protection" then
		DarkRP.notify(Plr, 1, 4, "You cannot rob the bank, "..team.GetName(Plr:Team()).." is a civil servant, you serve the government and law.")
		return
	end
	
	if RPExtraTeams and RPExtraTeams[Plr:Team()] and RPExtraTeams[Plr:Team()].banker then
		DarkRP.notify(Plr, 1, 4, "You cannot steal from yourself.")
		return
	end

	if Plr.GetEmployer and Plr:GetEmployer() then
		for _, v in pairs(player.GetAll()) do
			if v == Plr:GetEmployer() then
				DarkRP.notify(Plr, 1, 4, "You cannot steal from your employer.")
				return
			end
		end
	end
	
	if GetGlobalInt("BankMoney", 0) < BANK.MoneyMin then
		DarkRP.notify(Plr, 1, 4,  "There must be atleast $"..BANK.MoneyMin.." in the bank to rob it.")
		return
	end
	
	--[[if #player.GetAll() < BANK.PlayersRequired then
		DarkRP.notify(Plr, 1, 4, BANK.PlayersRequired.." players are required to rob the bank.")
		return
	end
	
	local TotalPolice, TotalBankers = 0, 0
	for _, v in pairs(player.GetAll()) do
		if v:isCP() then
			TotalPolice = TotalPolice + 1
		end
		if RPExtraTeams and RPExtraTeams[v:Team()] and RPExtraTeams[v:Team()].banker then
			TotalBankers = TotalBankers + 1
		end
	end
	if TotalPolice < Bank.PoliceRequired then
		DarkRP.notify(Plr, 1, 4, BANK.PoliceRequired.." police "..(BANK.PoliceRequired <= 1 and "is" or "are").." required to rob the bank.")
		return
	end
	if TotalBankers < Bank.BankersRequired then
		DarkRP.notify(Plr, 1, 4, BANK.TotalBankers.." banker"..(BANK.BankersRequired <= 1 and " is" or "s are").." required to rob the bank.")
		return
	end]]
	
	if BANK.NotifyPolice then
		for _, v in pairs(player.GetAll()) do
			if v:isCP() then
				DarkRP.notify(v, 1, 8, "The bank is being robbed!")
			end
			if RPExtraTeams and RPExtraTeams[v:Team()] and RPExtraTeams[v:Team()].banker then
				DarkRP.notify(v, 1, 8, "The bank is being robbed!")
				for _, x in pairs(player.GetAll()) do
					if v == x:GetEmployer() then
						DarkRP.notify(x, 1, 8, "The bank is being robbed!")
					end
				end
			end
		end
	end
	
	SetGlobalBool("BankRobbery", true)
	BankRobber = Plr
	BankRobber:SetNWBool("Robber", true)
	SetGlobalFloat("BankTakeaway", 0)
	NotifiedRobber = false
	
	BankRobber:setDarkRPVar("wanted", true)
    BankRobber:setDarkRPVar("wantedReason", "Bank robbery")
	
	DarkRP.notify(Plr, 1, 4, "Bank robbery started.")
end

hook.Add("PostGamemodeLoaded", "BankPostGamemodeLoaded", function()
	SetBankMoney(GetGlobalInt("BankMoney", 0))
end)
SetBankMoney(GetGlobalInt("BankMoney"), 0)

concommand.Add("setbankmoney", function(Plr, Cmd, Args)
	if not IsValid(Plr) or Plr:IsAdmin() then
		if #Args == 1 and tonumber(Args[1]) then
			SetBankMoney(tonumber(Args[1]) <= 1 and tonumber(Args[1]) * BANK.MoneyMax or math.min(tonumber(Args[1]), BANK.MoneyMax))
		else
			SpecialPrint(Plr, "Invalid arguments to run setbankmoney.")
		end
	else
		SpecialPrint(Plr, "Cannot do that, must be admin or console.")
	end
end)

timer.Create("BankMoneyIncrease", BANK.AddMoneyDelay, 0, function()
	if not GetGlobalBool("BankRobbery", false) then
		SetBankMoney(math.max(math.min(GetGlobalInt("BankMoney") + BANK.AddMoneyAmount, BANK.MoneyMax > 0 and BANK.MoneyMax or math.huge), 0))
	end
end)

--[[
function BANK_Initlize()
	BANK_AddMoneyTimer()
	SetGlobalInt( "BANK_VaultAmount", 0 )
	BankIsBeingRobbed = false
end
timer.Simple(1, function() 
	BANK_Initlize() 
end)

function BANK_PlayerDeath( ply, inflictor, attacker )
	if ply.IsRobbingBank then
		DarkRP.notify(ply, 1, 5,  "You have failed to rob the bank!")
		ply:unWanted(nil)
		attacker:addMoney(BANK_Custom_KillReward)
		
		for k, v in pairs(player.GetAll()) do
			if table.HasValue( GAMEMODE.CivilProtectionJobs, v:Team() ) then
				DarkRP.notify(v, 1, 7,  "The bank robbery has failed!")
			end
		end
		
		umsg.Start("BANK_KillTimer")
		umsg.End()
						
		ply.IsRobbingBank = false
		BankIsBeingRobbed = false
	end
end
hook.Add("PlayerDeath", "BANK_PlayerDeath", BANK_PlayerDeath)

function BANK_RobberyFailCheck()
	for k, v in pairs(player.GetAll()) do
		if v.IsRobbingBank then
			BankRobber = v
			break
		end
	end
	
	if IsValid(BankRobber) then
		for _, ent in pairs(ents.FindByClass("bank_vault")) do
			if ent:IsValid() && BankRobber:GetPos():Distance(ent:GetPos()) >= BANK_Custom_RobberyDistance then
				if BankIsBeingRobbed then
					DarkRP.notify(BankRobber, 1, 5,  "You have moved to far away from the bank vault, and the robbery has failed!")
					BankRobber:unWanted(nil)
					
					for k, v in pairs(player.GetAll()) do
						if table.HasValue( GAMEMODE.CivilProtectionJobs, v:Team() ) then
							DarkRP.notify(v, 1, 7,  "The bank robbery has failed!")
						end
					end
			
					umsg.Start("BANK_KillTimer")
					umsg.End()
									
					BankRobber.IsRobbingBank = false
					BankIsBeingRobbed = false
					BankRobber = nil
				end
			end
		end
	end
end
hook.Add("Tick", "BANK_RobberyFailCheck", BANK_RobberyFailCheck)

function BANK_BeginRobbery( ply )
	local RequiredTeamsCount = 0
	local RequiredPlayersCounted = 0
	
	for k, v in pairs(player.GetAll()) do
		RequiredPlayersCounted = RequiredPlayersCounted + 1
		
		if table.HasValue( GAMEMODE.CivilProtectionJobs, v:Team() ) then
			RequiredTeamsCount = RequiredTeamsCount + 1
		end
		
		if RequiredPlayersCounted == #player.GetAll() then
			if RequiredTeamsCount < BANK_Custom_PoliceRequired then
				DarkRP.notify(ply, 1, 5, "There has to be "..BANK_Custom_PoliceRequired.." police officers before you can rob the bank.")
				return
			end
		end
	end
	
	if BankCooldown then
		DarkRP.notify(ply, 1, 5,  "You cannot rob the bank yet!")
		return
	end
	if GetGlobalInt( "BANK_VaultAmount" ) <= 0 then
		DarkRP.notify(ply, 1, 5, "There are no money in the bank!")
		return
	end
	if BankIsBeingRobbed then
		DarkRP.notify(ply, 1, 5, "The bank is already being robbed!")
		return
	end
	if #player.GetAll() < BANK_Custom_PlayerLimit then
		DarkRP.notify(ply, 1, 5, "There must be "..BANK_Custom_PlayerLimit.." players before you can rob the bank.")
		return
	end
	if table.HasValue( GAMEMODE.CivilProtectionJobs, ply:Team() ) then
		DarkRP.notify(ply, 1, 5, "You are not allowed to rob the bank with your current team!")
		return
	end
	
	
	for k, v in pairs(player.GetAll()) do
		if table.HasValue( GAMEMODE.CivilProtectionJobs, v:Team() ) then
			DarkRP.notify(v, 1, 7,  "The bank is being robbed!")
		end
	end
	
	BankIsBeingRobbed = true
	DarkRP.notify(ply, 1, 5, "You have began a robbery on the bank!")
	DarkRP.notify(ply, 1, 10, "You must stay alive for ".. BANK_Custom_AliveTime .." minutes to receive the banks money.")
	DarkRP.notify(ply, 1, 13, "If you go to far away from the bank vault, the robbery will also fail!")
	ply.IsRobbingBank = true
	ply:wanted(nil, "Bank Robbery")
				
	umsg.Start("BANK_RestartTimer")
		umsg.Long(BANK_Custom_AliveTime * 60)
	umsg.End()
				
	timer.Simple( BANK_Custom_AliveTime * 60, function()
		if ply.IsRobbingBank then
			DarkRP.notify(ply, 1, 5,  "You have succesfully robbed the bank!")
			for k, v in pairs(player.GetAll()) do
				if table.HasValue( GAMEMODE.CivilProtectionJobs, v:Team() ) then
					DarkRP.notify(v, 1, 7,  "The bank robbery has succeseded and the money is now long gone!")
				end
			end
						
			ply:unWanted(nil)
			umsg.Start("BANK_KillTimer")
			umsg.End()
						
			BANK_StartCooldown()
						
			ply.IsRobbingBank = false
			
			if BANK_Custom_DropMoneyOnSucces then
				for _, ent in pairs(ents.FindByClass("bank_vault")) do
					DarkRP.createMoneyBag( ent:GetPos() + Vector(50, 0, 0), GetGlobalInt( "BANK_VaultAmount" ) )
					DarkRP.notify(ply, 1, 5,  "$"..util.RobberyFormatNumber(GetGlobalInt( "BANK_VaultAmount" )).." has dropped from the bank!")
				end
			else
				ply:addMoney( GetGlobalInt( "BANK_VaultAmount" ) )
				DarkRP.notify(ply, 1, 5,  "You have been given $"..util.RobberyFormatNumber(GetGlobalInt( "BANK_VaultAmount" )).." for succesfully robbing the bank.")
			end
						
			SetGlobalInt( "BANK_VaultAmount", 0 )
			BankIsBeingRobbed = false
		end
	end)
end

function BANK_StartCooldown()
	BankCooldown = true
	umsg.Start("BANK_RestartCooldown")
		umsg.Long(BANK_Custom_CooldownTime * 60)
	umsg.End()
	
	timer.Simple( BANK_Custom_CooldownTime * 60, function()
		BankCooldown = false
		umsg.Start("BANK_KillCooldown")
		umsg.End()
	end)
end

function BANK_AddMoneyTimer()
	timer.Create("BANK_MoneyTimer", BANK_CUSTOM_MoneyTimer, 0, function()
		if not BankIsBeingRobbed then
			if BANK_Custom_Max > 0 then
				SetGlobalInt( "BANK_VaultAmount", math.Clamp( (GetGlobalInt( "BANK_VaultAmount" ) + BANK_CUSTOM_MoneyOnTime), 0, BANK_Custom_Max) )
			else
				SetGlobalInt( "BANK_VaultAmount", (GetGlobalInt( "BANK_VaultAmount" ) + BANK_CUSTOM_MoneyOnTime) )
			end
		end
	end)
end

function BANK_Disconnect( ply )
	if ply.IsRobbingBank then
		ply:unWanted(nil)
			
		for k, v in pairs(player.GetAll()) do
			if table.HasValue( GAMEMODE.CivilProtectionJobs, v:Team())  then
				DarkRP.notify(v, 1, 7,  "The bank robbery has failed!")
			end
		end
			
		umsg.Start("BANK_KillTimer")
		umsg.End()
							
		ply.IsRobbingBank = false
		BankIsBeingRobbed = false
	end
end
hook.Add( "PlayerDisconnected", "BANK_Disconnect", BANK_Disconnect )]]