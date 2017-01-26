include("shared.lua")

local SelfEnt

surface.CreateFont("BankHeader", {
	font = "Tahoma",
	size = 42,
	weight = 1000,
	antialias = true
})
surface.CreateFont("BankMoney", {
	font = "Tahoma",
	size = 30,
	weight = 1000,
	antialias = true
})
surface.CreateFont("BankInfo", {
	font = "Tahoma",
	size = 20,
	weight = 1000,
	antialias = true
})

local SphereMat = Material("vertexlitgeneric")
hook.Add("PostDrawOpaqueRenderables", "BankWorldRenders", function()
	local Plr = LocalPlayer()
	if LocalPlayer():GetNWBool("Robber", false) and IsValid(SelfEnt) then
		local PlrPos = Plr:EyePos()
		local Pos = SelfEnt:GetPos() + SelfEnt:GetAngles():Up() * 3.68
		local Dist = Pos:Distance(PlrPos)
		
		render.SetColorMaterial()
		render.DrawSphere(Pos, -BANK.RobberyDistance, 50, 50, Color(Dist/BANK.RobberyDistance * 255, 50, 50, 100))
		if Dist > BANK.RobberyDistance - 300 then
			Dist = (Dist - (BANK.RobberyDistance - 300))/300
			
			local Ang = Angle()
			Ang:RotateAroundAxis(Ang:Up(), (PlrPos - Pos):Angle().y)
			Ang:RotateAroundAxis(Ang:Right(), (PlrPos.z - Pos.z)/BANK.RobberyDistance * 60)
			Pos:Add(Ang:Forward() * BANK.RobberyDistance)
			Ang:RotateAroundAxis(Ang:Right(), 90)
			Ang:RotateAroundAxis(Ang:Up(), -90)
			
			local Takeaway = math.Round(GetGlobalInt("BankTakeaway", 0))
			local Text = Takeaway == 0 and "Flee with nothing" or "Flee with $"..Takeaway
			
			surface.SetFont("BankInfo")
			local w, h = surface.GetTextSize(Text)
			w = w + 25
			local x, y = -w/2, -h/2
			
			cam.Start3D2D(Pos, Ang, 0.5)
				surface.SetDrawColor(Color(255, 0, 0, 255 * Dist))
				surface.DrawRect(x, y, w, h)
				
				draw.SimpleTextOutlined(Text, "BankInfo", 0, 0, Color(255, 255, 255, 255 * Dist), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255 * Dist))
			cam.End3D2D()
		end
	end
end)

local function GetMat(Name, Texture, Matrix)
	local Data = {
		["$basetexture"] = Texture,
		["$model"] = 1,
		--["$basetexturetransform"] = Matrix
	}
	local Mat = CreateMaterial(Name, "VertexLitGeneric", Data)
	timer.Simple(1, function()
		Mat:SetMatrix("$basetexturetransform", Matrix)
	end)
	return Mat
end

local TopMatrix = Matrix()
TopMatrix:Scale(Vector(4, 4, 4))
local FrontMatrix = Matrix()
FrontMatrix:Scale(Vector(6, 8, 4))
local SideMatrix = Matrix()
SideMatrix:Scale(Vector(6, 4, 4))

local TopMat = GetMat("bankmoneymattop", "models/props/cs_assault/moneytop", TopMatrix)
local FrontMat = GetMat("bankmoneymatfront", "models/props/cs_assault/moneyshort", FrontMatrix)
local SideMat = GetMat("bankmoneymatside", "models/props/cs_assault/moneylong", SideMatrix)

local MoneyWidth = 60

local WhiteColor = Color(255, 255, 255)
local function DrawQuad(Pos, Normal, Width, Height, Mat, Rotation)
	if Mat then
		render.SetMaterial(Mat)
	end
	render.DrawQuadEasy(Pos, Normal, Width, Height, WhiteColor, Rotation or 0)
end

