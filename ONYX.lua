local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "ONYX Hub",
   Icon = 0,
   LoadingTitle = "ONYX Hub",
   LoadingSubtitle = "by QERIX",
   ShowText = "ONYX Hub",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "ONYXHub",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = false
   },
   KeySystem = true,
   KeySettings = {
      Title = "ONYX Hub | Key",
      Subtitle = "Key system",
      Note = "https://link-hub.net/1392772/AfVHcFNYkLMx",
      FileName = "OnyxHubKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"AyamGoreng!"}
   }
})

-- NPC/Banana ESP
local function isPlayerCharacter(model)
   if not model or not model:IsA("Model") then return false end
   return Players:GetPlayerFromCharacter(model) ~= nil
end

local function isBananaOrNPC(model)
   if not model or not model:IsA("Model") then return false end
   if isPlayerCharacter(model) then return false end
   local hum = model:FindFirstChildWhichIsA("Humanoid")
   return hum ~= nil
end

local espEnabled = false
local espHighlights = {}
local espConns = {}
local npcHighlights = {}
local worldConns = {}

local function markNPC(model)
   if not espEnabled then return end
   if not isBananaOrNPC(model) then return end
   if npcHighlights[model] and npcHighlights[model].Parent then return end
   local ok, err = pcall(function()
      local hl = Instance.new("Highlight")
      hl.FillTransparency = 0.5
      hl.OutlineTransparency = 0
      hl.FillColor = Color3.fromRGB(85, 170, 255)
      hl.OutlineColor = Color3.fromRGB(0, 0, 0)
      hl.Adornee = model
      hl.Parent = model
      npcHighlights[model] = hl
   end)
   if not ok then
      warn("ESP markNPC error:", err)
   end
end

local function removeESP(player)
   if espHighlights[player] then
      espHighlights[player]:Destroy()
      espHighlights[player] = nil
   end
   local t = espConns[player]
   if t then
      if t.charAdded then t.charAdded:Disconnect() end
      if t.died then t.died:Disconnect() end
      espConns[player] = nil
   end
end

local function applyESPToChar(player, char)
   if not char then return end
   removeESP(player)
   local hl = Instance.new("Highlight")
   hl.FillTransparency = 0.5
   hl.OutlineTransparency = 0
   hl.FillColor = Color3.fromRGB(255, 85, 85)
   hl.OutlineColor = Color3.fromRGB(255, 255, 255)
   hl.Adornee = char
   hl.Parent = char
   espHighlights[player] = hl
   local hum = char:FindFirstChildWhichIsA("Humanoid")
   if hum then
      local diedConn = hum.Died:Connect(function()
         removeESP(player)
      end)
      espConns[player] = espConns[player] or {}
      espConns[player].died = diedConn
   end
end

local function attachESP(player)
   if player == LocalPlayer then return end
   if not espEnabled then return end
   local char = player.Character or player.CharacterAdded:Wait()
   applyESPToChar(player, char)
   local ca = player.CharacterAdded:Connect(function(c)
      if espEnabled then
         applyESPToChar(player, c)
      end
   end)
   espConns[player] = espConns[player] or {}
   espConns[player].charAdded = ca
end

local function scanWorldForNPCs()
   for _, inst in ipairs(workspace:GetDescendants()) do
      if inst:IsA("Model") then
         markNPC(inst)
      end
   end
end

local function enableESP()
   espEnabled = true
   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer then
         attachESP(player)
      end
   end
   task.spawn(function()
      task.wait(1)
      if espEnabled then scanWorldForNPCs() end
   end)
   if not worldConns.descAdded then
      worldConns.descAdded = workspace.DescendantAdded:Connect(function(inst)
         if not espEnabled then return end
         if inst:IsA("Model") then
            markNPC(inst)
         elseif inst:IsA("Humanoid") and inst.Parent and inst.Parent:IsA("Model") then
            markNPC(inst.Parent)
         end
      end)
   end
   Players.PlayerAdded:Connect(function(player)
      if espEnabled then
         attachESP(player)
      end
   end)
end

local Tab = Window:CreateTab("Main", 4483362458)
local Section = Tab:CreateSection("Toggles")

local noclipConn
local noclipCharConn
local noclipEnabled = false

local function applyNoclip(char)
   if not char then return end
   if noclipConn then noclipConn:Disconnect() noclipConn = nil end
   noclipConn = RunService.Stepped:Connect(function()
      if not noclipEnabled then return end
      if not char.Parent then return end
      for _, v in ipairs(char:GetDescendants()) do
         if v:IsA("BasePart") and v.CanCollide and v.Name ~= "HumanoidRootPart_OnyxFloat" then
            v.CanCollide = false
         end
      end
   end)
end

local function bindCharacter(char)
   if noclipCharConn then noclipCharConn:Disconnect() noclipCharConn = nil end
   noclipCharConn = char:WaitForChild("Humanoid").Died:Connect(function()
      if noclipConn then noclipConn:Disconnect() noclipConn = nil end
   end)
   applyNoclip(char)
end

