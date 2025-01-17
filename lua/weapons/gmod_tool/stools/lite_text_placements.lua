TOOL.Category = "Lite Tools"
TOOL.Name = "#tool.lite_text_placements.name"
TOOL.Information = {
	{name = "left"}
}

local sepColor = Color(0, 0, 0)
local amtLines = 5

for i=1, amtLines do
	TOOL.ClientConVar["text"..i] = ""
	TOOL.ClientConVar["size"..i] = "50"
	TOOL.ClientConVar["r"..i] = "255"
	TOOL.ClientConVar["g"..i] = "255"
	TOOL.ClientConVar["b"..i] = "255"
	TOOL.ClientConVar["a"..i] = "255"
end

if SERVER then
	CreateConVar("sbox_maxtextplacements", "3", {FCVAR_NOTIFY, FCVAR_REPLICATED})	
end

if CLIENT then
	language.Add("tool.lite_text_placements.name", "Text Placement")	
	language.Add("tool.lite_text_placements.desc", "Place text on a wall.")	
    language.Add("tool.lite_text_placements.left", "Place the text.")
    language.Add("tool.lite_text_placements.right", "Update existing text.")

	for i=1, amtLines do
		language.Add("tool.lite_text_placements.text"..i, "Line "..i)
		language.Add("tool.lite_text_placements.text"..i..".help", "The text for line "..i..".")
		language.Add("tool.lite_text_placements.size"..i, "Line "..i.." Text Size")
		language.Add("tool.lite_text_placements.size"..i..".help", "The size of the text.")
		language.Add("tool.lite_text_placements.color"..i, "Line "..i.." Text Color")
		language.Add("tool.lite_text_placements.color"..i..".help", "The color of the text.")
	end

	language.Add("SBoxLimit_textplacements", "You've hit the text placement limit!")
end

function TOOL:BuildLines()
	local lines = {}
	for i=1, amtLines do
		lines[i] = self:GetClientInfo("text"..i)
	end
	for i=amtLines, 1, -1 do
		if not (lines[i] == "") then break end
		lines[i] = nil
	end

	return lines
end

function TOOL:CreateEntity(trace)
	local newEnt = ents.Create("lite_text")
	newEnt:SetPos(trace.HitPos)

	local angle = trace.HitNormal:Angle()
	angle:RotateAroundAxis(trace.HitNormal:Angle():Right(), -90)
	angle:RotateAroundAxis(trace.HitNormal:Angle():Forward(), 90)
	newEnt:SetAngles(angle)

	newEnt:Spawn()
	newEnt:Activate()

	return newEnt
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()

	if not ply:CheckLimit("textplacements") then return end
	local text = self:BuildLines()
	if not text then return end

	local ent = self:CreateEntity(trace)
	for k, v in pairs(text) do
		if k > amtLines then continue end -- Just a failsafe to make sure nothing goes wrong
		ent:SetText(k, v)
		ent:SetTextColor(k, Color(math.Clamp(self:GetClientNumber("r"..k, 255), 0, 255), math.Clamp(self:GetClientNumber("g"..k, 255), 0, 255), math.Clamp(self:GetClientNumber("b"..k, 255), 0, 255)))
		ent:SetTextSize(k, math.Clamp(self:GetClientNumber("size"..k, 50), 30, 100))
	end

	ply:AddCount("textplacements", ent)
	ply:AddCleanup("textplacements", ent)
	undo.Create("lite_text_placements")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()

	return true
end

local ConVarsDefault = TOOL:BuildConVarList()
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {Text = "#tool.lite_text_placements.name", Description = "#tool.lite_text_placements.desc"})
		
	panel:AddControl("ComboBox", {MenuButton = 1, Folder = "lite_text_placements", Options = {["#preset.default"] = ConVarsDefault}, CVars = table.GetKeys(ConVarsDefault)})

	for i=1, amtLines do
		panel:AddControl("Header", {Text = "#tool.lite_text_placements.text"..i, Description = "#tool.lite_text_placements.text"..i})
		panel:AddControl("textbox", {Label = "#tool.lite_text_placements.text"..i, Command = "lite_text_placements_text"..i, MaxLenth = "30"})
		panel:AddControl("Slider", {Label = "#tool.lite_text_placements.size"..i, Command = "lite_text_placements_size"..i, Type = "Int", Min = 30, Max = 100})
		panel:AddControl("Color", {Label = "#tool.lite_text_placements.color"..i, Red = "lite_text_placements_r"..i, Green = "lite_text_placements_g"..i, Blue = "lite_text_placements_b"..i, Alpha = "lite_text_placements_a"..i})
		
		if i >= amtLines then continue end

		local x = vgui.Create('DPanel', panel)
		x:DockMargin(5, 15, 5, 5)
		x:Dock(TOP)
		x:SetTall(3)
		x.Paint = function(s, w, h)
			draw.RoundedBox(0, 0, 0, w, h, sepColor)
		end
	end
end
