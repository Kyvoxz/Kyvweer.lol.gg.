local source = game:HttpGet("https://github.com/Kyvoxz/Kyvweer.lol.gg./edit/main/Kyvweer.gg_with_AvatarSpoofer.lua")
local fn = loadstring(source)
if fn then fn() end

task.delay(3, function()
    local Library = getgenv().Library
    if not Library or not Library.Tabs then return end

    local visuals
    for name, tab in pairs(Library.Tabs) do
        if tostring(name):lower():find("visual") then
            visuals = tab
            break
        end
    end
    if not visuals then return end

    local group = visuals:AddLeftGroupbox("Avatar Spoofer")
    if not group then return end

    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local AS = {
        Enabled = false,
        Local = {Enabled = false, UserId = 0, Username = "", DisplayName = ""},
        Others = {Enabled = false, UserId = 0, Username = "", DisplayName = ""}
    }
    local originals, conns = {}, {}

    local function getDesc(id)
        if not id or id <= 0 then return nil end
        local ok, d = pcall(Players.GetHumanoidDescriptionFromUserId, Players, id)
        return ok and d or nil
    end

    local function apply(char, id)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local desc = getDesc(id)
        if not desc then return end
        if not originals[char] then pcall(function() originals[char] = hum:GetAppliedDescription() end) end
        pcall(hum.ApplyDescription, hum, desc)
    end

    local function process(plr)
        if not AS.Enabled then return end
        local data = (plr == LP) and AS.Local or AS.Others
        if not data.Enabled then return end
        if data.Username ~= "" then pcall(function() plr.Name = data.Username end) end
        if data.DisplayName ~= "" then pcall(function() plr.DisplayName = data.DisplayName end) end
        if data.UserId > 0 then
            local function onChar(c) task.wait(0.4) apply(c, data.UserId) end
            if plr.Character then task.spawn(onChar, plr.Character) end
            table.insert(conns, plr.CharacterAdded:Connect(onChar))
        end
    end

    local function start()
        for _, p in ipairs(Players:GetPlayers()) do process(p) end
        table.insert(conns, Players.PlayerAdded:Connect(process))
    end

    local function stop()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
    end

    group:AddToggle("AS_Enabled", {Text = "Enabled", Default = false, Callback = function(v) AS.Enabled = v if v then start() else stop() end end})
    group:AddToggle("AS_Local", {Text = "Local Player", Default = false, Callback = function(v) AS.Local.Enabled = v end})
    group:AddInput("AS_LocalId", {Text = "Local UserId", Default = "", Numeric = true, Finished = true, Callback = function(v) AS.Local.UserId = tonumber(v) or 0 end})
    group:AddInput("AS_LocalUser", {Text = "Local Username", Default = "", Finished = true, Callback = function(v) AS.Local.Username = v end})
    group:AddInput("AS_LocalDisplay", {Text = "Local DisplayName", Default = "", Finished = true, Callback = function(v) AS.Local.DisplayName = v end})
    group:AddToggle("AS_Others", {Text = "Other Players", Default = false, Callback = function(v) AS.Others.Enabled = v end})
    group:AddInput("AS_OthersId", {Text = "Others UserId", Default = "", Numeric = true, Finished = true, Callback = function(v) AS.Others.UserId = tonumber(v) or 0 end})
end)