local ToggleNoclip = Tab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "onyx_noclip",
   Callback = function(v)
      noclipEnabled = v
      if v then
         local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
         applyNoclip(char)
         LocalPlayer.CharacterAdded:Connect(function(nc)
            if noclipEnabled then applyNoclip(nc) end
         end)
      else
         if noclipConn then noclipConn:Disconnect() noclipConn = nil end
      end
   end,
})

local fbConn
local savedLighting

local function saveLighting()
   savedLighting = {
      Ambient = Lighting.Ambient,
      OutdoorAmbient = Lighting.OutdoorAmbient,
      Brightness = Lighting.Brightness,
      ClockTime = Lighting.ClockTime,
      FogEnd = Lighting.FogEnd,
      FogStart = Lighting.FogStart,
      GlobalShadows = Lighting.GlobalShadows,
      ExposureCompensation = Lighting.ExposureCompensation,
   }
end

local function restoreLighting()
   if not savedLighting then return end
   Lighting.Ambient = savedLighting.Ambient
   Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
   Lighting.Brightness = savedLighting.Brightness
   Lighting.ClockTime = savedLighting.ClockTime
   Lighting.FogEnd = savedLighting.FogEnd
   Lighting.FogStart = savedLighting.FogStart
   Lighting.GlobalShadows = savedLighting.GlobalShadows
   Lighting.ExposureCompensation = savedLighting.ExposureCompensation
end

local ToggleFullbright = Tab:CreateToggle({
   Name = "Fullbright",
   CurrentValue = false,
   Flag = "onyx_fullbright",
   Callback = function(v)
      if v then
         saveLighting()
         if fbConn then fbConn:Disconnect() fbConn = nil end
         fbConn = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
         end)
      else
         if fbConn then fbConn:Disconnect() fbConn = nil end
         restoreLighting()
      end
   end,
})

local nfConn
local savedAtmospheres = {}
local function setNoFog()
   Lighting.FogEnd = 100000
   for _, v in ipairs(Lighting:GetDescendants()) do
      if v:IsA("Atmosphere") then
         if not savedAtmospheres[v] then
            savedAtmospheres[v] = { Density = v.Density, Haze = v.Haze, Color = v.Color, Decay = v.Decay, Glare = v.Glare, Offset = v.Offset }
         end
         v.Density = 0
         v.Haze = 0
         v.Glare = 0
      end
   end
end

local function restoreAtmosphere()
   for atm, props in pairs(savedAtmospheres) do
      if atm and atm.Parent then
         atm.Density = props.Density
         atm.Haze = props.Haze
         atm.Color = props.Color
         atm.Decay = props.Decay
         atm.Glare = props.Glare
         atm.Offset = props.Offset
      end
   end
end

local ToggleNoFog = Tab:CreateToggle({
   Name = "No Fog",
   CurrentValue = false,
   Flag = "onyx_nofog",
   Callback = function(v)
      if v then
         saveLighting()
         setNoFog()
         if nfConn then nfConn:Disconnect() nfConn = nil end
         nfConn = RunService.RenderStepped:Connect(function()
            setNoFog()
         end)
      else
         if nfConn then nfConn:Disconnect() nfConn = nil end
         restoreAtmosphere()
         restoreLighting()
      end
   end,
})

local VisualsSection = Tab:CreateSection("Visuals")
local ToggleESP = Tab:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Flag = "onyx_esp",
   Callback = function(v)
      if v then
         enableESP()
      else
         disableESP()
      end
   end,
})

local MovementSection = Tab:CreateSection("Movement")

local desiredSpeed = 16
local speedEnabled = false
local speedLockConn
local speedCharConn

local function applySpeed(char)
   local hum = char and char:FindFirstChildWhichIsA("Humanoid")
   if not hum then return end
   hum.WalkSpeed = desiredSpeed
   if speedLockConn then speedLockConn:Disconnect() speedLockConn = nil end
   speedLockConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
      if hum.WalkSpeed ~= desiredSpeed then
         hum.WalkSpeed = desiredSpeed
      end
   end)
end

local SliderSpeed = Tab:CreateSlider({
   Name = "Speed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "WS",
   CurrentValue = 16,
   Flag = "onyx_speed",
   Callback = function(val)
      desiredSpeed = val
      if speedEnabled then
         local char = LocalPlayer.Character
         if char then applySpeed(char) end
      end
   end,
})

local ToggleSpeed = Tab:CreateToggle({
   Name = "Speed (Lock)",
   CurrentValue = false,
   Flag = "onyx_speed_lock",
   Callback = function(v)
      speedEnabled = v
      if v then
         local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
         applySpeed(char)
         if speedCharConn then speedCharConn:Disconnect() speedCharConn = nil end
         speedCharConn = LocalPlayer.CharacterAdded:Connect(function(c)
            if speedEnabled then
               applySpeed(c)
            end
         end)
      else
         if speedLockConn then speedLockConn:Disconnect() speedLockConn = nil end
         if speedCharConn then speedCharConn:Disconnect() speedCharConn = nil end
      end
   end,
})
