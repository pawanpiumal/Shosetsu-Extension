-- {"id":20260201,"ver":"0.0.17","libVer":"1.0.0","author":"GPPA"}
--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 20260201

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Vampira MTL"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://www.vampiramtl.com/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL =
    "https://i0.wp.com/www.vampiramtl.com/wp-content/uploads/2023/05/cropped-e28094pngtreee28094moon-flying-bat-swarm-halloween_5567857-2-1.png"

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
    return url:gsub("https://www.vampiramtl.com/", "")
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

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {Listing("Something without any input", false, function()
    -- Previous documentation, except no data or appending.
    local urls = {"https://www.vampiramtl.com/ongoing-caught-up-series/",
                  "https://www.vampiramtl.com/completed-series/", "https://www.vampiramtl.com/dropped-series/"}

    local novels = {}
    for _, url in ipairs(urls) do
        local document = GETDocument(url)
        local a = document:select("div.entry-content a")

        mapNotNil(a, function(v)
            local href = v:attr("href")
            local novel = Novel {
                title = v:text() or href,
                link = shrinkURL(href)
            }
            table.insert(novels, novel)
        end)
    end

    return novels
end)}

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local url = expandURL(chapterURL)

    --- Chapter page, extract info from it.
    local document = GETDocument(url)

    return pageOfElem(document:selectFirst("article"), true, "")
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @param loadChapters boolean
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
    local url = expandURL(novelURL)

    --- Novel page, extract info from it.
    local document = GETDocument(url)

    document = document:selectFirst("article")

    local description = table.concat(map(document:select("div.entry-content p"), function(v)
        return v:text()
    end), "\n")

    local novel = NovelInfo {
        title = document:selectFirst("h1"):text() or "",
        imageURL = document:selectFirst("figure img") and document:selectFirst("figure img"):attr("src") or "",
        description = description
    }

    if loadChapters then
        local chaps = document:select("div.entry-content ul li a")
        local chapters = mapNotNil(chaps, function(a)
            return NovelChapter {
                title = a:text() or "",
                link = shrinkURL(a:attr("href") or ""),
                release = "",
                order = -1
            }
        end)
        novel:setChapters(chapters)
    end

    return novel
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

    -- Previous documentation, except no data or appending.
    local urls = {"https://www.vampiramtl.com/ongoing-caught-up-series/",
                  "https://www.vampiramtl.com/completed-series/", "https://www.vampiramtl.com/dropped-series/"}

    local novels = {}
    for _, url in ipairs(urls) do
        local document = GETDocument(url)
        local a = document:select("div.entry-content a")

        mapNotNil(a, function(v)
            local href = v:attr("href")

            local title = v:text() or ""

            title = title:lower()

            query = query:lower()

            if title:find(query, 1, true) ~= nil then
                local novel = Novel {
                    title = title,
                    link = shrinkURL(href)
                }
                table.insert(novels, novel)
            end
        end)
    end

    return novels
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
