local BOT_TOKEN = "______________" 

local function sendLog(channel, name, discordName, discordId, ip, license, license2, status)
    local color = (status == "Accepted") and 3066993 or 15158332
    local title = (status == "Accepted") and "✅ ผู้เล่นเข้าสู่เซิร์ฟเวอร์" or "❌ การเชื่อมต่อถูกปฏิเสธ"
    local emoji = (status == "Accepted") and "🟢" or "🔴"

    local embed = {
        {
            title = emoji .. " " .. title,
            fields = {
                { name = "👤 ชื่อผู้เล่น", value = "`" .. name .. "`", inline = true },
                { name = "📛 Discord", value = discordName and ("`" .. discordName .. "`") or "`ไม่พบข้อมูล`", inline = true },
                { name = "🆔 Discord ID", value = discordId and ("`" .. discordId .. "`") or "`ไม่พบข้อมูล`", inline = true },
                { name = "🌍 IP", value = "||" .. ip .. "||", inline = false },
                { name = "🔑 License", value = license and ("||" .. license .. "||") or "`ไม่พบข้อมูล`", inline = false },
                { name = "🔑 License 2", value = license2 and ("||" .. license2 .. "||") or "`ไม่พบข้อมูล`", inline = false },
            },
            color = color,
            footer = { text = "📅 เวลา | " .. os.date("%d/%m/%Y %H:%M:%S") },
        }
    }

    PerformHttpRequest("https://discord.com/api/v10/channels/" .. channel .. "/messages", function(status, response)
        if status ~= 200 then print("❌ Log Error: " .. status .. " - " .. response) end
    end, "POST", json.encode({ embeds = embed }), {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. BOT_TOKEN
    })
end

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    local ids = GetPlayerIdentifiers(src)
    local discordId, ip, license, license2 = nil, GetPlayerEndpoint(src), nil, nil

    for _, id in ipairs(ids) do
        if id:sub(1, 7) == "license" then
            if not license then license = id:sub(9) else license2 = id:sub(9) end
        elseif id:sub(1, 8) == "discord:" then
            discordId = id:sub(9)
        end
    end

    deferrals.defer()
    deferrals.update("กำลังตรวจสอบชื่อใน Discord...")

    if not discordId then
        sendLog(Config.Log, name, nil, nil, ip, license, license2, "Rejected")
        return deferrals.done(Config.DisFIVEM)
    end

    PerformHttpRequest("https://discord.com/api/guilds/" .. Config.Serverdis .. "/members/" .. discordId, function(status, response)
        if status == 200 then
            local data = json.decode(response)
            local discordName = data.nick or data.user.username

            if discordName == name then
                sendLog(Config.Log, name, discordName, discordId, ip, license, license2, "Accepted")
                deferrals.done()
            else
                sendLog(Config.Log, name, discordName, discordId, ip, license, license2, "Rejected")
                deferrals.done(string.format(Config.Check, discordName))
            end
        else
            sendLog(Config.Log, name, nil, discordId, ip, license, license2, "Rejected")
            deferrals.done(Config.Error)
        end
    end, "GET", "", { ["Authorization"] = "Bot " .. BOT_TOKEN })
end)
