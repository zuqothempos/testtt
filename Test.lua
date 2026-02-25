-- ═══════════════════════════════════════
--        MA BIBLIOTHÈQUE GUI - v2.5
-- ═══════════════════════════════════════

local Library = {}
Library.__index = Library

-- ═══════════════════════════════════════
--         SYSTÈME DE CLÉS AVANCÉ
-- ═══════════════════════════════════════

-- Whitelist UserId — seuls ces comptes peuvent utiliser le script
-- Laisse vide {} pour désactiver la whitelist
local WHITELIST = {
    -- 123456789,  -- exemple UserId
}

-- Blacklist UserId (rempli automatiquement après 3 tentatives)
-- Tu peux aussi en mettre manuellement ici
local BLACKLIST = {
    -- 987654321,  -- exemple
}

local MAX_ATTEMPTS = 3
local attemptCount = 0
local blacklistFile = "MNCStorm_blacklist.txt"
local sessionFile   = "MNCStorm_sessions.txt"

-- Messages personnalisés par rôle affichés après le login
local RoleMessages = {
    Admin   = "👑 Bienvenue, Administrateur ! Accès total activé.",
    Premium = "⭐ Bienvenue, membre Premium ! Profite de toutes les fonctionnalités.",
    Free    = "🔓 Bienvenue ! Tu utilises la version gratuite de MNCStorm.",
}

-- ─────────────────────────────────────────
-- Système de clés avec UserId + usage unique
-- ─────────────────────────────────────────
local KeySystem = {
    AdminKeys = {
        ["ADMIN-1234-5678-9012"] = {
            expire   = "Jamais",
            userId   = nil,        -- nil = n'importe qui peut l'utiliser
            maxUses  = nil,        -- nil = illimité
            uses     = 0,
        },
        ["ADMIN-ABCD-EFGH-IJKL"] = {
            expire   = "Jamais",
            userId   = nil,
            maxUses  = nil,
            uses     = 0,
        },
    },
    PremiumKeys = {
        ["PREMIUM-XXXX-YYYY-ZZZZ"] = {
            expire   = "31/12/2026",
            userId   = nil,
            maxUses  = nil,
            uses     = 0,
        },
        ["PREMIUM-ONCE-ONLY-0001"] = {
            expire   = "31/12/2026",
            userId   = nil,
            maxUses  = 1,          -- clé à usage unique
            uses     = 0,
        },
    },
    FreeKeys = {
        ["FREE-0000-0000-0001"] = {
            expire   = "01/12/2026",
            userId   = nil,
            maxUses  = nil,
            uses     = 0,
        },
        ["FREE-0000-0000-0002"] = {
            expire   = "01/12/2026",
            userId   = 123456789, -- clé liée à un UserId précis
            maxUses  = nil,
            uses     = 0,
        },
    },
}

local function isExpired(dateStr)
    if dateStr == "Jamais" then return false end
    local d, m, y = dateStr:match("(%d+)/(%d+)/(%d+)")
    if not d then return false end
    local now = os.date("*t")
    d, m, y = tonumber(d), tonumber(m), tonumber(y)
    if y < now.year then return true end
    if y == now.year and m < now.month then return true end
    if y == now.year and m == now.month and d < now.day then return true end
    return false
end

local function checkKey(key, userId)
    local allGroups = {
        {data = KeySystem.AdminKeys,   role = "Admin"},
        {data = KeySystem.PremiumKeys, role = "Premium"},
        {data = KeySystem.FreeKeys,    role = "Free"},
    }
    for _, group in ipairs(allGroups) do
        for k, info in pairs(group.data) do
            if k == key then
                if isExpired(info.expire) then return nil, nil, "expired" end
                if info.userId and info.userId ~= userId then return nil, nil, "userid" end
                if info.maxUses and info.uses >= info.maxUses then return nil, nil, "used" end
                info.uses = info.uses + 1
                return group.role, info.expire
            end
        end
    end
    return nil, nil, "invalid"
end

-- Gestion blacklist via fichier
local function loadBlacklist()
    if readfile and pcall(function() readfile(blacklistFile) end) then
        local ok, content = pcall(readfile, blacklistFile)
        if ok and content then
            for id in content:gmatch("%d+") do
                table.insert(BLACKLIST, tonumber(id))
            end
        end
    end
end

local function saveBlacklist()
    if writefile then
        local ids = {}
        for _, id in ipairs(BLACKLIST) do
            table.insert(ids, tostring(id))
        end
        pcall(writefile, blacklistFile, table.concat(ids, "\n"))
    end
end

local function isBlacklisted(userId)
    for _, id in ipairs(BLACKLIST) do
        if id == userId then return true end
    end
    return false
end

local function addToBlacklist(userId)
    table.insert(BLACKLIST, userId)
    saveBlacklist()
end

local function isWhitelisted(userId)
    if #WHITELIST == 0 then return true end
    for _, id in ipairs(WHITELIST) do
        if id == userId then return true end
    end
    return false
end

-- Sauvegarde session
local function saveSession(role, system, gained)
    if not writefile then return end
    local now = os.date("%d/%m/%Y %H:%M:%S")
    local line = string.format("[%s] Rôle:%s | Appareil:%s | Gagné:%s\n", now, role, system, tostring(gained))
    local existing = ""
    if readfile then
        pcall(function() existing = readfile(sessionFile) end)
    end
    pcall(writefile, sessionFile, existing .. line)
end

local KeyColors = {
    Admin   = Color3.fromRGB(255, 80,  80),
    Premium = Color3.fromRGB(255, 200, 50),
    Free    = Color3.fromRGB(100, 200, 100),
}
local KeyIcons = {
    Admin   = "👑 Admin",
    Premium = "⭐ Premium",
    Free    = "🔓 Free",
}

