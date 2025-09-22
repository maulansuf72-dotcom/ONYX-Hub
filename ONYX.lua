-- ONYX v0.1 for 99 Nights in the Forest

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local function getChar() return LocalPlayer and LocalPlayer.Character end

-- Window (template)
local Window = WindUI:CreateWindow({
    Title = "ONYX Hub",
    Author = "",
    NewElements = true,
})

--Window:SetTitle(Window.Title .. " | " .. WindUI.Version)

Window:EditOpenButton({
    Title = "Open ONYX Hub UI",
    CornerRadius = UDim.new(1,0),
    StrokeThickness = 0,
    Enabled = true,
    Draggable = true,
    -- Icon = "monitor",
    -- Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    -- OnlyMobile = false,
})

-- Section (template)
local ElementsSection = Window:Section({
    Title = "Elements",
})

-- Global state (must be declared before any tabs use them)
local KA = {
    enabled = false,
    showRadius = true,
    radius = 500,
    target = "All",
}

local ESP = { mobs = false, items = false, players = false }
local TP = { playerTarget = nil }
local AUTO = { interact = false, interactRadius = 25 }
local MOVE = { walkspeed = 16, jumppower = 50, noclip = false }
local WORLD = { nightVision = false, noFog = false }
local MAIN = { expandHitbox=false, hitboxSize=50, autoBandage=false, healBelow=40, autoEat=false, eatBelow=50, eatFoods={"Carrot","Apple","Berry","Meat","Morsel"} }
local PLAY = { antiAFK=false, fly=false, flySpeed=50, infiniteJump=false }
local FISH = { autoCast=false, autoMini=false, bigBar=false, mode="Teleport" }

-- Tab: Auto (collect/rescue/campfire/chest)
do
    local AutoTab = ElementsSection:Tab({ Title = "Auto", Icon = "bolt" })
    local auto2 = { flowers=false, coins=false, chestOpen=false, rescueKids=false, fuel=false, fuelType="Log", startFuel=50 }
    AutoTab:Toggle({ Title = "AutoCollect Flowers", Callback = function(v) auto2.flowers = v and true or false end })
    AutoTab:Toggle({ Title = "AutoCollect Coins", Callback = function(v) auto2.coins = v and true or false end })
    AutoTab:Toggle({ Title = "Open All Chest", Callback = function(v) auto2.chestOpen = v and true or false end })
    AutoTab:Toggle({ Title = "Auto Rescue Kids", Callback = function(v) auto2.rescueKids = v and true or false end })
    AutoTab:Toggle({ Title = "Auto Fuel Campfire", Callback = function(v) auto2.fuel = v and true or false end })
    if type(AutoTab.Dropdown) == "function" then
        AutoTab:Dropdown({ Title = "Select Fuels", List = {"Log","Coal","Fuel","Wood"}, Selected = auto2.fuelType, Callback = function(o) auto2.fuelType=o end })
    end
    if type(AutoTab.Slider) == "function" then
        AutoTab:Slider({ Title = "Start Fueling When", Min=10, Max=95, Default=auto2.startFuel, Callback=function(v) auto2.startFuel = math.clamp(tonumber(v) or auto2.startFuel,10,95) end })
    end

    -- background worker
    task.spawn(function()
        while true do
            task.wait(0.3)
            local char = getChar(); local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local function collectByKeys(keys, radius)
                local target = nearestInstanceByNameContains(hrp.Position, keys)
                if target then
                    local pos
                    if target:IsA("Model") then local p = target.PrimaryPart or getHRP(target); pos = p and p.Position elseif target:IsA("BasePart") then pos = target.Position end
                    if pos and (pos - hrp.Position).Magnitude <= (radius or 200) then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0,2,0))
                        for _, pp in ipairs((target:IsA("Model") and target:GetDescendants()) or {}) do
                            if pp:IsA("ProximityPrompt") and pp.Enabled then pcall(function() fireproximityprompt(pp) end) end
                        end
                    end
                end
            end

            if auto2.flowers then collectByKeys({"flower"}, 300) end
            if auto2.coins then collectByKeys({"coin"}, 300) end
            if auto2.chestOpen then collectByKeys({"chest","crate"}, 500) end
            if auto2.rescueKids then collectByKeys({"child","kid"}, 600) end
            if auto2.fuel then collectByKeys({string.lower(auto2.fuelType or "log")}, 500) collectByKeys({"campfire","bonfire"}, 500) end
        end
    end)
