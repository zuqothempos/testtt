-- ═══════════════════════════════════════
--      MIDNIGHT CHASERS - MNCStorm Bêta
-- ═══════════════════════════════════════

-- ⚠️ CONFIGURATION WEBHOOK
-- Proxy Hyra nécessaire — les exécuteurs bloquent Discord directement
local WEBHOOK_URL = "https://hooks.hyra.io/api/webhooks/1476192970918072410/Se0jIHE53o7Pq1kqH27RMfGlEjdw8BZ9nUByJX-JhoT9teOge3qEJH1nUNiBZ-GHBqdr"
local STATS_INTERVAL = 15 * 60  -- 15 minutes en secondes

-- Anti AFK
warn("Anti AFK running...")
game:GetService("Players").LocalPlayer.Idled:connect(function()
    warn("Anti AFK launched!")
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- Stream des objets
task.spawn(function()
    for i, v in pairs(workspace:GetDescendants()) do
        if v.ClassName == "Model" then
            task.spawn(function()
                game.Players.LocalPlayer:RequestStreamAroundAsync(v.WorldPivot.Position, 3)
            end)
            task.wait()
        end
    end
end)

-- ═══════════════════════════════════════
--         DÉTECTION DU SYSTÈME
-- ═══════════════════════════════════════
local function getSystem()
    local UIS = game:GetService("UserInputService")
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        local ok, inset = pcall(function()
            return game:GetService("GuiService"):GetGuiInset()
        end)
        if ok and inset.Y > 20 then
            return "iOS"
        else
            return "Android"
        end
    elseif UIS.KeyboardEnabled and UIS.TouchEnabled then
        return "PC (tactile)"
    else
        return "PC"
    end
end

-- ═══════════════════════════════════════
--         WEBHOOK DISCORD
-- ═══════════════════════════════════════
local HttpService = game:GetService("HttpService")

local function sendWebhook(title, description, color, fields)
    local embedFields = {}
    if fields then
        for _, f in ipairs(fields) do
            table.insert(embedFields, {
                name   = f.name,
                value  = f.value,
                inline = f.inline or false
            })
        end
    end

    local payload = HttpService:JSONEncode({
        username   = "MNCStorm Logger",
        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. game.Players.LocalPlayer.UserId .. "&width=150&height=150&format=png",
        embeds = {
            {
                title       = title,
                description = description,
                color       = color or 5814783,
                fields      = embedFields,
                footer      = {
                    text = "MNCStorm Bêta • " .. os.date("%d/%m/%Y %H:%M:%S")
                },
                thumbnail = {
                    url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. game.Players.LocalPlayer.UserId .. "&width=150&height=150&format=png"
                }
            }
        }
    })

    -- ✅ CORRECTION : passage par proxy Hyra
    -- Les exécuteurs (Synapse, Krnl...) bloquent discord.com et discordapp.com
    -- hooks.hyra.io est un proxy public qui relaie vers Discord
    local ok, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, payload, Enum.HttpContentType.ApplicationJson, false)
    end)
    if not ok then
        warn("[Webhook] Erreur : " .. tostring(err))
    end
end

-- ═══════════════════════════════════════
--              FONCTIONS FARM
-- ═══════════════════════════════════════
local function reachedMax(value)
    local test = 0
    for i, v in pairs(value:GetDescendants()) do
        if v:IsA("Seat") then test += 1 end
    end
    test = test * 5
    return value:FindFirstChild("Gifts") and #value.Gifts:GetChildren() == test
end