-- ═══════════════════════════════════════
--              CONFIGURATION
-- ═══════════════════════════════════════
local CONFIG = {
    Background    = Color3.fromRGB(20, 20, 30),
    TopBar        = Color3.fromRGB(30, 30, 45),
    TabBar        = Color3.fromRGB(25, 25, 38),
    TabActive     = Color3.fromRGB(80, 120, 255),
    TabInactive   = Color3.fromRGB(40, 40, 60),
    Element       = Color3.fromRGB(35, 35, 52),
    ElementHover  = Color3.fromRGB(50, 50, 75),
    ToggleOn      = Color3.fromRGB(80, 200, 120),
    ToggleOff     = Color3.fromRGB(60, 60, 80),
    SliderFill    = Color3.fromRGB(80, 120, 255),
    Text          = Color3.fromRGB(255, 255, 255),
    TextDim       = Color3.fromRGB(160, 160, 180),
    Border        = Color3.fromRGB(60, 60, 90),
    Dropdown      = Color3.fromRGB(28, 28, 42),
    ProfileBg     = Color3.fromRGB(25, 25, 40),
    InfoBg        = Color3.fromRGB(28, 28, 45),
    AdminBg       = Color3.fromRGB(40, 20, 20),
    WindowWidth   = 520,
    WindowHeight  = 400,
    WindowMinW    = 300,
    WindowMinH    = 200,
    ProfileHeight = 70,
    TabHeight     = 30,
    ElementHeight = 36,
    CornerRadius  = UDim.new(0, 6),
}

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ═══════════════════════════════════════
--           FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════
local function tween(obj, props, duration, style, direction)
    TweenService:Create(obj, TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    ), props):Play()
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or CONFIG.CornerRadius
    c.Parent = parent
end

local function addPadding(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.Parent = parent
end

local function addListLayout(parent, padding, direction)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, padding or 6)
    l.FillDirection = direction or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CONFIG.Border
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function makeLabel(parent, text, size, pos, font, textSize, color, align)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = color or CONFIG.Text
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 12
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.Parent = parent
    return l
end

local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart = nil
    local startPos  = nil
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart and startPos
            and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function getTime()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function hueToColor(h)
    return Color3.fromHSV(h % 1, 1, 1)
end

-- ═══════════════════════════════════════
--         CURSEUR PERSONNALISÉ
-- ═══════════════════════════════════════
local cursorGui = nil
local cursorActive = false

local function createCursor(parent)
    if cursorGui then cursorGui:Destroy() end
    cursorGui = Instance.new("ScreenGui")
    cursorGui.Name = "MNCCursor"
    cursorGui.ResetOnSpawn = false
    cursorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    cursorGui.DisplayOrder = 9999
    cursorGui.IgnoreGuiInset = true
    cursorGui.Parent = game.CoreGui

    -- Curseur principal
    local cursor = Instance.new("Frame")
    cursor.Name = "Cursor"
    cursor.Size = UDim2.new(0, 14, 0, 14)
    cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cursor.BorderSizePixel = 0
    cursor.ZIndex = 100
    cursor.Parent = cursorGui
    addCorner(cursor, UDim.new(1, 0))
    addStroke(cursor, CONFIG.TabActive, 2)

    -- Point central
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = CONFIG.TabActive
    dot.BorderSizePixel = 0
    dot.ZIndex = 101
    dot.Parent = cursor
    addCorner(dot, UDim.new(1, 0))

    -- Traînée
    local trail = Instance.new("Frame")
    trail.Name = "Trail"
    trail.Size = UDim2.new(0, 8, 0, 8)
    trail.BackgroundColor3 = CONFIG.TabActive
    trail.BackgroundTransparency = 0.5
    trail.BorderSizePixel = 0
    trail.ZIndex = 99
    trail.Parent = cursorGui
    addCorner(trail, UDim.new(1, 0))

    local hue = 0
    local trailX, trailY = 0, 0

    RunService.RenderStepped:Connect(function(dt)
        if not cursorActive then return end
        local mouse = UserInputService:GetMouseLocation()
        cursor.Position = UDim2.new(0, mouse.X - 7, 0, mouse.Y - 7)

        -- Traînée lissée
        trailX = trailX + (mouse.X - 4 - trailX) * 0.15
        trailY = trailY + (mouse.Y - 4 - trailY) * 0.15
        trail.Position = UDim2.new(0, trailX, 0, trailY)

        -- Arc-en-ciel sur le curseur
        hue = (hue + dt * 0.5) % 1
        local col = hueToColor(hue)
        dot.BackgroundColor3 = col
        trail.BackgroundColor3 = col
        for _, s in ipairs(cursor:GetChildren()) do
            if s:IsA("UIStroke") then s.Color = col end
        end
    end)

    return cursorGui
end

local function enableCursor()
    cursorActive = true
    game:GetService("UserInputService").MouseIconEnabled = false
end

local function disableCursor()
    cursorActive = false
    game:GetService("UserInputService").MouseIconEnabled = true
    if cursorGui then cursorGui:Destroy() cursorGui = nil end
end