local MatLoaded = false
function ENT:Draw()
	self:DrawModel()
	
	if not SelfEnt then
		SelfEnt = self
	end
	
	local Money = GetGlobalInt("BankMoney", 0)
	local MoneyPercent = math.min(Money/BANK.MoneyMax, 1)
	local MoneyHeight = MoneyPercent * 50
	
	local Plr = LocalPlayer()
	local PlrPos = Plr:EyePos()
	local Ang = self:GetAngles()
	local Pos = self:GetPos() + Ang:Up() * (3.68 + MoneyHeight/2)
	
	if MoneyHeight > 0 then
		if not MatLoaded then
			MatLoaded = true
			TopMat:SetMatrix("$basetexturetransform", TopMatrix)
			FrontMat:SetMatrix("$basetexturetransform", FrontMatrix)
			SideMat:SetMatrix("$basetexturetransform", SideMatrix)
		end
		
		local Forward, Right, Up = Ang:Forward(), Ang:Right(), Ang:Up()
		
		DrawQuad(Pos + Forward * MoneyWidth/2, Forward, MoneyHeight, MoneyWidth, FrontMat, 90)
		DrawQuad(Pos - Forward * MoneyWidth/2, -Forward, MoneyHeight, MoneyWidth, nil, -90)
		
		DrawQuad(Pos + Right * MoneyWidth/2, Right, MoneyHeight, MoneyWidth, SideMat, 90)
		DrawQuad(Pos - Right * MoneyWidth/2, -Right, MoneyHeight, MoneyWidth, nil, -90)
		
		DrawQuad(Pos + Up * MoneyHeight/2, Vector(Forward.x, Forward.y, Forward.z + 360), MoneyWidth, MoneyWidth, TopMat)
	end
	
	local IsTop, ClosestN, ClosestFace = false
	local SClosestN, SClosestFace
	if MoneyPercent >= 0.5 then
		local ClosestDist, SClosestDist = 500, 500
		local Faces = {Pos + Ang:Forward() * (MoneyWidth/2 + 0.1), Pos + Ang:Right() * (MoneyWidth/2 + 0.1), Pos - Ang:Forward() * (MoneyWidth/2 + 0.1), Pos - Ang:Right() * (MoneyWidth/2 + 0.1)}
		for i, v in pairs(Faces) do
			local Dist = v:Distance(PlrPos)
			if Dist < ClosestDist then
				ClosestFace, ClosestN, ClosestDist = v, i, Dist
			end
		end
		for i, v in pairs(Faces) do
			local Dist = v:Distance(PlrPos)
			if Dist < SClosestDist and Dist > ClosestDist then
				SClosestFace, SClosestN, SClosestDist = v, i, Dist
			end
		end
	else
		local Face = Pos + Ang:Up() * (MoneyHeight/2 + 1)
		local Dist = Face:Distance(PlrPos)
		if Dist < 500  then
			ClosestFace, IsTop = Face, true
		end
	end
	if ClosestFace then
		local Robbery = GetGlobalBool("BankRobbery", false)
		local Takeaway = math.Round(GetGlobalInt("BankTakeaway", 0))
		local Text3 = Robbery and "Takeaway: $"..Takeaway or (Money < BANK.MoneyMin and "Not enough money to steal." or "Hold use key to rob")
		
		surface.SetFont("BankHeader")
		local w1, h1 = surface.GetTextSize("Bank")
		surface.SetFont("BankMoney")
		local w2, h2 = surface.GetTextSize("$"..Money)
		surface.SetFont("BankInfo")
		local w3, h3 = surface.GetTextSize(Text3)
		local w = math.max(w1, w2, w3) + 25
		local h = math.max(h1, h2, h3) * 3
		local x, y = -w/2, -h/2
		
		if IsTop then
			Ang = Angle()
			Ang:RotateAroundAxis(Ang:Up(), (PlrPos - ClosestFace):Angle().y + 90)
		else
			Ang:RotateAroundAxis(Ang:Right(), -90)
			Ang:RotateAroundAxis(Ang:Up(), 90)
			Ang:RotateAroundAxis(Ang:Right(), (ClosestN - 1) * 90)
		end
		
		cam.Start3D2D(ClosestFace, Ang, IsTop and 0.2 or 0.15)
			surface.SetDrawColor(Color(0, 0, 0, 240))
			surface.DrawRect(x, y, w, h)
			
			draw.SimpleTextOutlined("Bank", "BankHeader", 0, -40, Robbery and Color(255, 50, 50) or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			draw.SimpleTextOutlined("$"..Money, "BankMoney", 0, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			draw.SimpleTextOutlined(Text3, "BankInfo", 0, 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
		cam.End3D2D()
		
		if SClosestFace and SClosestFace ~= ClosestFace then
			Ang:RotateAroundAxis(Ang:Right(), (ClosestN - 1) * -90 + (SClosestN - 1) * 90)
			cam.Start3D2D(SClosestFace, Ang, 0.15)
				surface.SetDrawColor(Color(0, 0, 0, 240))
				surface.DrawRect(x, y, w, h)
				
				draw.SimpleTextOutlined("Bank", "BankHeader", 0, -40, Robbery and Color(255, 50, 50) or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
				draw.SimpleTextOutlined("$"..Money, "BankMoney", 0, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
				draw.SimpleTextOutlined(Text3, "BankInfo", 0, 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			cam.End3D2D()
		end
	end
end

--[[DrawEnts = DrawEnts or {}

local MoneyScale = 2
local MoneyWidth = 3.67 * MoneyScale
local MoneyLength = 8 * MoneyScale
local MoneyHeight = 0.74 * MoneyScale
local MoneyColumns = 20/MoneyScale
local MoneyRows = 8/MoneyScale
local MoneyVertical = 50/MoneyScale

local MoneyAmount = MoneyColumns * MoneyRows * MoneyVertical

local function AddDrawEnt()
	local New = ClientsideModel("models/props/cs_assault/money.mdl", RENDERGROUP_STATIC)
	New:SetModelScale(MoneyScale)
	DrawEnts[#DrawEnts + 1] = New
end

function ENT:Draw()
	self:DrawModel()
	
	if #DrawEnts < MoneyAmount then
		for i = 1, MoneyAmount - #DrawEnts do
			AddDrawEnt()
		end
	end
	
	local Pos = self:GetPos()
	local Ang = self:GetAngles()
	Pos:Add(Ang:Up() * 3.68)
	Pos:Add(Ang:Forward() * MoneyLength * (-MoneyRows/2 + 0.5))
	Pos:Add(Ang:Right() * MoneyWidth * (-MoneyColumns/2 - 0.5))
	local Settings = {model = "models/props/cs_assault/money.mdl", pos = Pos, angle = self:GetAngles()}
	local PosZOffset = self:GetAngles():Right() * MoneyWidth
	local PosXOffset = self:GetAngles():Forward() * MoneyLength - PosZOffset * MoneyColumns
	local PosYOffset = self:GetAngles():Up() * MoneyHeight - self:GetAngles():Forward() * MoneyLength * MoneyRows
	local i = 1
	for y = 1, MoneyVertical do
		for x = 1, MoneyRows do
			for z = 1, MoneyColumns do
				Settings.pos:Add(PosZOffset)
				if y == MoneyVertical or (x == 1 or x == MoneyRows or z == 1 or z == MoneyColumns) then
					render.Model(Settings, DrawEnts[i])
					i = i + 1
				end
			end
			Settings.pos:Add(PosXOffset)
		end
		Settings.pos:Add(PosYOffset)
	end
end]]