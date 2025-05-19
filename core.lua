local E, L, V, P, G = unpack(ElvUI);
local CH = E:GetModule("Chat")
local EM = E:NewModule("ExtraEmojis", "AceHook-3.0", "AceEvent-3.0");
local EP = LibStub("LibElvUIPlugin-1.0")
local addon, addonTable = ...

local format = string.format

-- Default settings
P["extraEmojis"] = {
    enable = true,
    emojiSize = 16 -- Default size setting
}

function EM:ColorizeSettingName(name)
    return format("|cffff3333%s|r", name)
end

-- Module initialization
function EM:Initialize()
    if not E.private.chat.enable then return end
    
    -- Hook to CH:DefaultSmileys to add our additional emojis
    self:SecureHook(CH, "DefaultSmileys", "AddExtraEmojis")
    
    -- Apply our emojis now if chat is already initialized
    if CH.Initialized then
        self:AddExtraEmojis()
    end

    -- Register plugin with ElvUI
    EP:RegisterPlugin(addon, self.ConfigTable)
end

-- Function to get the emoji size format from settings
function EM:GetEmojiSize()
    local size = E.db.extraEmojis.emojiSize or 16
    return ":" .. size .. ":" .. size
end

-- Function to add extra emojis
function EM:AddExtraEmojis()
    if not E.db.extraEmojis or not E.db.extraEmojis.enable then return end
    
    -- Get the emoji size format from settings
    local emojiSize = self:GetEmojiSize()
    
    -- Path to emoji textures
    local customPath = "Interface\\AddOns\\ElvUI_ExtraEmojis\\Media\\"
    
    -- Add custom emojis (you'll need to create these texture files)
    CH:AddSmiley(":epog:", E:TextureString(customPath.."Epog.tga", emojiSize))
    
    -- You can also add alternative text triggers for existing ElvUI emojis
    CH:AddSmiley(":-)", E:TextureString(E.Media.ChatEmojis.Smile, emojiSize))
    CH:AddSmiley(":3", E:TextureString(E.Media.ChatEmojis.Smirk, emojiSize))
    CH:AddSmiley(":thinking_face:", E:TextureString(E.Media.ChatEmojis.Thinking, emojiSize))
end

local function CopyURLToChat(url)
    local editBox = ChatEdit_ChooseBoxForSend()
    ChatEdit_ActivateChat(editBox)
    editBox:SetText(url)
    editBox:HighlightText()
end

function EM:ConfigTable()
    E.Options.args.extraEmojis = {
        order = 50,
        type = "group",
        name = EM:ColorizeSettingName("Extra Emojis"),
        args = {
            header = {
                order = 1,
                type = "header",
                name = EM:ColorizeSettingName("Extra Emojis Configuration"),
            },
            enable = {
                order = 2,
                type = "toggle",
                name = "Enable",
                desc = "Enable/Disable extra emojis in chat",
                get = function(info) return E.db.extraEmojis.enable end,
                set = function(info, value) 
                    E.db.extraEmojis.enable = value
                    CH:DefaultSmileys()
                    EM:AddExtraEmojis()
                end,
            },
            emojiSize = {
                order = 3,
                type = "range",
                min = 8, max = 64, step = 1,
                name = "Emoji Size",
                desc = "Sets the size of the emojis",
                get = function(info) return E.db.extraEmojis.emojiSize end,
                set = function(info, value) 
                    E.db.extraEmojis.emojiSize = value
                    CH:DefaultSmileys()
                    EM:AddExtraEmojis()
                end,
                disabled = function() return not E.db.extraEmojis.enable end,
            },
            emojiInfo = {
                order = 4,
                type = "description",
                name = "If you wish to request more emojis or contribute please visit https://github.com/Bennylavaa/ElvUI_ExtraEmojis \n\nUse the button below to copy the URL",
            },
            copyURL = {
                order = 5,
                type = "execute",
                name = "Copy GitHub URL",
                desc = "Click to copy the GitHub URL to your chat input box",
                func = function() CopyURLToChat("https://github.com/Bennylavaa/ElvUI_ExtraEmojis") end,
            }
        },
    }
end

-- Add slash command to manually enable/disable
SLASH_EXTRAEMOJIS1 = "/extraemojis"
SlashCmdList["EXTRAEMOJIS"] = function(msg)
    if msg == "on" then
        print("Extra Emojis: Enabled")
        E.db.extraEmojis = E.db.extraEmojis or {}
        E.db.extraEmojis.enable = true
        CH:DefaultSmileys()
        EM:AddExtraEmojis()
    elseif msg == "off" then
        print("Extra Emojis: Disabled")
        E.db.extraEmojis = E.db.extraEmojis or {}
        E.db.extraEmojis.enable = false
        CH:DefaultSmileys()
    elseif msg == "url" then
        CopyURLToChat("https://github.com/Bennylavaa/ElvUI_ExtraEmojis")
    else
        print("Extra Emojis: Use /extraemojis on, /extraemojis off, or /extraemojis url")
    end
end

-- Initialize Module
E:RegisterModule(EM:GetName(), function()
    EM:Initialize()
end)

-- Updater
function hcstrsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

local major, minor, fix = hcstrsplit(".", tostring(GetAddOnMetadata("ElvUI_ExtraEmojis", "Version")))
fix = fix or 0 -- Set fix to 0 if it is nil

local alreadyshown = false
local localversion  = tonumber(major*10000 + minor*100 + fix)
local remoteversion = tonumber(gpiupdateavailable) or 0
local loginchannels = { "BATTLEGROUND", "RAID", "GUILD", "PARTY" }
local groupchannels = { "BATTLEGROUND", "RAID", "PARTY" }
  
gpiupdater = CreateFrame("Frame")
gpiupdater:RegisterEvent("CHAT_MSG_ADDON")
gpiupdater:RegisterEvent("PLAYER_ENTERING_WORLD")
gpiupdater:RegisterEvent("PARTY_MEMBERS_CHANGED")
gpiupdater:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local arg1, arg2 = ...
        if arg1 == "ElvUIEE" then
            local v, remoteversion = hcstrsplit(":", arg2)
            remoteversion = tonumber(remoteversion)
            if v == "VERSION" and remoteversion then
                if remoteversion > localversion then
                    gpiupdateavailable = remoteversion
                    if not alreadyshown then
                        print("|cff1784d1E|r|cffe5e3e3lvUI|r |cff1784d1E|r|cffe5e3e3xtra|r |cff1784d1E|r|cffe5e3e3mojis|r New version available! |cff66ccffhttps://github.com/Bennylavaa/ElvUI_ExtraEmojis|r")
                        alreadyshown = true
                    end
                end
            end
            --This is a little check that I can use to see if people are actually using the addon.
            if v == "PING?" then
                for _, chan in ipairs(loginchannels) do
                    SendAddonMessage("ElvUIEE", "PONG!:"..GetAddOnMetadata("ElvUI_ExtraEmojis", "Version"), chan)
                end
            end
            if v == "PONG!" then
                --print(arg1 .." "..arg2.." "..arg3.." "..arg4)
            end
        end

        if event == "PARTY_MEMBERS_CHANGED" then
            local groupsize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers() > 0 and GetNumPartyMembers() or 0
            if (this.group or 0) < groupsize then
                for _, chan in ipairs(groupchannels) do
                    SendAddonMessage("ElvUIEE", "VERSION:" .. localversion, chan)
                end
            end
            this.group = groupsize
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not alreadyshown and localversion < remoteversion then
            print("|cff1784d1E|r|cffe5e3e3lvUI|r |cff1784d1E|r|cffe5e3e3xtra|r |cff1784d1E|r|cffe5e3e3mojis|r New version available! |cff66ccffhttps://github.com/Bennylavaa/ElvUI_ExtraEmojis|r")
            gpiupdateavailable = localversion
            alreadyshown = true
        end

        for _, chan in ipairs(loginchannels) do
            SendAddonMessage("ElvUIEE", "VERSION:" .. localversion, chan)
        end
    end
end)