-- ═══════════════════════════════════════
--        ÉCRAN DE CHARGEMENT
-- ═══════════════════════════════════════
local function showLoadingScreen(callback)
    local sg = Instance.new("ScreenGui")
    sg.Name = "MNCLoading"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = game.CoreGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = CONFIG.Background
    bg.BorderSizePixel = 0
    bg.Parent = sg

    local title = makeLabel(bg, "MNCStorm",
        UDim2.new(0, 300, 0, 50), UDim2.new(0.5, -150, 0.35, 0),
        Enum.Font.GothamBold, 32, Color3.fromRGB(255, 255, 255))

    local sub = makeLabel(bg, "Midnight Chasers — Chargement en cours...",
        UDim2.new(0, 400, 0, 24), UDim2.new(0.5, -200, 0.35, 56),
        Enum.Font.Gotham, 13, CONFIG.TextDim)

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 360, 0, 8)
    barBg.Position = UDim2.new(0.5, -180, 0.55, 0)
    barBg.BackgroundColor3 = CONFIG.Element
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    addCorner(barBg, UDim.new(1, 0))

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = CONFIG.TabActive
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    addCorner(barFill, UDim.new(1, 0))

    local pctLabel = makeLabel(bg, "0%",
        UDim2.new(0, 360, 0, 20), UDim2.new(0.5, -180, 0.55, 14),
        Enum.Font.GothamSemibold, 11, CONFIG.TextDim, Enum.TextXAlignment.Right)

    local steps = {
        "Initialisation du script...",
        "Connexion aux services Roblox...",
        "Chargement des fonctions farm...",
        "Configuration de la GUI...",
        "Vérification de la clé...",
        "Prêt !",
    }

    local stepLabel = makeLabel(bg, steps[1],
        UDim2.new(0, 360, 0, 20), UDim2.new(0.5, -180, 0.55, 30),
        Enum.Font.Gotham, 11, CONFIG.TextDim, Enum.TextXAlignment.Left)

    local hue = 0
    local rainbowConn = RunService.Heartbeat:Connect(function(dt)
        hue = (hue + dt * 0.4) % 1
        barFill.BackgroundColor3 = hueToColor(hue)
        title.TextColor3 = hueToColor(hue)
    end)

    task.spawn(function()
        for i, step in ipairs(steps) do
            local pct = i / #steps
            stepLabel.Text = step
            pctLabel.Text = math.floor(pct * 100) .. "%"
            tween(barFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.4, Enum.EasingStyle.Quad)
            task.wait(0.45)
        end
        task.wait(0.3)
        rainbowConn:Disconnect()
        tween(bg,       {BackgroundTransparency = 1}, 0.5)
        tween(title,    {TextTransparency = 1}, 0.5)
        tween(sub,      {TextTransparency = 1}, 0.5)
        tween(barBg,    {BackgroundTransparency = 1}, 0.5)
        tween(barFill,  {BackgroundTransparency = 1}, 0.5)
        tween(pctLabel, {TextTransparency = 1}, 0.5)
        tween(stepLabel,{TextTransparency = 1}, 0.5)
        task.wait(0.55)
        sg:Destroy()
        callback()
    end)
end

