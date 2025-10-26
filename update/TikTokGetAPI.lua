
----------------------------------------------------------------

local jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJ2dWFnYTJrMSIsImxldmVsIjo5OSwiZnVsbF9uYW1lIjoiTmd1eWVuRHV5TGFtIiwidXNlcl9pZCI6OTAsImxhc3RfdGltZV9wdyI6MCwiaWF0IjoxNzYwMDA0MjQwfQ.4yWJZINPkIIz8D2AENUrfq1OlN-AFFnCCU9SbEh4YSQ"
local deviceID = "TB01"
local apiURL = "https://ibestcloud.com/api/v1/tool/action/get?action_type=Tiktok&jwt=" .. jwt .. "&device_id=" .. deviceID
local imgPath = rootDir() .. "/img/"

----------------------------------------------------------------
-- ⚙️ TIỆN ÍCH CHUNG
----------------------------------------------------------------
local function tap(x, y, delay)
    if not x or not y then return end
    touchDown(1, x, y)
    usleep(80000)
    touchUp(1, x, y)
    usleep(delay or 500000)
end

local function openDeep(url)
    if type(openURL) == "function" then return openURL(url) end
    if type(appOpenURL) == "function" then return appOpenURL(url) end
    require "objc"
    local NSURL, UIApplication = objc.NSURL, objc.UIApplication
    return UIApplication:sharedApplication():openURL_(NSURL:URLWithString_(url))
end

----------------------------------------------------------------
-- 🌐 GỌI API
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
        toast("❌ API lỗi: " .. tostring(err))
        return nil
    end
    return response
end

----------------------------------------------------------------
-- 🧩 TRÍCH DỮ LIỆU TRẢ VỀ
----------------------------------------------------------------
local function extractOptions(resp)
    local actions, linkAcc, linkPost, commentList = {}, {}, {}, {}

    for a in resp:gmatch('"actions"%s*:%s*%[(.-)%]') do
        for v in a:gmatch('"(.-)"') do table.insert(actions, v) end
    end
    for b in resp:gmatch('"linkAcc"%s*:%s*%[(.-)%]') do
        for v in b:gmatch('"(.-)"') do table.insert(linkAcc, v) end
    end
    for c in resp:gmatch('"linkPost"%s*:%s*%[(.-)%]') do
        for v in c:gmatch('"(.-)"') do table.insert(linkPost, v) end
    end
    for d in resp:gmatch('"commentContent"%s*:%s*%[(.-)%]') do
        for v in d:gmatch('"(.-)"') do table.insert(commentList, v) end
    end

    local delay = tonumber(resp:match('"delaySec"%s*:%s*(%d+)')) or 5
    return {
        actions = actions,
        linkAcc = linkAcc,
        linkPost = linkPost,
        commentList = commentList,
        delay = delay * 1000000
    }
end

local function hasAction(opt, act)
    for _, a in ipairs(opt.actions or {}) do
        if a == act then return true end
    end
    return false
end

local function randomComment(opt)
    local list = opt.commentList or {}
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

----------------------------------------------------------------
-- 🔘 AUTOFOLLOW (GIỮ NGUYÊN)
----------------------------------------------------------------
local function findImg(name, thr)
    local r = findImage(imgPath .. name, 1, thr or 0.6, nil, false, 2)
    return r and #r > 0 and {r[1][1], r[1][2]} or nil
end

local function followIfNeeded()
    usleep(80000)
    local p = findImg("follow_button.png", 0.6)
    if p then
        tap(p[1], p[2])
        toast("✅ Đã nhấn Follow")
        usleep(3000000)
    else
        toast("⚠️ Không thấy nút Follow")
        usleep(2000000)
    end
end

local function followAccounts_OLD(opt)
    for i, acc in ipairs(opt.linkAcc or {}) do
        local username = acc:match("@([%w%._%-]+)")
        if username then
            local link = "snssdk1233://user/@" .. username
            toast("🔗 (" .. i .. ") @" .. username)
            openDeep(link)
            usleep(6000000)
            followIfNeeded()
            usleep(3000000)
        end
    end
end

----------------------------------------------------------------
-- 💬 AUTOPOST (ĐÚNG THỨ TỰ + COMMENT CUỐI)
----------------------------------------------------------------
local function interactPosts(opt)
    for _, post in ipairs(opt.linkPost or {}) do
        local awemeID = post:match("/video/(%d+)")
        local deep = awemeID and ("snssdk1233://aweme/detail/" .. awemeID) or post
        toast("🎬 Mở bài: " .. post)
        openDeep(deep)
        usleep(7000000)
        appActivate("com.ss.iphone.ugc.Ame")

        ----------------------------------------------------------------
        -- 🔹 Thứ tự thao tác y hệt log anh gửi
        ----------------------------------------------------------------
        touchDown(4, 688.71, 551.26);
        usleep(83259.46);
        touchUp(4, 688.71, 551.26);
        usleep(1534928.58);

        touchDown(3, 690.77, 949.35);
        usleep(83393.79);
        touchUp(3, 690.77, 949.35);
        usleep(1832034.67);

        touchDown(6, 108.79, 1006.36);
        usleep(101348.17);
        touchUp(6, 108.79, 1006.36);
        usleep(4482539.00);

        touchDown(1, 684.61, 684.63);
        usleep(67895.96);
        touchUp(1, 684.61, 684.63);
        usleep(1848500.00);

        touchDown(2, 355.13, 1275.15);
        usleep(101478.38);
        touchUp(2, 355.13, 1275.15);

        ----------------------------------------------------------------
        -- 💬 Sau cùng: nhập comment và nhấn gửi
        ----------------------------------------------------------------
        local cmt = randomComment(opt)
        if cmt then
            usleep(1000000)
            inputText(cmt)
            usleep(1000000)
            touchDown(2, 671.26, 779.32)
            usleep(65136.83)
            touchUp(2, 671.26, 779.32)
            toast("💬 Comment: " .. cmt)
        else
            toast("⚠️ Không có comment trong danh sách")
        end

        usleep(opt.delay or 5000000)
    end
end

----------------------------------------------------------------
-- 🔁 MAIN LOOP
----------------------------------------------------------------
toast("🚀 TikTok AutoLoop – Bắt đầu hoạt động...")
math.randomseed(os.time())

while true do
    toast("📡 Gọi API lấy tác vụ...")
    local resp = getAPIResponse()
    if resp then
        local opt = extractOptions(resp)
        if opt and #opt.actions > 0 then
            if hasAction(opt, "follow") then followAccounts_OLD(opt) end
            if hasAction(opt, "like") or hasAction(opt, "share") or hasAction(opt, "comment") then
                interactPosts(opt)
            end
        else
            toast("⏳ Không có tác vụ – nghỉ 5s")
            usleep(5000000)
        end
    else
        toast("⚠️ API lỗi – nghỉ 10s rồi thử lại")
        usleep(10000000)
    end
    usleep(8000000)
end

toast("🎉 Dừng vòng lặp – By Mr.L")
