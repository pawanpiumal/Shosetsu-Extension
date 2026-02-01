-- {"id":20260131,"ver":"0.0.131","libVer":"1.0.0","author":"GPPA"}
--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 20260131

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Pen and Paper Translations"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://penandpapertranslations.com/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = "https://i0.wp.com/penandpapertranslations.com/wp-content/uploads/2025/07/resized_pen_logo_512x512-1.png"

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

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @return string Shrunk URL.
local function shrinkURL(url)
    return url:gsub("https://penandpapertranslations%.com/", "")
end

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {Listing("Something (with incrementing pages!)", false, function(data)
    --- @type int
    -- local page = data[PAGE]
    -- local url = baseURL .. "page/" .. page

    local document = GETDocument(baseURL)

    local list = mapNotNil(document:select("ul.wp-block-navigation__container li.open-on-hover-click"), function(v)
        return v
    end)

    local novels = {}

    for i, v in ipairs(list) do
        if i ~= 1 then
            local list2 = v:select("ul li")
            mapNotNil(list2, function(v2)
                local a = v2:selectFirst("a")

                local url = a:attr("href")

                local novel = Novel()

                novel:setTitle(a:text() or "")
                novel:setLink(shrinkURL(url))

                -- local doc = GETDocument(url)

                -- doc = doc:selectFirst(
                --     "div.wp-block-columns-is-layout-flex div.wp-block-column-is-layout-flow div.wp-block-group-is-layout-constrained")

                -- local novel = Novel()
                -- local title = doc:selectFirst("h2"):text() or ""

                -- local link = url or ""
                -- local imgElement = doc:selectFirst("img")
                -- local img = imgElement and imgElement:attr("src") or ""

                -- novel:setTitle(title)
                -- novel:setLink(shrinkURL(link))
                -- novel:setImageURL(img)

                table.insert(novels, novel)
            end)
        end
    end
    return novels
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
    local url = expandURL(chapterURL)

    --- Chapter page, extract info from it.
    local document = GETDocument(url)

    local title = document:selectFirst("div.wp-block-column-is-layout-flow div.wp-block-group-is-layout-constrained h2")
        :text() or ""

    local doc = document:selectFirst("div.wp-block-post-content-is-layout-constrained")

    doc:prepend("<h2>" .. title .. "</h2>");

    doc:select("div"):remove() -- Remove unwanted divs if any.
    doc:select("a"):remove() -- Remove unwanted links if any.`

    return pageOfElem(doc, false)
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

    local doc = document:selectFirst("div.wp-block-columns-is-layout-flex div.wp-block-column-is-layout-flow")

    local title = doc:selectFirst("h2"):text() or ""

    local imgElement = doc:selectFirst("img")
    local img = imgElement and imgElement:attr("src") or ""

    local description = table.concat(map(doc:select("div.entry-content p"), function(v)
        return v:text()
    end), "\n")

    local novel = NovelInfo {
        title = title,
        imageURL = img,
        description = description,
        author = "",
        genres = {},
        status = NovelStatus(3) -- Unknown
    }

    if loadChapters then
        local chaps = doc:select("div.entry-content li")
        local chapters = mapNotNil(chaps, function(v)
            local a = v:selectFirst("a")
            return NovelChapter {
                title = a:text() or "",
                link = shrinkURL(a:attr("href") or ""),
                release = v:selectFirst("time") and v:selectFirst("time"):attr("datetime") or "",
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
    --- Get the user text query to pass through.
    --- @type string
    local query = data[QUERY]

    local document = GETDocument(baseURL)

    local list = mapNotNil(document:select("ul.wp-block-navigation__container li.open-on-hover-click"), function(v)
        return v
    end)

    local novels = {}

    for i, v in ipairs(list) do
        if i ~= 1 then
            local list2 = v:select("ul li")
            mapNotNil(list2, function(v2)
                local a = v2:selectFirst("a")

                local url = a:attr("href")

                local novel = Novel()

                local title = a:text() or ""
                title = title:lower()

                query = query:lower()

                if title:find(query, 1, true) ~= nil then
                    novel:setTitle(title)
                    novel:setLink(shrinkURL(url))

                    table.insert(novels, novel)
                end
            end)
        end
    end
    return novels
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
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required if [hasSearch] is true.
    search = search
}