-- ═══════════════════════════════════════
--        ÉCRAN DE SAISIE DE CLÉ
-- ═══════════════════════════════════════
local function showKeyScreen(callback)
    loadBlacklist()

    local userId = LocalPlayer.UserId

    -- Vérification whitelist
    if not isWhitelisted(userId) then
        local sg = Instance.new("ScreenGui")
        sg.Name = "MNCBlocked"
        sg.ResetOnSpawn = false
        sg.Parent = game.CoreGui
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1,0,1,0)
        bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency = 0.3
        bg.BorderSizePixel = 0
        bg.Parent = sg
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,380,0,120)
        f.Position = UDim2.new(0.5,-190,0.5,-60)
        f.BackgroundColor3 = CONFIG.Background
        f.BorderSizePixel = 0
        f.Parent = sg
        addCorner(f, UDim.new(0,10))
        addStroke(f, Color3.fromRGB(200,60,60), 2)
        makeLabel(f, "🚫 Accès refusé",
            UDim2.new(1,0,0,40), UDim2.new(0,0,0,8),
            Enum.Font.GothamBold, 18, Color3.fromRGB(255,80,80))
        makeLabel(f, "Votre compte n'est pas autorisé à utiliser ce script.",
            UDim2.new(1,-20,0,30), UDim2.new(0,10,0,50),
            Enum.Font.Gotham, 12, CONFIG.TextDim)
        makeLabel(f, "Contactez le staff pour obtenir l'accès.",
            UDim2.new(1,-20,0,24), UDim2.new(0,10,0,82),
            Enum.Font.Gotham, 11, CONFIG.TextDim)
        return
    end

    -- Vérification blacklist
    if isBlacklisted(userId) then
        local sg = Instance.new("ScreenGui")
        sg.Name = "MNCBlacklisted"
        sg.ResetOnSpawn = false
        sg.Parent = game.CoreGui
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1,0,1,0)
        bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency = 0.3
        bg.BorderSizePixel = 0
        bg.Parent = sg
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,400,0,130)
        f.Position = UDim2.new(0.5,-200,0.5,-65)
        f.BackgroundColor3 = CONFIG.Background
        f.BorderSizePixel = 0
        f.Parent = sg
        addCorner(f, UDim.new(0,10))
        addStroke(f, Color3.fromRGB(200,60,60), 2)
        makeLabel(f, "⛔ Compte banni",
            UDim2.new(1,0,0,40), UDim2.new(0,0,0,8),
            Enum.Font.GothamBold, 18, Color3.fromRGB(255,80,80))
        makeLabel(f, "Trop de tentatives incorrectes détectées.",
            UDim2.new(1,-20,0,26), UDim2.new(0,10,0,50),
            Enum.Font.Gotham, 12, CONFIG.TextDim)
        makeLabel(f, "⚠️ Veuillez contacter le staff pour résoudre ce problème.",
            UDim2.new(1,-20,0,26), UDim2.new(0,10,0,78),
            Enum.Font.Gotham, 11, Color3.fromRGB(255,180,50))
        makeLabel(f, "UserId : " .. tostring(userId),
            UDim2.new(1,-20,0,20), UDim2.new(0,10,0,104),
            Enum.Font.GothamSemibold, 10, CONFIG.TextDim)
        return
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "KeyScreen"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = game.CoreGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    bg.Parent = sg

    local kf = Instance.new("Frame")
    kf.Size = UDim2.new(0, 0, 0, 0)
    kf.Position = UDim2.new(0.5, 0, 0.5, 0)
    kf.BackgroundColor3 = CONFIG.Background
    kf.BorderSizePixel = 0
    kf.Parent = sg
    addCorner(kf, UDim.new(0, 10))
    addStroke(kf, CONFIG.Border, 1)

    tween(kf, {
        Size = UDim2.new(0, 360, 0, 230),
        Position = UDim2.new(0.5, -180, 0.5, -115)
    }, 0.4, Enum.EasingStyle.Back)

    makeLabel(kf, "🔑  Entrez votre clé",
        UDim2.new(1, 0, 0, 48), UDim2.new(0, 0, 0, 0),
        Enum.Font.GothamBold, 16, CONFIG.Text)

    makeLabel(kf, "Clé Free / Premium / Admin",
        UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 46),
        Enum.Font.Gotham, 11, CONFIG.TextDim)

    -- Compteur de tentatives
    local attemptsLbl = makeLabel(kf, "Tentatives restantes : " .. (MAX_ATTEMPTS - attemptCount),
        UDim2.new(1, -20, 0, 16), UDim2.new(0, 10, 0, 64),
        Enum.Font.Gotham, 10, Color3.fromRGB(255, 180, 50))

    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -40, 0, 36)
    inputBg.Position = UDim2.new(0, 20, 0, 90)
    inputBg.BackgroundColor3 = CONFIG.Element
    inputBg.BorderSizePixel = 0
    inputBg.Parent = kf
    addCorner(inputBg, UDim.new(0, 6))
    addStroke(inputBg, CONFIG.Border, 1)

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -16, 1, 0)
    inputBox.Position = UDim2.new(0, 8, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    inputBox.PlaceholderColor3 = CONFIG.TextDim
    inputBox.Text = ""
    inputBox.TextColor3 = CONFIG.Text
    inputBox.Font = Enum.Font.GothamSemibold
    inputBox.TextSize = 13
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputBg

    local errLabel = makeLabel(kf, "",
        UDim2.new(1, -20, 0, 18), UDim2.new(0, 10, 0, 136),
        Enum.Font.Gotham, 11, Color3.fromRGB(255, 80, 80))

    local validateBtn = Instance.new("TextButton")
    validateBtn.Size = UDim2.new(1, -40, 0, 36)
    validateBtn.Position = UDim2.new(0, 20, 0, 176)
    validateBtn.BackgroundColor3 = CONFIG.TabActive
    validateBtn.Text = "Valider la clé"
    validateBtn.TextColor3 = CONFIG.Text
    validateBtn.Font = Enum.Font.GothamBold
    validateBtn.TextSize = 13
    validateBtn.BorderSizePixel = 0
    validateBtn.Parent = kf
    addCorner(validateBtn, UDim.new(0, 6))

    validateBtn.MouseButton1Click:Connect(function()
        local role, expire, reason = checkKey(inputBox.Text, userId)
        if role then
            _G.MNCKeyRole   = role
            _G.MNCKeyExpire = expire or "Jamais"
            _G.MNCKeyMsg    = RoleMessages[role] or ""
            tween(validateBtn, {BackgroundColor3 = CONFIG.ToggleOn}, 0.2)
            validateBtn.Text = "✓ " .. (RoleMessages[role] or "Accès autorisé")
            task.delay(1, function()
                tween(kf, {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                task.delay(0.35, function()
                    sg:Destroy()
                    showLoadingScreen(function()
                        callback(role)
                    end)
                end)
            end)
        else
            attemptCount = attemptCount + 1
            local remaining = MAX_ATTEMPTS - attemptCount
            attemptsLbl.Text = "Tentatives restantes : " .. remaining

            if attemptCount >= MAX_ATTEMPTS then
                addToBlacklist(userId)
                errLabel.Text = "⛔ Trop de tentatives ! Contactez le staff."
                errLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                validateBtn.Active = false
                validateBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
                validateBtn.Text = "Accès bloqué"
                task.delay(2, function()
                    sg:Destroy()
                    showKeyScreen(callback)
                end)
                return
            end

            local msgs = {
                expired = "⏰ Clé expirée ! Contactez l'admin.",
                userid  = "🔒 Cette clé n'est pas liée à votre compte.",
                used    = "🔑 Cette clé a déjà été utilisée.",
                invalid = "❌ Clé invalide, réessayez. (" .. remaining .. " restante" .. (remaining > 1 and "s" or "") .. ")",
            }
            errLabel.Text = msgs[reason] or "❌ Clé invalide."
            errLabel.TextColor3 = reason == "expired" and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(255, 80, 80)
            tween(inputBg, {BackgroundColor3 = Color3.fromRGB(80, 30, 30)}, 0.1)
            task.delay(0.6, function()
                tween(inputBg, {BackgroundColor3 = CONFIG.Element}, 0.3)
            end)
        end
    end)
end

-- ═══════════════════════════════════════
--           CRÉATION DE FENÊTRE
-- ═══════════════════════════════════════
function Library:CreateWindow(title, requireKey, onReady)
    local Window = {}
    Window._tabs      = {}
    Window._activeTab = nil
    Window._tabBtns   = {}

    local function buildWindow(role)
        role = role or "Free"

        -- Curseur personnalisé
        createCursor()
        enableCursor()

        local sg = Instance.new("ScreenGui")
        sg.Name = "CustomLib"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = game.CoreGui

        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, CONFIG.WindowWidth, 0, CONFIG.WindowHeight)
        main.Position = UDim2.new(0.5, -CONFIG.WindowWidth/2, 0.5, -CONFIG.WindowHeight/2)
        main.BackgroundColor3 = CONFIG.Background
        main.BorderSizePixel = 0
        main.Parent = sg
        addCorner(main, UDim.new(0, 8))
        addStroke(main, CONFIG.Border, 1)

        -- TopBar
        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 40)
        topBar.BackgroundColor3 = CONFIG.TopBar
        topBar.BorderSizePixel = 0
        topBar.Parent = main
        addCorner(topBar, UDim.new(0, 8))

        local fix = Instance.new("Frame")
        fix.Size = UDim2.new(1, 0, 0.5, 0)
        fix.Position = UDim2.new(0, 0, 0.5, 0)
        fix.BackgroundColor3 = CONFIG.TopBar
        fix.BorderSizePixel = 0
        fix.Parent = topBar

        makeLabel(topBar, title or "Ma GUI",
            UDim2.new(1, -130, 1, 0), UDim2.new(0, 12, 0, 0),
            Enum.Font.GothamBold, 14, CONFIG.Text, Enum.TextXAlignment.Left)

        -- Bouton fermer
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 28, 0, 28)
        closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 12
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = topBar
        addCorner(closeBtn, UDim.new(0, 6))
        closeBtn.MouseButton1Click:Connect(function()
            disableCursor()
            tween(main, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(0.35, function() sg:Destroy() end)
        end)

        -- Bouton minimiser
        local minimized = false
        local minBtn = Instance.new("TextButton")
        minBtn.Size = UDim2.new(0, 28, 0, 28)
        minBtn.Position = UDim2.new(1, -70, 0.5, -14)
        minBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 40)
        minBtn.Text = "—"
        minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minBtn.Font = Enum.Font.GothamBold
        minBtn.TextSize = 12
        minBtn.BorderSizePixel = 0
        minBtn.Parent = topBar
        addCorner(minBtn, UDim.new(0, 6))

        -- ✅ Mode compact
        local compactMode = false
        local compactBtn = Instance.new("TextButton")
        compactBtn.Size = UDim2.new(0, 28, 0, 28)
        compactBtn.Position = UDim2.new(1, -104, 0.5, -14)
        compactBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
        compactBtn.Text = "⊟"
        compactBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        compactBtn.Font = Enum.Font.GothamBold
        compactBtn.TextSize = 12
        compactBtn.BorderSizePixel = 0
        compactBtn.Parent = topBar
        addCorner(compactBtn, UDim.new(0, 6))

        compactBtn.MouseButton1Click:Connect(function()
            compactMode = not compactMode
            if compactMode then
                -- Mode compact : juste la topbar visible, déplace en coin
                tween(main, {
                    Size = UDim2.new(0, 180, 0, 40),
                    Position = UDim2.new(1, -190, 0, 10)
                }, 0.3, Enum.EasingStyle.Back)
                compactBtn.Text = "⊞"
            else
                tween(main, {
                    Size = UDim2.new(0, CONFIG.WindowWidth, 0, CONFIG.WindowHeight),
                    Position = UDim2.new(0.5, -CONFIG.WindowWidth/2, 0.5, -CONFIG.WindowHeight/2)
                }, 0.3, Enum.EasingStyle.Back)
                compactBtn.Text = "⊟"
            end
        end)

        minBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            tween(main, {
                Size = minimized
                    and UDim2.new(0, CONFIG.WindowWidth, 0, 40)
                    or  UDim2.new(0, CONFIG.WindowWidth, 0, CONFIG.WindowHeight)
            }, 0.3, Enum.EasingStyle.Back)
        end)

        makeDraggable(main, topBar)

        -- ✅ Redimensionnement (coin bas-droit)
        local resizeHandle = Instance.new("TextButton")
        resizeHandle.Size = UDim2.new(0, 16, 0, 16)
        resizeHandle.Position = UDim2.new(1, -16, 1, -16)
        resizeHandle.BackgroundColor3 = CONFIG.Border
        resizeHandle.Text = ""
        resizeHandle.BorderSizePixel = 0
        resizeHandle.ZIndex = 10
        resizeHandle.Parent = main
        addCorner(resizeHandle, UDim.new(0, 3))

        -- Triangle visuel dans le coin
        local resizeIcon = makeLabel(resizeHandle, "⤡",
            UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
            Enum.Font.GothamBold, 10, CONFIG.TextDim)

        local resizing = false
        local resizeStart = nil
        local startSize   = nil
        local startPos2   = nil

        resizeHandle.MouseButton1Down:Connect(function()
            resizing    = true
            resizeStart = UserInputService:GetMouseLocation()
            startSize   = main.AbsoluteSize
            startPos2   = main.AbsolutePosition
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
        end)
        RunService.RenderStepped:Connect(function()
            if not resizing then return end
            local mouse = UserInputService:GetMouseLocation()
            local dx = mouse.X - resizeStart.X
            local dy = mouse.Y - resizeStart.Y
            local newW = math.max(CONFIG.WindowMinW, startSize.X + dx)
            local newH = math.max(CONFIG.WindowMinH, startSize.Y + dy)
            main.Size = UDim2.new(0, newW, 0, newH)
        end)

        -- Profil
        local profile = Instance.new("Frame")
        profile.Size = UDim2.new(1, 0, 0, CONFIG.ProfileHeight)
        profile.Position = UDim2.new(0, 0, 0, 40)
        profile.BackgroundColor3 = CONFIG.ProfileBg
        profile.BorderSizePixel = 0
        profile.Parent = main
        addStroke(profile, CONFIG.Border, 1)

        local avatarBg = Instance.new("Frame")
        avatarBg.Size = UDim2.new(0, 50, 0, 50)
        avatarBg.Position = UDim2.new(0, 10, 0.5, -25)
        avatarBg.BackgroundColor3 = CONFIG.Element
        avatarBg.BorderSizePixel = 0
        avatarBg.Parent = profile
        addCorner(avatarBg, UDim.new(1, 0))
        addStroke(avatarBg, KeyColors[role] or CONFIG.Border, 2)

        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(1, 0, 1, 0)
        avatar.BackgroundTransparency = 1
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
        avatar.Parent = avatarBg
        addCorner(avatar, UDim.new(1, 0))

        makeLabel(profile, LocalPlayer.DisplayName,
            UDim2.new(0, 200, 0, 20), UDim2.new(0, 70, 0, 8),
            Enum.Font.GothamBold, 13, CONFIG.Text, Enum.TextXAlignment.Left)

        makeLabel(profile, "@" .. LocalPlayer.Name,
            UDim2.new(0, 200, 0, 16), UDim2.new(0, 70, 0, 28),
            Enum.Font.Gotham, 10, CONFIG.TextDim, Enum.TextXAlignment.Left)

        -- Message personnalisé par rôle
        local roleMsg = _G.MNCKeyMsg or RoleMessages[role] or ""
        makeLabel(profile, roleMsg,
            UDim2.new(0, 240, 0, 16), UDim2.new(0, 70, 0, 46),
            Enum.Font.Gotham, 9, KeyColors[role] or CONFIG.TextDim, Enum.TextXAlignment.Left)

        local clockBg = Instance.new("Frame")
        clockBg.Size = UDim2.new(0, 105, 0, 30)
        clockBg.Position = UDim2.new(1, -115, 0.5, -15)
        clockBg.BackgroundColor3 = CONFIG.Element
        clockBg.BorderSizePixel = 0
        clockBg.Parent = profile
        addCorner(clockBg, UDim.new(0, 6))
        addStroke(clockBg, CONFIG.Border, 1)

        makeLabel(clockBg, "🕐",
            UDim2.new(0, 22, 1, 0), UDim2.new(0, 4, 0, 0),
            Enum.Font.Gotham, 12, CONFIG.Text)

        local clockLbl = makeLabel(clockBg, getTime(),
            UDim2.new(1, -28, 1, 0), UDim2.new(0, 26, 0, 0),
            Enum.Font.GothamBold, 13, CONFIG.TabActive, Enum.TextXAlignment.Left)

        RunService.Heartbeat:Connect(function()
            clockLbl.Text = getTime()
        end)

        -- TabBar
        local tabBarY = 40 + CONFIG.ProfileHeight
        local tabBar = Instance.new("Frame")
        tabBar.Size = UDim2.new(1, 0, 0, CONFIG.TabHeight)
        tabBar.Position = UDim2.new(0, 0, 0, tabBarY)
        tabBar.BackgroundColor3 = CONFIG.TabBar
        tabBar.BorderSizePixel = 0
        tabBar.Parent = main
        addListLayout(tabBar, 4, Enum.FillDirection.Horizontal)
        addPadding(tabBar, 4)

        -- Arc-en-ciel tabs
        local rainbowHue = 0
        RunService.Heartbeat:Connect(function(dt)
            rainbowHue = (rainbowHue + dt * 0.25) % 1
            for i, data in ipairs(Window._tabBtns) do
                local offset = (i - 1) / math.max(#Window._tabBtns, 1)
                local h = (rainbowHue + offset * 0.6) % 1
                local col = hueToColor(h)
                if Window._activeTab and Window._activeTab.btn == data.btn then
                    data.btn.BackgroundColor3 = col
                    data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    if data.stroke then data.stroke.Color = col end
                else
                    data.btn.BackgroundColor3 = Color3.fromRGB(
                        math.floor(col.R * 255 * 0.35),
                        math.floor(col.G * 255 * 0.35),
                        math.floor(col.B * 255 * 0.35)
                    )
                    data.btn.TextColor3 = CONFIG.TextDim
                end
            end
        end)

        local contentY = tabBarY + CONFIG.TabHeight
        local contentArea = Instance.new("Frame")
        contentArea.Size = UDim2.new(1, 0, 1, -contentY)
        contentArea.Position = UDim2.new(0, 0, 0, contentY)
        contentArea.BackgroundTransparency = 1
        contentArea.BorderSizePixel = 0
        contentArea.Parent = main

        -- ════════════════════════════
        --      Window:AddTab
        -- ════════════════════════════
        function Window:AddTab(tabName, adminOnly)
            -- adminOnly = true : tab visible uniquement pour Admin
            if adminOnly and role ~= "Admin" then
                return {
                    AddLabel = function() end,
                    AddSeparator = function() end,
                    AddInfo = function() return function() end end,
                    AddButton = function() end,
                    AddToggle = function() return {SetState=function()end,GetState=function()return false end} end,
                    AddSlider = function() return {SetValue=function()end,GetValue=function()return 0 end} end,
                    AddInput = function() end,
                    AddDropdown = function() return {GetSelected=function()return "" end,SetSelected=function()end} end,
                }
            end

            local Tab = {}

            local tabBtn = Instance.new("TextButton")
            tabBtn.Size = UDim2.new(0, 78, 1, -6)
            tabBtn.BackgroundColor3 = CONFIG.TabInactive
            tabBtn.Text = tabName
            tabBtn.TextColor3 = CONFIG.TextDim
            tabBtn.Font = Enum.Font.GothamSemibold
            tabBtn.TextSize = 11
            tabBtn.BorderSizePixel = 0
            tabBtn.Parent = tabBar
            addCorner(tabBtn, UDim.new(0, 5))
            local tabStroke = addStroke(tabBtn, CONFIG.Border, 1)

            -- Badge rouge sur tab Admin
            if adminOnly then
                local badge = Instance.new("Frame")
                badge.Size = UDim2.new(0, 8, 0, 8)
                badge.Position = UDim2.new(1, -10, 0, 2)
                badge.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                badge.BorderSizePixel = 0
                badge.Parent = tabBtn
                addCorner(badge, UDim.new(1, 0))
            end

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, 0, 1, 0)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 3
            scroll.ScrollBarImageColor3 = CONFIG.TabActive
            scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroll.Visible = false
            scroll.Parent = contentArea
            local layout = addListLayout(scroll, 6)
            addPadding(scroll, 8)

            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
            end)

            local function activate()
                if Window._activeTab then
                    Window._activeTab.frame.Visible = false
                end
                Window._activeTab = {btn = tabBtn, frame = scroll}
                scroll.Visible = true
            end

            tabBtn.MouseButton1Click:Connect(activate)
            if #Window._tabs == 0 then activate() end
            table.insert(Window._tabs, {btn = tabBtn, frame = scroll})
            table.insert(Window._tabBtns, {btn = tabBtn, stroke = tabStroke})

            local function makeElement(labelText, descText)
                local c = Instance.new("Frame")
                c.Size = UDim2.new(1, -16, 0, CONFIG.ElementHeight)
                c.BackgroundColor3 = CONFIG.Element
                c.BorderSizePixel = 0
                c.Parent = scroll
                addCorner(c)
                addStroke(c, CONFIG.Border, 1)
                c.MouseEnter:Connect(function() tween(c, {BackgroundColor3 = CONFIG.ElementHover}, 0.1) end)
                c.MouseLeave:Connect(function() tween(c, {BackgroundColor3 = CONFIG.Element}, 0.1) end)
                makeLabel(c, labelText,
                    descText and UDim2.new(0.55, 0, 0.5, 0) or UDim2.new(0.55, 0, 1, 0),
                    UDim2.new(0, 10, 0, 0),
                    Enum.Font.GothamSemibold, 12, CONFIG.Text, Enum.TextXAlignment.Left)
                if descText then
                    makeLabel(c, descText,
                        UDim2.new(0.55, 0, 0.5, 0), UDim2.new(0, 10, 0.5, 0),
                        Enum.Font.Gotham, 10, CONFIG.TextDim, Enum.TextXAlignment.Left)
                end
                return c
            end

            function Tab:AddLabel(text)
                local c = Instance.new("Frame")
                c.Size = UDim2.new(1, -16, 0, CONFIG.ElementHeight)
                c.BackgroundColor3 = CONFIG.TabBar
                c.BorderSizePixel = 0
                c.Parent = scroll
                addCorner(c)
                makeLabel(c, text, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
                    Enum.Font.GothamSemibold, 12, CONFIG.TextDim)
            end

            function Tab:AddSeparator(text)
                local sep = Instance.new("Frame")
                sep.Size = UDim2.new(1, -16, 0, 20)
                sep.BackgroundTransparency = 1
                sep.Parent = scroll
                local line = Instance.new("Frame")
                line.Size = UDim2.new(1, 0, 0, 1)
                line.Position = UDim2.new(0, 0, 0.5, 0)
                line.BackgroundColor3 = CONFIG.Border
                line.BorderSizePixel = 0
                line.Parent = sep
                if text then
                    local sl = Instance.new("TextLabel")
                    sl.Size = UDim2.new(0, 0, 1, 0)
                    sl.AutomaticSize = Enum.AutomaticSize.X
                    sl.Position = UDim2.new(0.5, 0, 0, 0)
                    sl.AnchorPoint = Vector2.new(0.5, 0)
                    sl.BackgroundColor3 = CONFIG.Background
                    sl.Text = "  " .. text .. "  "
                    sl.TextColor3 = CONFIG.TextDim
                    sl.Font = Enum.Font.Gotham
                    sl.TextSize = 10
                    sl.BorderSizePixel = 0
                    sl.Parent = sep
                end
            end

            function Tab:AddInfo(icon, labelText, defaultValue)
                local c = Instance.new("Frame")
                c.Size = UDim2.new(1, -16, 0, CONFIG.ElementHeight)
                c.BackgroundColor3 = CONFIG.InfoBg
                c.BorderSizePixel = 0
                c.Parent = scroll
                addCorner(c)
                addStroke(c, CONFIG.Border, 1)
                makeLabel(c, icon,
                    UDim2.new(0, 28, 1, 0), UDim2.new(0, 6, 0, 0),
                    Enum.Font.Gotham, 14, CONFIG.Text)
                makeLabel(c, labelText,
                    UDim2.new(0.45, 0, 1, 0), UDim2.new(0, 36, 0, 0),
                    Enum.Font.GothamSemibold, 12, CONFIG.TextDim, Enum.TextXAlignment.Left)
                local valLbl = makeLabel(c, tostring(defaultValue or "—"),
                    UDim2.new(0.4, 0, 1, 0), UDim2.new(0.58, 0, 0, 0),
                    Enum.Font.GothamBold, 12, CONFIG.TabActive, Enum.TextXAlignment.Right)
                return function(newValue)
                    valLbl.Text = tostring(newValue)
                end
            end

            function Tab:AddButton(labelText, desc, callback)
                local c = makeElement(labelText, desc)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 80, 0, 22)
                btn.Position = UDim2.new(1, -90, 0.5, -11)
                btn.BackgroundColor3 = CONFIG.TabActive
                btn.Text = "Exécuter"
                btn.TextColor3 = CONFIG.Text
                btn.Font = Enum.Font.GothamSemibold
                btn.TextSize = 11
                btn.BorderSizePixel = 0
                btn.Parent = c
                addCorner(btn, UDim.new(0, 4))
                btn.MouseButton1Click:Connect(function()
                    tween(btn, {BackgroundColor3 = Color3.fromRGB(50,80,200)}, 0.1)
                    task.delay(0.15, function() tween(btn, {BackgroundColor3 = CONFIG.TabActive}, 0.1) end)
                    if callback then callback() end
                end)
            end

            function Tab:AddToggle(labelText, desc, default, callback)
                local state = default or false
                local c = makeElement(labelText, desc)
                local tbg = Instance.new("Frame")
                tbg.Size = UDim2.new(0, 44, 0, 22)
                tbg.Position = UDim2.new(1, -54, 0.5, -11)
                tbg.BackgroundColor3 = state and CONFIG.ToggleOn or CONFIG.ToggleOff
                tbg.BorderSizePixel = 0
                tbg.Parent = c
                addCorner(tbg, UDim.new(1, 0))
                local circle = Instance.new("Frame")
                circle.Size = UDim2.new(0, 16, 0, 16)
                circle.Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
                circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                circle.BorderSizePixel = 0
                circle.Parent = tbg
                addCorner(circle, UDim.new(1, 0))
                local zone = Instance.new("TextButton")
                zone.Size = UDim2.new(1, 0, 1, 0)
                zone.BackgroundTransparency = 1
                zone.Text = ""
                zone.Parent = tbg
                zone.MouseButton1Click:Connect(function()
                    state = not state
                    tween(tbg, {BackgroundColor3 = state and CONFIG.ToggleOn or CONFIG.ToggleOff}, 0.2)
                    tween(circle, {Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.2, Enum.EasingStyle.Back)
                    if callback then callback(state) end
                end)
                return {
                    SetState = function(s)
                        state = s
                        tween(tbg, {BackgroundColor3 = state and CONFIG.ToggleOn or CONFIG.ToggleOff}, 0.2)
                        tween(circle, {Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.2)
                    end,
                    GetState = function() return state end
                }
            end

            function Tab:AddSlider(labelText, desc, min, max, default, callback)
                local value = default or min
                local c = makeElement(labelText, desc)
                c.Size = UDim2.new(1, -16, 0, 52)
                local valLbl = makeLabel(c, tostring(value),
                    UDim2.new(0, 44, 0, 22), UDim2.new(1, -50, 0, 4),
                    Enum.Font.GothamBold, 12, CONFIG.TabActive, Enum.TextXAlignment.Right)
                local sbg = Instance.new("Frame")
                sbg.Size = UDim2.new(1, -20, 0, 8)
                sbg.Position = UDim2.new(0, 10, 1, -18)
                sbg.BackgroundColor3 = CONFIG.ToggleOff
                sbg.BorderSizePixel = 0
                sbg.Parent = c
                addCorner(sbg, UDim.new(1, 0))
                local sfill = Instance.new("Frame")
                sfill.Size = UDim2.new(math.clamp((value-min)/(max-min),0,1), 0, 1, 0)
                sfill.BackgroundColor3 = CONFIG.SliderFill
                sfill.BorderSizePixel = 0
                sfill.Parent = sbg
                addCorner(sfill, UDim.new(1, 0))
                local sBtn = Instance.new("TextButton")
                sBtn.Size = UDim2.new(1, 0, 3, 0)
                sBtn.Position = UDim2.new(0, 0, -1, 0)
                sBtn.BackgroundTransparency = 1
                sBtn.Text = ""
                sBtn.Parent = sbg
                local sliding = false
                sBtn.MouseButton1Down:Connect(function() sliding = true end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
                RunService.RenderStepped:Connect(function()
                    if not sliding then return end
                    local mouse = UserInputService:GetMouseLocation()
                    local abs = sbg.AbsolutePosition
                    local sz  = sbg.AbsoluteSize
                    local pct = math.clamp((mouse.X - abs.X) / sz.X, 0, 1)
                    value = math.floor(min + (max - min) * pct)
                    sfill.Size = UDim2.new(pct, 0, 1, 0)
                    valLbl.Text = tostring(value)
                    if callback then callback(value) end
                end)
                return {
                    SetValue = function(v)
                        value = math.clamp(v, min, max)
                        sfill.Size = UDim2.new((value-min)/(max-min), 0, 1, 0)
                        valLbl.Text = tostring(value)
                    end,
                    GetValue = function() return value end
                }
            end

            function Tab:AddInput(labelText, placeholder, callback)
                local c = makeElement(labelText)
                local ibg = Instance.new("Frame")
                ibg.Size = UDim2.new(0, 160, 0, 24)
                ibg.Position = UDim2.new(1, -170, 0.5, -12)
                ibg.BackgroundColor3 = CONFIG.Dropdown
                ibg.BorderSizePixel = 0
                ibg.Parent = c
                addCorner(ibg, UDim.new(0, 4))
                addStroke(ibg, CONFIG.Border, 1)
                local ibox = Instance.new("TextBox")
                ibox.Size = UDim2.new(1, -10, 1, 0)
                ibox.Position = UDim2.new(0, 5, 0, 0)
                ibox.BackgroundTransparency = 1
                ibox.PlaceholderText = placeholder or "Entrez une valeur..."
                ibox.PlaceholderColor3 = CONFIG.TextDim
                ibox.Text = ""
                ibox.TextColor3 = CONFIG.Text
                ibox.Font = Enum.Font.Gotham
                ibox.TextSize = 11
                ibox.ClearTextOnFocus = false
                ibox.Parent = ibg
                ibox.Focused:Connect(function() tween(ibg, {BackgroundColor3 = Color3.fromRGB(40,40,60)}, 0.1) end)
                ibox.FocusLost:Connect(function(enter)
                    tween(ibg, {BackgroundColor3 = CONFIG.Dropdown}, 0.1)
                    if enter and callback then callback(ibox.Text) end
                end)
                return ibox
            end

            function Tab:AddDropdown(labelText, options, callback)
                local selected = options[1]
                local open = false
                local c = makeElement(labelText)
                c.ClipsDescendants = false
                local dBtn = Instance.new("TextButton")
                dBtn.Size = UDim2.new(0, 160, 0, 24)
                dBtn.Position = UDim2.new(1, -170, 0.5, -12)
                dBtn.BackgroundColor3 = CONFIG.Dropdown
                dBtn.Text = selected .. "  ▾"
                dBtn.TextColor3 = CONFIG.Text
                dBtn.Font = Enum.Font.GothamSemibold
                dBtn.TextSize = 11
                dBtn.BorderSizePixel = 0
                dBtn.ZIndex = 5
                dBtn.Parent = c
                addCorner(dBtn, UDim.new(0, 4))
                addStroke(dBtn, CONFIG.Border, 1)
                local dList = Instance.new("Frame")
                dList.Size = UDim2.new(0, 160, 0, 0)
                dList.Position = UDim2.new(1, -170, 1, 4)
                dList.BackgroundColor3 = CONFIG.Dropdown
                dList.BorderSizePixel = 0
                dList.ClipsDescendants = true
                dList.ZIndex = 10
                dList.Visible = false
                dList.Parent = c
                addCorner(dList, UDim.new(0, 4))
                addStroke(dList, CONFIG.Border, 1)
                addListLayout(dList, 2)
                addPadding(dList, 4)
                for _, option in ipairs(options) do
                    local ob = Instance.new("TextButton")
                    ob.Size = UDim2.new(1, -8, 0, 24)
                    ob.BackgroundColor3 = CONFIG.Dropdown
                    ob.Text = option
                    ob.TextColor3 = CONFIG.Text
                    ob.Font = Enum.Font.Gotham
                    ob.TextSize = 11
                    ob.BorderSizePixel = 0
                    ob.ZIndex = 11
                    ob.Parent = dList
                    addCorner(ob, UDim.new(0, 4))
                    ob.MouseEnter:Connect(function() tween(ob, {BackgroundColor3 = CONFIG.ElementHover}, 0.1) end)
                    ob.MouseLeave:Connect(function() tween(ob, {BackgroundColor3 = CONFIG.Dropdown}, 0.1) end)
                    ob.MouseButton1Click:Connect(function()
                        selected = option
                        dBtn.Text = option .. "  ▾"
                        open = false
                        tween(dList, {Size = UDim2.new(0,160,0,0)}, 0.2)
                        task.delay(0.2, function() dList.Visible = false end)
                        if callback then callback(option) end
                    end)
                end
                local totalH = #options * 28 + 8
                dBtn.MouseButton1Click:Connect(function()
                    open = not open
                    dList.Visible = true
                    tween(dList, {Size = open and UDim2.new(0,160,0,totalH) or UDim2.new(0,160,0,0)}, 0.2, Enum.EasingStyle.Back)
                    if not open then task.delay(0.2, function() dList.Visible = false end) end
                end)
                return {
                    GetSelected = function() return selected end,
                    SetSelected = function(v) selected = v; dBtn.Text = v .. "  ▾" end
                }
            end

            return Tab
        end

        -- Expose saveSession pour MNCStorm
        Window.saveSession = saveSession

        if onReady then
            onReady(Window)
        end
    end

    if requireKey then
        showKeyScreen(function(role)
            buildWindow(role)
        end)
    else
        showLoadingScreen(function()
            buildWindow("Free")
        end)
    end

    return Window
end

return Library
