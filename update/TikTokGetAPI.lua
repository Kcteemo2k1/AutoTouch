----------------------------------------------------------------
-- TikTok AutoFollow – By_Mr_L
----------------------------------------------------------------
local jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJ2dWFnYTJrMSIsImxldmVsIjoxLCJmdWxsX25hbWUiOiJOZ3V5ZW5EdXlMYW0iLCJ1c2VyX2lkIjo5MCwibGFzdF90aW1lX3B3IjowLCJpYXQiOjE3NTI1NjI4OTZ9.VUD0P6-3sajjoazq3gIDB3pzO6__7r9GPhsucr8qweA"
local deviceID = "227ce1968e1b431a"
local apiURL = "https://ibestcloud.com/api/v1/tool/action/get?action_type=Tiktok&jwt=" .. jwt .. "&device_id=" .. deviceID

local imgPath = rootDir() .. "/img/"

----------------------------------------------------------------
-- 📡 Gọi deeplink (mở TikTok)
----------------------------------------------------------------
local function openDeep(url)
    if type(openURL) == "function" then return openURL(url) end
    if type(appOpenURL) == "function" then return appOpenURL(url) end
    require "objc"
    local NSURL, UIApplication = objc.NSURL, objc.UIApplication
    return UIApplication:sharedApplication():openURL_(NSURL:URLWithString_(url))
end

----------------------------------------------------------------
-- 🌐 Gọi API
----------------------------------------------------------------
local function getAPIResponse()
    local curl = require("cURL")
    local response = ""
    local c = curl.easy{
        url = apiURL,
        ssl_verifypeer = false,
        ssl_verifyhost = false,
        writefunction = function(str)
            response = response .. str
            return #str
        end
    }
    local ok, err = pcall(function() c:perform() end)
    c:close()
    if not ok then
        toast("❌ API lỗi: " .. tostring(err)); return nil
    end
    return response
end

----------------------------------------------------------------
-- 🔍 Trích xuất username từ JSON
----------------------------------------------------------------
local function extractUsernames(json)
    local usernames = {}
    for block in json:gmatch('"linkAcc"%s*:%s*%[(.-)%]') do
        for link in block:gmatch('"(.-)"') do
            local username = link:match("tiktok%.com/@([^/?]+)")
            if username then
                table.insert(usernames, username)
            end
        end
    end
    return usernames
end

----------------------------------------------------------------
-- 🔘 Tìm và nhấn nút Follow
----------------------------------------------------------------
local function findImg(name, thr)
    local r = findImage(imgPath .. name, 1, thr or 0.6, nil, false, 2)
    return r and #r > 0 and {r[1][1], r[1][2]} or nil
end

local function tap(x, y)
    if not x then return end
    touchDown(1, x, y); usleep(80000)
    touchUp(1, x, y); usleep(800000)
end

local function followIfNeeded()
usleep(80000)
    local p = findImg("follow_button.png", 0.6)
    if p then
        tap(p[1], p[2])
        toast("✅ Đã nhấn Follow"); usleep(3000000)
    else
        toast("⚠️ Không thấy nút Follow"); usleep(2000000)
    end
end

----------------------------------------------------------------
-- 🔁 MAIN LOOP – gọi API liên tục mỗi 5–10 giây
----------------------------------------------------------------
while true do
    toast("📡 Gọi API...")
    local json = getAPIResponse()
    if not json then
        toast("⚠️ API lỗi – thử lại sau"); usleep(5000000)
    else
        local usernames = extractUsernames(json)
        if #usernames == 0 then
            toast("⏳ Không có username – đợi 7s"); usleep(7000000)
        else
            for i, username in ipairs(usernames) do
                local link = "snssdk1233://user/@" .. username
                toast("🔗 ("..i..") @" .. username)
                openDeep(link)
                usleep(6000000)          -- chờ TikTok load
                followIfNeeded()
                usleep(3000000)          -- nghỉ ngắn trước user tiếp theo
            end
        end
    end
    usleep(5000000)                      -- 🕐 Lặp lại sau 5 giây
end

toast("🎉 Xong xuôi – Script by Mr.L")
