-- {"id":260127,"ver":"1.0.91","libVer":"1.0.0","author":"GPPA"}
--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 260127

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Yuki Kitsuneko"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://yukikitsuneko.blogspot.com/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL =
    "https://blogger.googleusercontent.com/img/a/AVvXsEjmtcoZ_MDWp2CpXJZSAaSXOqqL-E54sJ4nw9AxmSv3yprfwVvxipfp41x8g2Q96eCorBx8S4vQZOZdggz_HE7k2G8MlfBFlYnRtNioP_CI7o2TbSfKIa9IVxY2xMDo1MVlUJixzeBWr__ZWgNQsoDc6Qmp0kLeTYlmZ4iHHT0yazeJL4aOsDNkUxQUMm7P=s640"

--- Shosetsu tries to handle cloudflare protection if this is set to true.
---
--- Optional, Default is false.
---
--- @type boolean
local hasCloudFlare = false

--- If the website has search.
---
--- Optional, Default is true.
---
--- @type boolean
local hasSearch = true

--- If the websites search increments or not.
---
--- Optional, Default is true.
---
--- @type boolean
local isSearchIncrementing = true

--- ChapterType provided by the extension.
---
--- Optional, Default is STRING. But please do HTML.
---
--- @type ChapterType
local chapterType = ChapterType.HTML

--- Index that pages start with. For example, the first page of search is index 1.
---
--- Optional, Default is 1.
---
--- @type number
local startIndex = 1

local json = Require("dkjson")
local unhtml = Require("unhtml")

local SELECT_STATUS_ID = 2
local SELECT_STATUS_TEXT = {"All Status", "Ongoing", "Completed", "One Shot"}

local SELECT_GENRE_ID = 3
local SELECT_GENRE_TEXT = {"All Types", "Action", "Adult", "Adventure", "Age Gap", "BSS", "Baseball", "Battle/Action",
                           "Beautiful Girls", "Bereavement", "Bickering Couple", "CHF", "Childhood Friend",
                           "Childhood Friends", "Cohabitation", "College Students", "Comedy", "Coming of Age",
                           "Diabetic", "Doting Love", "Doting Love Interest", "Drama", "Ecchi", "Erotica", "Fantasy",
                           "First Love", "Flirty", "Friendship", "Gal", "Harem", "High School Students", "Isekai",
                           "Kuudere", "Lovey-Dovey Romance", "Magic", "Mecha", "Monsters", "Music", "Mystery",
                           "Netorare", "Netori", "Office Life", "Office Love", "Otome", "Problem Solving",
                           "Psychological", "Pure Diabetes", "Pure Love", "R18", "Reincarnation", "RomCom", "Romance",
                           "School Life", "School Love", "Scientists", "Seinen", "Serves You Right", "Sexual Violence",
                           "Shoujo", "Shounen", "Slice of Life", "Strongest MC", "Supernatural", "Territory Building",
                           "Time Leap", "Time Travel", "Tokusatsu", "Tragedy", "Tragic Love", "Tsundere",
                           "University Student", "Villainess", "Work", "Working Adults", "Yandere"}

--- Filters to display via the filter fab in Shosetsu.
---
--- Optional, Default is none.
---
--- @type Filter[] | Array
local searchFilters = {DropdownFilter(SELECT_STATUS_ID, "Status", SELECT_STATUS_TEXT),
                       DropdownFilter(SELECT_GENRE_ID, "Genre", SELECT_GENRE_TEXT)}

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @return string Shrunk URL.
local function shrinkURL(url)
    return url:gsub("https://yukikitsuneko.blogspot.com/", "")
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @return string Full URL.
local function expandURL(url)
    return baseURL .. url
end

local function extractNovelDataFromScript(script)
    local scriptText = script:html() or ""
    if scriptText ~= "" and scriptText:find("novelData") then
        -- Match: const novelData = [...]
        local jsonStr = scriptText:match("const%s+novelData%s*=%s*(%b[])")

        if jsonStr then
            -- Try to decode JSON
            local success, data = pcall(function()
                return json.decode(jsonStr)
            end)

            if success and data then
                return data
            end
        end
    end

    return nil
end

local function genreInList(list, genre)
    for _, v in ipairs(list) do
        if v == genre then
            return true
        end
    end
    return false
end

local function parseListing(data, search)
    local url = "https://yukikitsuneko.blogspot.com/p/series-list.html"

    local doc = GETDocument(url)

    doc = doc:selectFirst("div.post div.post-body script")

    local js = extractNovelDataFromScript(doc)

    local novels = {}

    for _, v in ipairs(js) do
        local tit = (v.title) or ""
        local href = expandURL(v.link or "")

        local novel = Novel()
        novel:setLink(shrinkURL(href))
        novel:setTitle(unhtml.convertHTMLentities(tit))
        novel:setImageURL(v.imageUrl or "")

        local addOrNot = true

        if data[SELECT_GENRE_ID] and data[SELECT_GENRE_ID] ~= 0 and v.genre then
            if not genreInList(v.genre, SELECT_GENRE_TEXT[data[SELECT_GENRE_ID] + 1]) then
                addOrNot = false
            end
        end

        if data[SELECT_STATUS_ID] and data[SELECT_STATUS_ID] ~= 0 and v.status then
            if SELECT_STATUS_TEXT[data[SELECT_STATUS_ID] + 1] ~= v.status then
                addOrNot = false
            end
        end

        if search and v.title and v.title:lower():find(search, 1, true) == nil then
            addOrNot = false
        end

        if addOrNot then
            table.insert(novels, novel)
        end
    end

    return novels