end

-- Tab: Visuals (FPS Boost & ESP reveals)
do
    local VisTab = ElementsSection:Tab({ Title = "Visuals", Icon = "eye" })
    local Lighting = game:GetService("Lighting")
    local overlay
    VisTab:Toggle({ Title = "Full Bright", Callback=function(v) pcall(function() if v then Lighting.Brightness=3 Lighting.ExposureCompensation=0.6 else Lighting.Brightness=1 Lighting.ExposureCompensation=0 end end) end })
    VisTab:Toggle({ Title = "Lower Graphics", Callback=function(v) pcall(function() settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic end) end })
    VisTab:Toggle({ Title = "Blackscreen", Callback=function(v)
        pcall(function()
            if v then
                if not overlay then overlay = Instance.new("ScreenGui"); overlay.Name = "ONYX_Black"; overlay.ResetOnSpawn=false; overlay.Parent = game:GetService("CoreGui"); local f=Instance.new("Frame", overlay); f.BackgroundColor3=Color3.new(0,0,0); f.Size=UDim2.fromScale(1,1) end
            else
                if overlay then overlay:Destroy() overlay=nil end
            end
        end)
    end })
    VisTab:Toggle({ Title = "Reveal Locations", Desc = "Enable multiple ESPs", Callback=function(v) ESP.mobs=v ESP.items=v ESP.players=v end })
end