local function hideWorkspaceObjects(plr)
    if not game.ReplicatedStorage:FindFirstChild("mrbackupfolder") then
        local folder = Instance.new("Folder", game.ReplicatedStorage)
        folder.Name = "mrbackupfolder"
    end
    for i, v in pairs(workspace:GetChildren()) do
        if (v.ClassName == "Model" and not string.find(v.Name, plr.Name) and not string.find(v.Name, plr.DisplayName) and not string.find(v.Name, "Gift") and v.Name ~= "") or
           (v.ClassName == "Folder" and not string.find(v.Name, plr.Name) and not string.find(v.Name, plr.DisplayName) and not string.find(v.Name, "Gift") and v.Name ~= "") or
           v:IsA("MeshPart") then
            v.Parent = game.ReplicatedStorage:FindFirstChild("mrbackupfolder")
        end
    end
end

local function restoreWorkspaceObjects()
    if game.ReplicatedStorage:FindFirstChild("mrbackupfolder") then
        for i, v in pairs(game.ReplicatedStorage:FindFirstChild("mrbackupfolder"):GetChildren()) do
            v.Parent = workspace
            task.wait()
        end
    end
end

local function ensureGroundPart()
    if not _G.ooga then
        local new = Instance.new("Part", workspace)
        new.Anchored = true
        new.Size = Vector3.new(10000, 10, 10000)
        _G.ooga = new
    end
end

