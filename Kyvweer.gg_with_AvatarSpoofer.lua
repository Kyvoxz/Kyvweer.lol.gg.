--[[
    Kyvweer.gg + Avatar Spoofer (Kicia)
    Sube este archivo a GitHub y usa:
    loadstring(game:HttpGet("TU_RAW_LINK"))()
]]

--==========================================================================
--  1. Cargar el script original de Kyvweer.gg Optimized
--==========================================================================
local KYVWEER_URL = "https://raw.githubusercontent.com/Kyvoxz/Kyvweer.gg./refs/heads/main/Kyvweer.gg.l%20(2).txt" -- cambia por el raw de tu optimized si quieres

local function loadKyvweer()
    local ok, source = pcall(game.HttpGet, game, KYVWEER_URL)
    if not ok or type(source) ~= "string" or #source < 100000 then
        warn("[Kyvweer] No se pudo descargar el script principal")
        return false
    end

    local fn, err = loadstring(source)
    if not fn then
        warn("[Kyvweer] Error loadstring:", err)
        return false
    end

    local success, result = pcall(fn)
    if not success then
        warn("[Kyvweer] Error al ejecutar:", result)
        return false
    end
    return true
end

--==========================================================================
--  2. Avatar Spoofer (extraído y adaptado de Kicia source prem)
--==========================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local AvatarSpoofer = {
    Enabled = false,
    Local = {
        Enabled = false,
        Username = "",
        DisplayName = "",
        UserId = 0,
    },
    Others = {
        Enabled = false,
        Username = "",
        DisplayName = "",
        UserId = 0,
    }
}

local originalDescriptions = {}
local connections = {}

local function getDescription(userId)
    if not userId or userId <= 0 then return nil end
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    return ok and desc or nil
end

local function applyAvatar(character, userId)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local desc = getDescription(userId)
    if not desc then return end

    if not originalDescriptions[character] then
        pcall(function()
            originalDescriptions[character] = humanoid:GetAppliedDescription()
        end)
    end

    pcall(function()
        humanoid:ApplyDescription(desc)
    end)
end

local function processPlayer(player)
    if not AvatarSpoofer.Enabled then return end

    local isLocal = (player == LocalPlayer)
    local data = isLocal and AvatarSpoofer.Local or AvatarSpoofer.Others
    if not data.Enabled then return end

    -- Nombres
    if data.Username ~= "" then
        pcall(function() player.Name = data.Username end)
    end
    if data.DisplayName ~= "" then
        pcall(function() player.DisplayName = data.DisplayName end)
    end

    -- Avatar
    if data.UserId and data.UserId > 0 then
        local function onChar(char)
            task.wait(0.4)
            applyAvatar(char, data.UserId)
        end
        if player.Character then
            task.spawn(onChar, player.Character)
        end
        table.insert(connections, player.CharacterAdded:Connect(onChar))
    end
end

local function start()
    for _, plr in ipairs(Players:GetPlayers()) do
        processPlayer(plr)
    end
    table.insert(connections, Players.PlayerAdded:Connect(processPlayer))
end

local function stop()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)
end

--==========================================================================
--  3. Inyectar UI en el panel de Kyvweer (Visuals → debajo de Crosshair)
--==========================================================================
local function injectUI()
    -- Esperamos a que el Library de Kyvweer exista
    local Library = getgenv().Library or rawget(getgenv(), "Library")
    if not Library then
        -- Reintento un poco más tarde
        task.delay(2, injectUI)
        return
    end

    -- Intentamos encontrar el tab Visuals
    local tabs = Library.Tabs or Library.tabs
    if not tabs then
        warn("[AvatarSpoofer] No se encontró Tabs del Library")
        return
    end

    local visualsTab = tabs["visuals"] or tabs["Visuals"] or tabs["VISUALS"]
    if not visualsTab then
        -- Buscar por nombre
        for name, tab in pairs(tabs) do
            if tostring(name):lower():find("visual") then
                visualsTab = tab
                break
            end
        end
    end

    if not visualsTab then
        warn("[AvatarSpoofer] No se encontró el tab Visuals. El spoofer funciona por código, pero sin botones en el menú.")
        return
    end

    -- Crear el grupo "Avatar Spoofer" debajo de Crosshair
    local ok, group = pcall(function()
        return visualsTab:AddLeftGroupbox("Avatar Spoofer")
            or visualsTab:AddGroupbox("Avatar Spoofer")
            or visualsTab:AddSection("Avatar Spoofer")
    end)

    if not ok or not group then
        -- Fallback: usar print + getgenv para control manual
        getgenv().AvatarSpoofer = AvatarSpoofer
        warn("[AvatarSpoofer] No se pudo crear el groupbox. Usa getgenv().AvatarSpoofer para controlarlo.")
        return
    end

    -- Toggles e inputs
    pcall(function()
        group:AddToggle("AS_Enabled", {
            Text = "Enabled",
            Default = false,
            Callback = function(v)
                AvatarSpoofer.Enabled = v
                if v then start() else stop() end
            end
        })

        group:AddToggle("AS_Local", {
            Text = "Local Player",
            Default = false,
            Callback = function(v)
                AvatarSpoofer.Local.Enabled = v
                if v and AvatarSpoofer.Enabled then processPlayer(LocalPlayer) end
            end
        })

        group:AddInput("AS_LocalUserId", {
            Text = "Local UserId",
            Default = "",
            Numeric = true,
            Finished = true,
            Callback = function(v)
                AvatarSpoofer.Local.UserId = tonumber(v) or 0
            end
        })

        group:AddInput("AS_LocalUsername", {
            Text = "Local Username",
            Default = "",
            Finished = true,
            Callback = function(v)
                AvatarSpoofer.Local.Username = v
            end
        })

        group:AddInput("AS_LocalDisplay", {
            Text = "Local DisplayName",
            Default = "",
            Finished = true,
            Callback = function(v)
                AvatarSpoofer.Local.DisplayName = v
            end
        })

        group:AddToggle("AS_Others", {
            Text = "Other Players",
            Default = false,
            Callback = function(v)
                AvatarSpoofer.Others.Enabled = v
            end
        })

        group:AddInput("AS_OthersUserId", {
            Text = "Others UserId",
            Default = "",
            Numeric = true,
            Finished = true,
            Callback = function(v)
                AvatarSpoofer.Others.UserId = tonumber(v) or 0
            end
        })
    end)

    getgenv().AvatarSpoofer = AvatarSpoofer
    print("[Kyvweer] Avatar Spoofer inyectado en Visuals → Avatar Spoofer")
end

--==========================================================================
--  4. Ejecutar todo
--==========================================================================
print("[Kyvweer] Cargando script principal...")
if loadKyvweer() then
    print("[Kyvweer] Script principal cargado. Inyectando Avatar Spoofer...")
    task.delay(1.5, injectUI)
else
    warn("[Kyvweer] Falló la carga del script principal. Avatar Spoofer no se inyectó.")
end
