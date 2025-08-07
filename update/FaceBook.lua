----------------------------------------------------------------
-- Facebook Auto Like + Follow + Comment + API Integration
----------------------------------------------------------------
local curl = require("cURL")
local json = require("json")  -- Đảm bảo có thư viện JSON
local jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJ2dWFnYTJrMSIsImxldmVsIjo5OSwiZnVsbF9uYW1lIjoiTmd1eWVuRHV5TGFtIiwidXNlcl9pZCI6OTAsImxhc3RfdGltZV9wdyI6MCwiaWF0IjoxNzU0MzY2NTQyfQ.zcwUWQHPTiq7Shf9lpLuwt0eaIHNTXOFzWijhLMF-QU"       -- Thay bằng JWT thật
local deviceID = "227ce1968e1b431a"
local apiURL = "https://ibestcloud.com/api/v1/tool/action/get?action_type=Facebook&jwt=" .. jwt .. "&device_id=" .. deviceID
local imgPath = rootDir() .. "/img/"

----------------------------------------------------------------
-- 📡 Mở URL trong App
----------------------------------------------------------------
local function openURLinApp(url)
    toast("🔗 Đang mở: " .. url)
    openURL(url)
    usleep(10000000)
end

----------------------------------------------------------------
-- 🖼️ Tìm & nhấn ảnh
----------------------------------------------------------------
local function findAndTap(imageName, threshold)
    local r = findImage(imgPath .. imageName, 1, threshold or 0.7, nil, false, 2)
    if r and #r > 0 then
        local x, y = r[1][1], r[1][2]
        touchDown(1, x, y); usleep(80000)
        touchUp(1, x, y); usleep(1500000)
        return true
    end
    return false
end

----------------------------------------------------------------
-- 🚀 Các tác vụ Facebook
----------------------------------------------------------------
local function processFaceLike()
    return findAndTap("facelike.png", 0.5)
end

local function processFollowPage()
    if findAndTap("3cham.png", 0.3) then
        usleep(1500000)
        return findAndTap("followpage.png", 0.3)
    end
    return false
end

local function processFaceFollow()
    return findAndTap("facefollow.png", 0.3)
end

local function processAddFriend()
    return findAndTap("addfriend.png", 0.3)
end

local function likePost()
    return findAndTap("like.png", 0.3)
end

local function commentPost(content)
    if findAndTap("comment.png", 0.3) then
        usleep(2000000)
        inputText(content)
        usleep(1000000)
        return findAndTap("send.png", 0.3)
    end
    return false
end

----------------------------------------------------------------
-- 🌐 Gọi API bằng cURL
----------------------------------------------------------------
local function getAPIResponse()
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
-- 🔁 MAIN LOOP – gọi API liên tục mỗi 5 giây
----------------------------------------------------------------
while true do
    toast("📡 Gọi API Facebook...")
    local raw = getAPIResponse()
    if not raw then
        toast("⚠️ API lỗi – thử lại sau"); usleep(5000000)
    else
        local ok, data = pcall(function() return json.decode(raw) end)
        if not ok or not data or not data.data or not data.data.options then
            toast("⚠️ JSON lỗi hoặc thiếu dữ liệu"); usleep(5000000)
        else
            local options = data.data.options
            local profileUrls = options.profileUrls or {}
            local postUrls = options.postUrls or {}
            local commentContent = options.commentContent or {}

            -- 🔁 Xử lý profile URLs
            for _, url in ipairs(profileUrls) do
                openURLinApp(url)
                usleep(5000000)

                if processFaceLike() then toast("👍 Đã Like Page") end
                if processFollowPage() then toast("✅ Đã Follow Page") end
                if processFaceFollow() then toast("✅ Đã Follow Profile") end
                if processAddFriend() then toast("✅ Đã Add Friend") end

                toast("✅ Xong link profile/page này"); usleep(3000000)
            end

            -- 🔁 Xử lý post URLs
            for _, link in ipairs(postUrls) do
                openURLinApp(link)
                usleep(5000000)

                if likePost() then toast("👍 Đã Like Post") end
                usleep(3000000)

                if #commentContent > 0 then
                    local randomComment = commentContent[math.random(#commentContent)]
                    if commentPost(randomComment) then
                        toast("💬 Đã gửi Comment")
                    else
                        toast("⚠️ Không gửi được Comment")
                    end
                    usleep(4000000)
                end
            end

            toast("🎉 Đã hoàn thành tác vụ từ API")
        end
    end
    usleep(5000000)
end

toast("🎯 Kết thúc – Script by Mr.LL")