local function tweenToPosition(car, targetPos, speed)
    local plr = game.Players.LocalPlayer
    local dist = (plr.Character.HumanoidRootPart.Position - targetPos.Position).magnitude
    local TweenService = game:GetService("TweenService")
    local TweenValue = Instance.new("CFrameValue")
    TweenValue.Value = car:GetPrimaryPartCFrame()
    TweenValue.Changed:Connect(function()
        local test = TweenValue.Value.Position
        _G.ooga.Position = test - Vector3.new(0, 14, 0)
        car:PivotTo(CFrame.new(_G.ooga.Position + Vector3.new(0, 7, 0), targetPos.Position))
        car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
    end)
    getfenv().tween = TweenService:Create(TweenValue,
        TweenInfo.new(dist / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        {Value = targetPos}
    )
    getfenv().tween:Play()
    repeat task.wait(0)
    until getfenv().tween.PlaybackState == Enum.PlaybackState.Cancelled
       or getfenv().tween.PlaybackState == Enum.PlaybackState.Completed
       or getfenv().tween.PlaybackState == Enum.PlaybackState.Paused
end

local function tweenToLocation(car, locations, plr)
    repeat
        task.wait()
        local speed = getfenv().speed or 230
        if getfenv().cancelman then speed = 50 end
        local pos = locations.WorldPivot + Vector3.new(0, 5, 0)
        local dist = (plr.Character.HumanoidRootPart.Position - pos.Position).magnitude
        local TweenService = game:GetService("TweenService")
        local TweenValue = Instance.new("CFrameValue")
        TweenValue.Value = car:GetPrimaryPartCFrame()
        TweenValue.Changed:Connect(function()
            local test = TweenValue.Value.Position
            local playerDist = plr:DistanceFromCharacter(pos.Position)
            if playerDist > 100 then
                _G.ooga.Position = test - Vector3.new(0, 14, 0)
                car:PivotTo(CFrame.new(_G.ooga.Position + Vector3.new(0, 7, 0), pos.Position))
                car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
            elseif playerDist < 100 and playerDist > 10 then
                if not getfenv().cancelman then
                    getfenv().cancelman = true
                    getfenv().tween:Cancel()
                end
                _G.ooga.Position = test - Vector3.new(0, 8, 0)
                car:PivotTo(CFrame.new(_G.ooga.Position + Vector3.new(0, 7, 0), Vector3.new(pos.X, car.PrimaryPart.CFrame.Y, pos.Z)))
                car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * 20
            elseif playerDist < 5 then
                local lookat = car.PrimaryPart.CFrame * CFrame.new(0, 0, -10000)
                car:PivotTo(CFrame.new(Vector3.new(pos.X, _G.ooga.CFrame.Y + 7, pos.Z), lookat.Position))
                car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            end
        end)
        getfenv().tween = TweenService:Create(TweenValue,
            TweenInfo.new(dist / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
            {Value = pos}
        )
        getfenv().tween:Play()
        repeat task.wait(0)
        until getfenv().tween.PlaybackState == Enum.PlaybackState.Cancelled
           or getfenv().tween.PlaybackState == Enum.PlaybackState.Completed
           or getfenv().tween.PlaybackState == Enum.PlaybackState.Paused
    until not locations:FindFirstChild("Highlight") or not _G.test
    getfenv().cancelman = nil
end

-- ═══════════════════════════════════════
--         VARIABLES GLOBALES
-- ═══════════════════════════════════════
local blackScreen     = nil
local modeActuel      = "Normal"
local speedMultiplier = {Normal = 1, Rapide = 1.5, Turbo = 2.5}

-- Wind.ez
local CollectionService = game:GetService("CollectionService")
local TAG               = "windnocollide"
local isWindOn          = false
local windConnections   = {}
local npcTransparency   = 0.6

-- Stats session
local sessionStart    = nil
local timerRunning    = false
local moneyStart      = nil
local lastMoney       = nil
local lastStatsSent   = nil

local frames = {
    CFrame.new(105.419128, -26.0098934, 7965.37988, -3.36170197e-05, 0.951051414, -0.309032798, -1, -3.36170197e-05, 5.31971455e-06, -5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(2751.86499, -26.0098934, 3694.63354, 3.34978104e-05, 0.951051414, -0.309032798, -1, 3.34978104e-05, -5.31971455e-06, 5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(-8821.48438, -26.0098934, 2042.49939, -3.36170197e-05, 0.951051414, -0.309032798, -1, -3.36170197e-05, 5.31971455e-06, -5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(-6408.62109, -26.0098934, -727.765198, 3.34978104e-05, 0.951051414, -0.309032798, -1, 3.34978104e-05, -5.31971455e-06, 5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(-6099.79639, -26.00989345, -1027.94556, -3.36170197e-05, 0.951051414, -0.309032798, -1, -3.36170197e-05, 5.31971455e-06, -5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(-6066.70068, -26.0098934, 493.255524, 3.34978104e-05, 0.951051414, -0.309032798, -1, 3.34978104e-05, -5.31971455e-06, 5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(132.786133, -26.0098934, 15.2286377, 3.34978104e-05, 0.951051414, -0.309032798, -1, 3.34978104e-05, -5.31971455e-06, 5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(-7692.85449, -26.0098934, -4668.61963, -3.36170197e-05, 0.951051414, -0.309032798, -1, -3.36170197e-05, 5.31971455e-06, -5.31971455e-06, 0.309032798, 0.951051414),
    CFrame.new(4887.24609, -26.0098934, 1222.96826, -3.36170197e-05, 0.951051414, -0.309032798, -1, -3.36170197e-05, 5.31971455e-06, -5.31971455e-06, 0.309032798, 0.951051414)
}

-- ═══════════════════════════════════════
--         FONCTIONS WIND.EZ
-- ═══════════════════════════════════════
local function shouldAffect(part)
    if not part:IsA("BasePart") then return false end
    local n = part.Name:lower()
    if n == "part" or n == "car" then return true end
    if part:FindFirstAncestor("NPCVehicles") then return true end
    return false
end

local function disableCollision(part)
    if part:GetAttribute("wind_originalcollide") == nil then
        part:SetAttribute("wind_originalcollide", part.CanCollide)
    end
    if part:GetAttribute("wind_originaltransparency") == nil then
        part:SetAttribute("wind_originaltransparency", part.Transparency)
    end
    part.CanCollide = false
    part.Transparency = npcTransparency
    CollectionService:AddTag(part, TAG)
end

local function restoreCollision(part)
    local c = part:GetAttribute("wind_originalcollide")
    if c ~= nil then
        part.CanCollide = c
        part:SetAttribute("wind_originalcollide", nil)
    end
    local t = part:GetAttribute("wind_originaltransparency")
    if t ~= nil then
        part.Transparency = t
        part:SetAttribute("wind_originaltransparency", nil)
    end
    CollectionService:RemoveTag(part, TAG)
end

local function applyToFolder(folder)
    for _, obj in ipairs(folder:GetDescendants()) do
        if shouldAffect(obj) then disableCollision(obj) end
    end
    local c = folder.DescendantAdded:Connect(function(newObj)
        if isWindOn and shouldAffect(newObj) then disableCollision(newObj) end
    end)
    table.insert(windConnections, c)
end

local function enableWind()
    local npc = workspace:FindFirstChild("NPCVehicles")
    if npc then applyToFolder(npc) end
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Folder") and tonumber(v.Name) then applyToFolder(v) end
    end
    local wsC = workspace.ChildAdded:Connect(function(child)
        if not isWindOn then return end
        if child.Name == "NPCVehicles" or (child:IsA("Folder") and tonumber(child.Name)) then
            applyToFolder(child)
        end
    end)
    table.insert(windConnections, wsC)
end

local function disableWind()
    for _, part in ipairs(CollectionService:GetTagged(TAG)) do
        restoreCollision(part)
    end
    for _, c in ipairs(windConnections) do c:Disconnect() end
    windConnections = {}
end

-- ═══════════════════════════════════════
--         FONCTIONS STATS
-- ═══════════════════════════════════════
local function getMoney()
    local plr = game.Players.LocalPlayer
    -- ⚠️ Modifie "leaderstats.Cash" si le nom est différent dans ton jeu
    local ok, val = pcall(function()
        return plr.leaderstats.Cash.Value
    end)
    return ok and val or 0
end

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02dh %02dm %02ds", h, m, s)
end

-- ═══════════════════════════════════════
--         CONSTRUCTION GUI
-- ═══════════════════════════════════════
local function buildGUI(W)
    local plr    = game.Players.LocalPlayer
    local system = getSystem()

    -- Webhook : connexion initiale
    task.spawn(function()
        sendWebhook(
            "🟢 Nouvelle connexion",
            "Un joueur vient de lancer **MNCStorm Bêta**.",
            0x57F287,
            {
                { name = "👤 Joueur",   value = plr.DisplayName .. " (@" .. plr.Name .. ")", inline = true  },
                { name = "🆔 UserId",   value = tostring(plr.UserId),                         inline = true  },
                { name = "📱 Appareil", value = system,                                       inline = true  },
                { name = "🔑 Rôle",     value = _G.MNCKeyRole or "Free",                     inline = true  },
                { name = "📅 Expire",   value = _G.MNCKeyExpire or "Inconnu",                inline = true  },
                { name = "🎮 Serveur",  value = tostring(game.JobId),                         inline = false },
            }
        )
    end)

    -- ─────────────────────────────
    --         TAB 1 — HOME
    -- ─────────────────────────────
    local tab1 = W:AddTab("Home")
    tab1:AddLabel("== Welcome to MNCStorm Bêta ❤ ==")
    tab1:AddSeparator("Informations")
    tab1:AddInfo("🖥️", "Système",    system)
    tab1:AddInfo("🔑", "Rôle",       _G.MNCKeyRole   or "Free")
    tab1:AddInfo("📅", "Clé expire", _G.MNCKeyExpire or "Inconnu")
    tab1:AddSeparator("Communauté")
    tab1:AddButton("❤️  J'aime MNCStorm !", "Clique pour montrer ton soutien !", function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = "❤️ Merci !",
            Text     = "Tu as aimé MNCStorm ! Merci pour ton soutien ✨",
            Duration = 5,
        })
    end)

    -- ─────────────────────────────
    --         TAB 2 — FARM
    -- ─────────────────────────────
    local tab2 = W:AddTab("Farm")
    tab2:AddLabel("== Auto Farm ==")
    tab2:AddSeparator("Paramètres")

    tab2:AddSlider("Vitesse", "Vitesse du véhicule", 100, 1000, 300, function(value)
        getfenv().speed = value * (speedMultiplier[modeActuel] or 1)
    end)

    tab2:AddDropdown("Mode", {"Normal", "Rapide", "Turbo"}, function(option)
        modeActuel = option
        local baseSpeed = getfenv().speed or 300
        getfenv().speed = baseSpeed * (speedMultiplier[option] or 1)
        warn("Mode : " .. option .. " | Vitesse : " .. tostring(getfenv().speed))
    end)

    tab2:AddSeparator("Farm Principal")

    tab2:AddToggle("Auto Farm", "Fait les trajets automatiquement", false, function(state)
        getfenv().auto = state
        if state then
            sessionStart  = tick()
            moneyStart    = getMoney()
            lastMoney     = moneyStart
            lastStatsSent = tick()
            timerRunning  = true
            hideWorkspaceObjects(plr)
            task.wait()
            task.spawn(function()
                while getfenv().auto do
                    local success, err = pcall(function()
                        local hum = plr.Character.Humanoid
                        local car = hum.SeatPart.Parent
                        getfenv().car = car
                        ensureGroundPart()
                        car.PrimaryPart = car.Body:FindFirstChild("#Weight")
                        for i, v in pairs(frames) do
                            if not getfenv().auto then break end
                            tweenToPosition(car, v + Vector3.new(0, 5, 0), getfenv().speed or 300)
                        end
                    end)
                    if not success then
                        warn("Auto Farm erreur : " .. tostring(err))
                        task.wait(2)
                    end
                end
            end)
        else
            timerRunning = false
            if getfenv().tween then getfenv().tween:Cancel() end
            restoreWorkspaceObjects()
        end
    end)

    tab2:AddSeparator("Event")

    tab2:AddToggle("Auto Deliver [Event]", "Livre les colis automatiquement", false, function(state)
        _G.test = state
        if state then
            hideWorkspaceObjects(plr)
            task.wait()
            task.spawn(function()
                while _G.test do
                    task.wait()
                    local success, err = pcall(function()
                        ensureGroundPart()
                        local car = plr.Character.Humanoid.SeatPart.Parent
                        getfenv().car = car
                        car.PrimaryPart = car.Body:FindFirstChild("#Weight")
                        local locations
                        local maxdistance = math.huge
                        for i, v in pairs(workspace:GetChildren()) do
                            if v.Name == "" and v:FindFirstChild("Highlight") then
                                local dist = (plr.Character.PrimaryPart.Position - v.WorldPivot.Position).magnitude
                                if dist < maxdistance then
                                    maxdistance = dist
                                    locations = v
                                end
                            end
                        end
                        if locations then
                            tweenToLocation(car, locations, plr)
                        elseif workspace:FindFirstChild("GiftPickup") then
                            repeat
                                task.wait()
                                car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                                car:PivotTo(CFrame.new(workspace.GiftPickup.WorldPivot.Position) + Vector3.new(0, 5, 0))
                            until reachedMax(car)
                        end
                    end)
                    if not success then
                        warn("Auto Deliver erreur : " .. tostring(err))
                        task.wait(2)
                    end
                end
            end)
        else
            if getfenv().tween then getfenv().tween:Cancel() end
            restoreWorkspaceObjects()
        end
    end)

    -- ─────────────────────────────
    --         TAB 3 — STATS
    -- ─────────────────────────────
    local tab3 = W:AddTab("Stats")
    tab3:AddLabel("== Statistiques de Session ==")
    tab3:AddSeparator("Session")

    local setTimer  = tab3:AddInfo("⏱️", "Temps actif",  "00h 00m 00s")
    local setMoney  = tab3:AddInfo("💰", "Argent gagné", "0")
    local setDelta  = tab3:AddInfo("📈", "Dernier gain",  "+0")
    local setStatus = tab3:AddInfo("📡", "Statut farm",   "Inactif")

    tab3:AddSeparator("Actions")

    tab3:AddButton("🔄  Réinitialiser", "Remet le timer et l'argent à zéro", function()
        sessionStart  = tick()
        moneyStart    = getMoney()
        lastMoney     = moneyStart
        lastStatsSent = tick()
        setTimer("00h 00m 00s")
        setMoney("0")
        setDelta("+0")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = "Stats réinitialisées",
            Text     = "Timer et argent remis à zéro.",
            Duration = 3,
        })
    end)

    -- Boucle stats — mise à jour chaque seconde + webhook toutes les 15min
    task.spawn(function()
        while true do
            task.wait(1)
            if timerRunning and sessionStart then
                local now     = tick()
                local elapsed = now - sessionStart
                local current = getMoney()
                local gained  = math.max(0, current - (moneyStart or current))
                local delta   = current - (lastMoney or current)
                lastMoney     = current

                setTimer(formatTime(elapsed))
                setMoney(tostring(gained))
                setStatus("✅ Actif")

                if delta > 0 then
                    setDelta("+" .. tostring(delta))
                elseif delta < 0 then
                    setDelta(tostring(delta))
                else
                    setDelta("+0")
                end

                -- Webhook toutes les 15 minutes
                if lastStatsSent and (now - lastStatsSent) >= STATS_INTERVAL then
                    lastStatsSent = now
                    local elapsed_fmt = formatTime(elapsed)
                    task.spawn(function()
                        sendWebhook(
                            "📊 Rapport de stats — 15 min",
                            "Rapport automatique de la session en cours.",
                            0x5865F2,
                            {
                                { name = "👤 Joueur",       value = plr.DisplayName .. " (@" .. plr.Name .. ")", inline = true  },
                                { name = "📱 Appareil",     value = system,                                       inline = true  },
                                { name = "⏱️ Temps actif",  value = elapsed_fmt,                                  inline = false },
                                { name = "💰 Argent gagné", value = tostring(gained),                             inline = true  },
                                { name = "📈 Dernier gain", value = (delta >= 0 and "+" or "") .. tostring(delta),inline = true  },
                                { name = "📡 Statut",       value = "✅ Farm actif",                              inline = false },
                            }
                        )
                    end)
                end
            else
                setStatus("⛔ Inactif")
            end
        end
    end)

    -- ─────────────────────────────
    --         TAB 4 — VISUEL
    -- ─────────────────────────────
    local tab4 = W:AddTab("Visuel")
    tab4:AddLabel("== Options Visuelles ==")
    tab4:AddSeparator("Écran")

    tab4:AddToggle("Black Screen", "Rend l'écran noir pour farmer en fond", false, function(state)
        if state then
            blackScreen = Instance.new("ScreenGui")
            blackScreen.Name = "BlackScreen"
            blackScreen.DisplayOrder = -1000
            blackScreen.Parent = game.CoreGui
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Parent = blackScreen
        else
            if blackScreen then
                blackScreen:Destroy()
                blackScreen = nil
            end
        end
    end)

    tab4:AddSeparator("Véhicules NPC")

    tab4:AddSlider("Transparence NPC", "0 = opaque  |  10 = invisible", 0, 10, 6, function(value)
        npcTransparency = value / 10
        if isWindOn then
            for _, part in ipairs(CollectionService:GetTagged(TAG)) do
                part.Transparency = npcTransparency
            end
        end
    end)

    tab4:AddToggle("Wind.ez | No Collide NPC", "Désactive la collision avec les véhicules NPC", false, function(state)
        isWindOn = state
        if state then enableWind() else disableWind() end
    end)

end

-- ═══════════════════════════════════════
--          CHARGEMENT BIBLIOTHÈQUE
-- ═══════════════════════════════════════
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/zuqothempos/testt/refs/heads/main/Test.lua"
))()

Library:CreateWindow("Midnight Chasers", true, function(W)
    buildGUI(W)
end)
