-- {"id":260127,"ver":"1.0.7","libVer":"1.0.0","author":"GPPA"}
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
local isSearchIncrementing = false

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

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @return string Shrunk URL.
local function shrinkURL(url)
    return url:gsub("https://yukikitsuneko.blogspot.com/", "")
end

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {Listing("Something without any input", false, function()
    -- Previous documentation, except no data or appending.
    local url = baseURL

    local doc = GETDocument(url)

    return mapNotNil(doc:select("div#LinkList1 div.widget-content ul li"), function(v)
        local a = v:selectFirst("a")
        if not a then
            return nil
        end

        local href = a:attr("href") or ""
        if href == "#" or href == "" then
            return nil
        end

        if href == "https://" or href == "#bt-home" or href == "https://yukikitsuneko.blogspot.com/p/dmca.html" then
            return nil
        end

        local tit = a:text() or a:attr("title") or ""
        -- trim whitespace
        tit = tit:gsub("^%s*%-*%s*(.-)%s*$", "%1")
        if tit == "" then
            tit = href
        end

        local novel = Novel()
        novel:setLink(shrinkURL(href))

        novel:setTitle(tit)
        return novel
    end)
end)}

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @return string Full URL.
local function expandURL(url)
    return baseURL .. url
end

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

        -- select all paragraph elements and guard nil anchors
        -- div.col-12.col-md-6.mt-3.mt-md-0 h6
        local chapterList = content:select("a")
        local chapterOrder = 1

        local novelList = AsList(mapNotNil(chapterList, function(v)
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

        -- Only works for previous versions that do not have chapters loaded via script
        -- script uses something like this to load the chapters
        -- "https://yukikitsuneko.blogspot.com/feeds/posts/default/-/Fixing%20a%20Gals%20Bike?alt=json-in-script&max-results=500&callback=processTocFeed"

        info:setChapters(novelList)
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
    --- Not required if search is not incrementing.
    --- @type int
    local page = data[PAGE]

    --- Get the user text query to pass through.
    --- @type string
    local query = data[QUERY]

    return {}
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
    settings = settingsModel,
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required if [hasSearch] is true.
    search = search,

    -- Required if [settings] is not empty
    updateSetting = updateSetting
}
