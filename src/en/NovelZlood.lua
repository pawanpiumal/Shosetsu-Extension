-- {"id":260126,"ver":"1.2.21","libVer":"1.0.0","author":"GPPA"}
--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 260126

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Novel Zlood"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://novel-zlood.github.io/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = "https://novel-zlood.github.io/images/logo.png"

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
    return url:gsub("https://novel-zlood%.github%.io/", "")
end

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {Listing("Something", false, function(data)
    -- Many sites use the baseURL + some path, you can perform the URL construction here.
    -- You can also extract query data from [data]. But do perform a null check, for safety.
    local url = baseURL

    local doc = GETDocument(url)

    return mapNotNil(doc:select("ul.project-list li"), function(v)
        local a = v:selectFirst("a")
        if not a then
            return nil
        end

        local href = a:attr("href") or ""
        if href == "#" or href == "" then
            return nil
        end
        href = shrinkURL(href)

        local tit = a:text() or a:attr("title") or ""
        -- trim whitespace
        tit = tit:gsub("^%s*(.-)%s*$", "%1")
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
    local htmlElement = GETDocument(expandURL(chapterURL)):selectFirst("article.post.h-entry")
    local title = htmlElement:selectFirst("h1.posttitle.p-name"):text()
    htmlElement = htmlElement:selectFirst("div.content.e-content")
    -- Chapter title inserted before chapter text
    htmlElement:prepend("<h1>" .. title .. "</h1>");

    htmlElement:select("a"):remove()

    return pageOfElem(htmlElement, false)
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @param loadChapters boolean
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))

    local content = doc:selectFirst("article.post div.content")

    local h = content and content:selectFirst("h1")
    local info = NovelInfo {
        title = h and h:text() or ""
    }

    -- Chapters
    -- Overrides `doc` if self.chaptersScriptLoaded is true.
    if loadChapters and content then

        -- select all paragraph elements and guard nil anchors
        local chapterList = content:selectFirst("p"):select("a") or {}
        local chapterOrder = 1

        local novelList = AsList(mapNotNil(chapterList, function(v)
            local a = v:selectFirst("a")

            local href = a:attr("href") or ""
            if href == "#" or href == "" then
                return nil
            end

            return NovelChapter {
                title = a:text() or href,
                link = href,
                order = chapterOrder
            }
        end))

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
    local page = data[PAGE]
    local query = data[QUERY]

    local doc = GETDocument(baseURL)

    return mapNotNil(doc:select("ul.project-list li"), function(v)
        local a = v:selectFirst("a")
        if not a then
            return nil
        end

        local href = a:attr("href") or ""
        if href == "#" or href == "" then
            return nil
        end
        href = shrinkURL(href)

        local title = a:text() or a:attr("title") or ""

        title = title:lower()
        query = query:lower()

        local novel = Novel()

        if title:find(query, 1, true) ~= nil then
            novel:setTitle(title)
            novel:setLink(href)

            return novel
        end
    end)
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
