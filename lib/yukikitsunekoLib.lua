-- {"ver":"0.0.96","author":"GPPA"}
local settings = {}

local defaults = {
    latestNovelSel = "ul.project-list",

    novelPageTitleSel = "li.project-item",

    hasSearch = false,

    --- Some sites require custom CSS to exist, such as RTL support
    customStyle = ""
}

function defaults:latest(data)
    return self.parse(GETDocument(self.baseURL))
end

---@param document Document The page containing novel information
---@return string the novel description
function defaults:parseNovelDescription(document)
    -- collect paragraph texts, trim, skip empty, join with newlines
    return table.concat(mapNotNil(document:select("p") or {}, function(p)
        local t = (p and p:text() or ""):gsub("^%s*(.-)%s*$", "%1")
        return t ~= "" and t or nil
    end), "\n")
end

---@param url string
---@return string
function defaults:getPassage(url)
    local htmlElement = GETDocument(url)

    local content = htmlElement:selectFirst("div.post-body.entry-content.float-container")
    local title = htmlElement:selectFirst("div.post-header div.post-title h2"):text()

    -- htmlElement = htmlElement:selectFirst("div.content.e-content")
    -- Chapter title inserted before chapter text
    content:prepend("<h5>" .. title .. "</h5>");

    content:select("a"):remove()

    return pageOfElem(content, true, self.customStyle)
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
    local doc = GETDocument(url)

    local content = doc:selectFirst("div.post-body.entry-content.float-container")

    local h = content and content:selectFirst("h1")
    local info = NovelInfo {
        title = h and h:text() or "",
        description = self.parseNovelDescription(content:select("div.row.mt-3")) or "",
        imageURL = content:selectFirst("img"):attr("src") or ""
    }

    -- Chapters
    -- Overrides `doc` if self.chaptersScriptLoaded is true.
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
                link = href,
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

function defaults:search(data)
    return nil
end

function defaults:expandURL(url)
    return self.baseURL .. "/" .. url
end

function defaults:shrinkURL(url)
    return url
end

---@param doc Document
function defaults:parse(doc)
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

        href = self.shrinkURL(href)

        local tit = a:text() or a:attr("title") or ""
        -- trim whitespace
        tit = tit:gsub("^%s*%-*%s*(.-)%s*$", "%1")
        if tit == "" then
            tit = href
        end

        local novel = Novel()
        novel:setLink(href)

        novel:setTitle(tit)
        return novel
    end)
end

return function(baseURL, _self)
    _self = setmetatable(_self or {}, {
        __index = function(_, k)
            local d = defaults[k]
            return (type(d) == "function" and wrap(_self, d) or d)
        end
    })

    _self.genres_map = {}
    local keyID = 100

    _self["baseURL"] = baseURL
    _self["listings"] = {Listing("Default", false, _self.latest)}
    _self["updateSetting"] = function(id, value)
        settings[id] = value
    end

    return _self
end