-- Tab: Players (movement & anti)
do
    local PTab = ElementsSection:Tab({ Title = "Players", Icon = "user" })
    PTab:Toggle({ Title = "AntiAFK", Callback=function(v)
        PLAY.antiAFK = v and true or false
        if v then
            local vu = game:GetService("VirtualUser")
            if not PLAY._afkConn then
                PLAY._afkConn = Players.LocalPlayer.Idled:Connect(function()
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end
        else
            if PLAY._afkConn then pcall(function() PLAY._afkConn:Disconnect() end) PLAY._afkConn=nil end
        end
    end })

    PTab:Toggle({ Title = "Fly", Callback=function(v) PLAY.fly = v and true or false end })
    if type(PTab.Slider) == "function" then
        PTab:Slider({ Title = "Fly Speed", Min=10, Max=300, Default=PLAY.flySpeed, Callback=function(val) PLAY.flySpeed = math.clamp(tonumber(val) or PLAY.flySpeed,10,300) end })
    end
    PTab:Toggle({ Title = "Infinite Jump", Callback=function(v) PLAY.infiniteJump = v and true or false end })
end

-- Tab: Settings (Config save/load; best-effort if exploit supports filesystem)
do
    local STab = ElementsSection:Tab({ Title = "Settings", Icon = "gear" })
    local cfg = { name = "Default" }
    STab:Input({ Title = "Config Name", Callback=function(t) if t and #t>0 then cfg.name=t end end })
    STab:Button({ Title = "Save Config", Callback=function()
        local ok, err = pcall(function()
            if writefile then
                local data = game:GetService("HttpService"):JSONEncode({KA=KA, ESP=ESP, TP=TP, AUTO=AUTO, MOVE=MOVE, WORLD=WORLD, MAIN=MAIN, PLAY=PLAY, FISH=FISH})
                writefile("ONYX_"..cfg.name..".json", data)
            end
        end)
        WindUI:Notify({ Title = "ONYX", Desc = ok and "Config saved" or ("Save failed: "..tostring(err)), Time=4 })
    end })
    STab:Button({ Title = "Load Config", Callback=function()
        local ok, data = pcall(function() if readfile then return readfile("ONYX_"..cfg.name..".json") end end)
        if ok and data then
            local ok2, tbl = pcall(function() return game:GetService("HttpService"):JSONDecode(data) end)
            if ok2 and tbl then KA=tbl.KA or KA ESP=tbl.ESP or ESP TP=tbl.TP or TP AUTO=tbl.AUTO or AUTO MOVE=tbl.MOVE or MOVE WORLD=tbl.WORLD or WORLD MAIN=tbl.MAIN or MAIN PLAY=tbl.PLAY or PLAY FISH=tbl.FISH or FISH end
            WindUI:Notify({ Title = "ONYX", Desc = "Config loaded", Time=4 })
        else
            WindUI:Notify({ Title = "ONYX", Desc = "Load failed or unsupported exploit", Time=4 })
        end
    end })
end
-- Helpers
local function strContains(hay, needle)
    if typeof(hay) ~= "string" or typeof(needle) ~= "string" then return false end
    return string.find(string.lower(hay), string.lower(needle), 1, true) ~= nil
end

-- Mob detection (generic; can be refined with your game’s tags/folders)
local function isMobModel(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return false end

    -- Prefer tags if the game uses them
    local tagged = false
    pcall(function()
        if CollectionService:HasTag(model, "Enemy") or CollectionService:HasTag(model, "Mob") then
            tagged = true
        end
    end)
    if tagged then return true end

    -- Fallback by name
    local n = model.Name or ""
    for _, key in ipairs({
        "bunny","frog","scorpion","wolf","alpha","bear","polar","arctic","fox",
        "mammoth","cultist","crossbow","juggernaut","alien","boar","deer","tiger","spider","creature","beast"
    }) do
        if strContains(n, key) then return true end
    end
    return false
end

local function targetMatches(model, selected)
    if selected == "All" then
        return true -- kill everything considered a mob (even if not in the list)
    end
    return strContains(model.Name or "", selected)
end

local function getTargetsInRadius(originPos, radius, selected)
    local results = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("Model") and isMobModel(inst) and targetMatches(inst, selected) then
            local hrp = inst:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - originPos).Magnitude <= radius then
                table.insert(results, inst)
            end
        end
    end
    return results
end

-- Default kill method (can be replaced with RemoteEvent if needed)
local function killMob(model)
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        pcall(function()
            hum.Health = 0
        end)
    end
end

-- Radius visualization
local sphereAdornment
local function ensureSphere()
    if not KA.showRadius then
        if sphereAdornment then sphereAdornment.Visible = false end
        return
    end
    if not sphereAdornment then
        local s = Instance.new("SphereHandleAdornment")
        s.Name = "ONYX_KillAuraRadius"
        s.Color3 = Color3.fromRGB(255, 100, 100)
        s.Transparency = 0.8
        s.AlwaysOnTop = true
        s.ZIndex = 5
        s.Parent = workspace
        sphereAdornment = s
    end
    local char = getChar()
    sphereAdornment.Adornee = char and char:FindFirstChild("HumanoidRootPart") or nil
    sphereAdornment.Radius = math.clamp(KA.radius, 0, 10000)
    sphereAdornment.Visible = KA.showRadius and (sphereAdornment.Adornee ~= nil)
end

-- Tab: Kill Aura
do
    local KillAuraTab = ElementsSection:Tab({
        Title = "Kill Aura",
        Icon = "swords",
    })

    -- Toggle ON/OFF
    KillAuraTab:Toggle({
        Title = "Enable Kill Aura",
        Desc = "Auto-kill mobs within radius",
        Callback = function(v)
            KA.enabled = v and true or false
        end
    })

    KillAuraTab:Space()

    -- Target selector
    local TARGET_LIST = {
        "All",
        "Bunny",
        "Frog",
        "Scorpion",
        "Wolf",
        "Alpha Wolf",
        "Bear",
        "Polar Bear",
        "Arctic Fox",
        "Mammoth",
        "Cultist",
        "Crossbow Cultist",
        "Juggernaut Cultist",
        "Alien",
    }

    if type(KillAuraTab.Dropdown) == "function" then
        KillAuraTab:Dropdown({
            Title = "Target",
            Desc = "Choose mob target",
            List = TARGET_LIST,
            Selected = "All",
            Callback = function(opt)
                KA.target = opt or "All"
            end
        })
    else
        KillAuraTab:Input({
            Title = "Target",
            Desc = "Type a target (e.g., Wolf) or 'All'",
            Callback = function(text)
                if text and #text > 0 then
                    KA.target = text
                end
            end
        })
    end

    KillAuraTab:Space()

    -- Radius (max 10000)
    if type(KillAuraTab.Slider) == "function" then
        KillAuraTab:Slider({
            Title = "Radius",
            Desc = "Kill Aura range (0 - 10000)",
            Min = 0,
            Max = 10000,
            Default = KA.radius,
            Callback = function(val)
                KA.radius = math.clamp(tonumber(val) or KA.radius, 0, 10000)
                ensureSphere()
            end
        })
    else
        KillAuraTab:Input({
            Title = "Radius",
            Desc = "Enter a number (0 - 10000)",
            Callback = function(text)
                local num = tonumber(text)
                if num then
                    KA.radius = math.clamp(num, 0, 10000)
                    ensureSphere()
                end
            end
        })
    end

    KillAuraTab:Space()

    -- Show Radius
    KillAuraTab:Toggle({
        Title = "Show Radius",
        Desc = "Display Kill Aura range circle",
        Default = KA.showRadius,
        Callback = function(v)
            KA.showRadius = v and true or false
            ensureSphere()
        end
    })

    -- Info (locked text)
    KillAuraTab:Input({
        Title = "Info",
        Type = "Textarea",
        Locked = true,
        Desc = "All = kill every mob (even if not listed). Max radius 10000.",
    })
end

-- Tab: Fishing (placeholders; refined with game data)
do
    local FishTab = ElementsSection:Tab({ Title = "Fishing", Icon = "fish" })
    FishTab:Toggle({ Title = "Auto Cast", Callback = function(v) FISH.autoCast = v and true or false end })
    FishTab:Toggle({ Title = "Auto Minigames", Callback = function(v) FISH.autoMini = v and true or false end })
    FishTab:Toggle({ Title = "Bigger Success Bar", Callback = function(v) FISH.bigBar = v and true or false end })
    if type(FishTab.Dropdown) == "function" then
        FishTab:Dropdown({ Title = "Mode", List = {"Teleport","Stand"}, Selected = FISH.mode, Callback = function(opt) FISH.mode = opt or "Teleport" end })
    end
    FishTab:Input({ Title = "Note", Type = "Textarea", Locked = true, Desc = "Auto-cast rod & auto-complete prompts when available." })
end

-- Tab: Bring (generic, will refine later)
do
    local BringTab = ElementsSection:Tab({ Title = "Bring", Icon = "box" })
    BringTab:Input({ Title = "Info", Type = "Textarea", Locked = true, Desc = "Brings items by teleporting to them and interacting (client-side)." })
    local bringState = { category = "Guns", maxPer = 50, targetLoc = "Player" }
    if type(BringTab.Dropdown) == "function" then
        BringTab:Dropdown({ Title = "Bring Location", List = {"Player","Campfire"}, Selected = bringState.targetLoc, Callback = function(o) bringState.targetLoc = o end })
    end
    BringTab:Input({ Title = "Max Per Item", Desc = "e.g., 1000", Callback = function(t) local n=tonumber(t) if n then bringState.maxPer=n end end })
    BringTab:Input({ Title = "Item Keywords (comma)", Desc = "e.g., Log,Fuel,Sheet", Callback = function(text) bringState.category = text end })
    BringTab:Button({ Title = "Start Bring", Callback = function()
        task.spawn(function()
            local myChar = getChar(); local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            local count = 0
            while count < (bringState.maxPer or 50) do
                task.wait(0.2)
                local keys={}
                for s in string.gmatch(bringState.category or '', '[^,]+') do table.insert(keys, (s:gsub('^%s+',''):gsub('%s+$',''))) end
                local target = nearestInstanceByNameContains(myHRP.Position, keys)
                if not target then break end
                local pos
                if target:IsA("Model") then local p = target.PrimaryPart or getHRP(target); pos = p and p.Position elseif target:IsA("BasePart") then pos = target.Position end
                if pos then myHRP.CFrame = CFrame.new(pos + Vector3.new(0,2,0)) end
                -- try prompt
                for _, pp in ipairs((target:IsA("Model") and target:GetDescendants()) or {}) do
                    if pp:IsA("ProximityPrompt") and pp.Enabled then pcall(function() fireproximityprompt(pp) end) end
                end
                count += 1
            end
        end)
    end })
end

-- Tab: Teleport
do
    local TPTab = ElementsSection:Tab({
        Title = "Teleport",
        Icon = "map-pin",
    })

    -- Simpler and stable: Input for player name
    TPTab:Input({
        Title = "Player",
        Desc = "Type player name to teleport",
        Callback = function(text) TP.playerTarget = text end
    })

    TPTab:Button({
        Title = "Teleport to Player",
        Desc = "Teleport to typed player name",
        Callback = function()
            local target = TP.playerTarget and Players:FindFirstChild(TP.playerTarget)
            local char = target and target.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local myChar = getChar(); local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP and hrp then myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
        end
    })

    TPTab:Button({
        Title = "Teleport to Campfire",
        Desc = "Teleport to nearest campfire",
        Callback = function()
            local myChar = getChar(); local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            local target = nearestInstanceByNameContains(myHRP.Position, {"campfire","bonfire","fire"})
            local pos
            if target then
                if target:IsA("Model") then
                    local p = target.PrimaryPart or (target:FindFirstChild("HumanoidRootPart"))
                    pos = p and p.Position
                elseif target:IsA("BasePart") then
                    pos = target.Position
                end
            end
            if pos then myHRP.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
        end
    })

    TPTab:Button({
        Title = "Teleport to Lost Child",
        Desc = "Teleport to nearest child",
        Callback = function()
            local myChar = getChar(); local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            local target = nearestInstanceByNameContains(myHRP.Position, {"child","lost"})
            local pos
            if target then
                if target:IsA("Model") then
                    local p = target.PrimaryPart or (target:FindFirstChild("HumanoidRootPart"))
                    pos = p and p.Position
                elseif target:IsA("BasePart") then
                    pos = target.Position
                end
            end
            if pos then myHRP.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
        end
    })
end

-- Main loop
task.spawn(function()
    while true do
        task.wait(0.1)
        ensureSphere()

        if not KA.enabled then
            continue
        end

        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local targets = getTargetsInRadius(hrp.Position, KA.radius, KA.target)
        for _, mob in ipairs(targets) do
            killMob(mob)
            task.wait(0.02)
        end
    end
end)

-- ESP updater
task.spawn(function()
    while true do
        task.wait(0.5)
        -- Mobs
        if ESP.mobs then
            for _, inst in ipairs(workspace:GetDescendants()) do
                if inst:IsA("Model") and isMobModel(inst) then
                    attachHighlight(inst, Color3.fromRGB(255, 80, 80), "mob")
                end
            end
        end
        -- Items/chests/drops (heuristic by name)
        if ESP.items then
            local keys = {"chest","crate","drop","loot","item","fruit","log","gun","fuel","gear"}
            for _, inst in ipairs(workspace:GetDescendants()) do
                local name = inst.Name or ""
                for _, k in ipairs(keys) do
                    if strContains(name, k) then
                        local obj = inst:IsA("Model") and inst or (inst:IsA("BasePart") and inst.Parent)
                        if obj then attachHighlight(obj, Color3.fromRGB(255, 255, 100), "item") end
                        break
                    end
                end
            end
        end
        -- Players (others)
        if ESP.players then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer then
                    local c = pl.Character
                    if c then attachHighlight(c, Color3.fromRGB(100, 200, 255), "player") end
                end
            end
        end
    end
end)

-- Auto interact loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if not AUTO.interact then continue end
        local char = getChar(); local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local part = prompt.Parent
                local pos
                if part and part:IsA("BasePart") then pos = part.Position
                elseif part and part:IsA("Model") then
                    local p = part.PrimaryPart or getHRP(part)
                    pos = p and p.Position
                end
                if pos and (pos - hrp.Position).Magnitude <= AUTO.interactRadius then
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- No-clip loop
task.spawn(function()
    RunService.Stepped:Connect(function()
        if MOVE.noclip then
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end)
end)

-- Expand Hitbox worker (client-side best-effort)
task.spawn(function()
    while true do
        task.wait(0.5)
        if not MAIN.expandHitbox then continue end
        for _, m in ipairs(workspace:GetDescendants()) do
            if m:IsA("Model") and isMobModel(m) then
                local hrp = getHRP(m)
                if hrp and hrp:IsA("BasePart") then pcall(function() hrp.Size = Vector3.new(MAIN.hitboxSize, MAIN.hitboxSize, MAIN.hitboxSize) end) end
            end
        end
    end
end)

-- Auto Heal/Eat worker
task.spawn(function()
    while true do
        task.wait(0.25)
        local char = getChar(); if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if MAIN.autoBandage and hum.Health <= MAIN.healBelow then
                -- try use bandage tool
                local function useToolByKeys(keys)
                    local function findTool(container)
                        for _, t in ipairs(container:GetChildren()) do
                            if t:IsA("Tool") then
                                for _, k in ipairs(keys) do if strContains(t.Name, k) then return t end end
                            end
                        end
                    end
                    local bp = LocalPlayer.Backpack
                    local tool = (bp and findTool(bp)) or findTool(char)
                    if tool then pcall(function() tool.Parent = char tool:Activate() end) return true end
                end
                useToolByKeys({"bandage","med","heal"})
            end
        end
        if MAIN.autoEat then
            -- try eat from backpack/character by activating tools with food names
            local keys = MAIN.eatFoods or {}
            local function tryFoods()
                local bp = LocalPlayer.Backpack
                local function findTool(container)
                    for _, t in ipairs(container:GetChildren()) do
                        if t:IsA("Tool") then for _, k in ipairs(keys) do if strContains(t.Name, k) then return t end end end
                    end
                end
                local tool = (bp and findTool(bp)) or findTool(char)
                if tool then pcall(function() tool.Parent = char tool:Activate() end) end
            end
            if hum and hum.Health <= MAIN.eatBelow then tryFoods() end
        end
    end
end)

-- Fly & Infinite Jump
task.spawn(function()
    local UIS = game:GetService("UserInputService")
    local flying = false
    local dir = Vector3.new()
    UIS.InputBegan:Connect(function(i,g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.Space and PLAY.infiniteJump then
            local char = getChar(); local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    RunService.RenderStepped:Connect(function(dt)
        local char = getChar(); local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if PLAY.fly then
            local cam = workspace.CurrentCamera
            local move = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
            hrp.Velocity = move.Unit * (PLAY.flySpeed or 50)
            hrp.AssemblyLinearVelocity = hrp.Velocity
        end
    end)
end)
