-- {"id":20260205,"ver":"0.0.33","libVer":"1.0.0","author":"GPPA"}
--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 20260205

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Test"

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
local imageURL = "https://d8iqbmvu05s9c.cloudfront.net/aiqpo1f3jbzpd0silc6b0qqot9ao"

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
local hasSearch = false

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
local chapterType = ChapterType.STRING

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
    local url = "https://yukikitsuneko.blogspot.com/"

    local novels = {}

    local novel = Novel {
        title = "Test Novel Title",
        link = "test"
    }
    table.insert(novels, novel)

    return novels
end)}

local json = Require("dkjson")

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
--- @param loadChapters boolean
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)

    local novel = NovelInfo {
        title = "Test Novel Inside Title",
        imageURL = "",
        description = "Description"
    }

    if loadChapters then
        local document = GETDocument(
            "https://yukikitsuneko.blogspot.com/feeds/posts/default/-/Like%20Snow%20Piling%20Up?alt=json-in-script&max-results=100&start-index=1")

		-- for JSONP
        document = document:selectFirst("body"):text():gsub("gdata.io.handleScriptLoaded%(", "")
        document = document:sub(1, -3) -- remove trailing )

        local jsonData = json.decode(document)
        local chapters = {}

        for _, v in ipairs(jsonData.feed.entry) do
            table.insert(chapters, NovelChapter {
                title = v.title["$t"] or "",
                link = shrinkURL(v.link[5].href) or "",
                release = v.updated["$t"] or "",
                order = 1
            })
        end

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