end

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {Listing("Something without any input", false, function(data)
    -- Previous documentation, except no data or appending.
    return parseListing(data)

end)}

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local htmlElement = GETDocument(expandURL(chapterURL))

    local content = htmlElement:selectFirst("div.post-body.entry-content.float-container")
    local title = htmlElement:selectFirst("div.post-header div.post-title h2"):text()

    -- htmlElement = htmlElement:selectFirst("div.content.e-content")
    -- Chapter title inserted before chapter text
    content:prepend("<h5>" .. title .. "</h5>");

    content:select("a"):remove()

    return pageOfElem(content, true, "")
end

local encode = Require("url").encode

local function split(str, delimiter)
    local parts = {}
    str = str .. delimiter -- add delimiter at end to simplify logic
    for part in str:gmatch("(.-)" .. delimiter:gsub("%W", "%%%0")) do
        if part ~= "" then
            table.insert(parts, part)
        end
    end
    return parts
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
---@param loadChapters boolean
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))

    local content = doc:selectFirst("div.post-body.entry-content.float-container")

    local h = content and content:selectFirst("h1")

    local description = table.concat(map(content:select("div.row.mt-3"), function(v)
        return v:text()
    end), "\n")

    local info = NovelInfo {
        title = h and h:text() or "",
        description = description or "",
        imageURL = content:selectFirst("img"):attr("src") or ""
    }

    -- Chapters
    if loadChapters and content then

        local start = 1
        local chapters = {}

        local chapterList = content:select("a")
        local chapterOrder = 1

        chapters = AsList(mapNotNil(chapterList, function(v)
            local a = v:selectFirst("a")

            local href = a:attr("href") or ""
            if href == "#" or href == "" then
                return nil
            end

            return NovelChapter {
                title = a:text() or href,
                link = shrinkURL(href),
                order = chapterOrder
            }
        end))

        -- local title = doc:selectFirst("div.post-title h2"):text()
        local title = doc:selectFirst("title"):text()
        title = split(title, " ~ ")[1]
        title = encode(title)

        -- info:setTitle(#chapters)

        if #chapters == 0 then
            repeat
                local formatURL = "https://yukikitsuneko.blogspot.com/feeds/posts/default/-/" .. title ..
                                      "?alt=json-in-script&max-results=100&start-index=" .. start
                local document = GETDocument(formatURL)

                -- for JSONP - ?alt=json-in-script
                document = document:selectFirst("body"):text():gsub("gdata.io.handleScriptLoaded%(", "")
                document = document:sub(1, -3) -- remove trailing )

                local jsonData = json.decode(document)

                if jsonData.feed.entry then
                    for _, v in ipairs(jsonData.feed.entry) do
                        table.insert(chapters, NovelChapter {
                            title = v.title["$t"] or "",
                            link = shrinkURL(v.link[5].href) or "",
                            release = v.published["$t"] or "",
                            order = 1
                        })
                    end
                end

                start = #chapters + 1
                -- info:setTitle("After " .. jsonData.feed["openSearch$totalResults"]["$t"] .. " got " .. #chapters ..
                --                   " chapters.")
            until #chapters == 0 or tonumber(jsonData.feed["openSearch$totalResults"]["$t"]) <= #chapters
        end

        info:setChapters(chapters)
    end

    return info
end

--- Called to search for novels off a website.
---
--- Optional, But required if [hasSearch] is true.
---
--- @param data table @of applied filter values [QUERY] is the search query, may be empty.
--- @return Novel[] | Array
local function search(data)
    --- @type string
    local query = data[QUERY]:lower()

    if query and query:match("^https?://") then
        local doc = GETDocument(query)

        local content = doc:selectFirst("div.post-body.entry-content.float-container")

        local h = content and content:selectFirst("h1")

        local info = {Novel {
            title = h and h:text() or "",
            imageURL = content:selectFirst("img"):attr("src") or "",
            link = shrinkURL(query)
        }}

        return info
    end

    return parseListing(data, query)

end

--- Called when a user changes a setting and when the extension is being initialized.
---
--- Optional, But required if [settingsModel] is not empty.
---
--- @param id int Setting key as stated in [settingsModel].
--- @param value any Value pertaining to the type of setting. Int/Boolean/String.
--- @return void
local function updateSetting(id, value)
    settings[id] = value
end

-- Return all properties in a lua table.
return {
    -- Required
    id = id,
    name = name,
    baseURL = baseURL,
    listings = listings, -- Must have at least one listing
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional values to change
    imageURL = imageURL,
    hasCloudFlare = hasCloudFlare,
    hasSearch = hasSearch,
    isSearchIncrementing = isSearchIncrementing,
    searchFilters = searchFilters,
    settings = {},
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required if [hasSearch] is true.
    search = search,

    -- Required if [settings] is not empty
    updateSetting = updateSetting
}
