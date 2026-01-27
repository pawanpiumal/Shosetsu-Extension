-- {"ver":"1.0.46","author":"GPPA"}

local settings = {}

local defaults = {
	latestNovelSel = "ul.project-list",

	novelPageTitleSel = "li.project-item",

	--- Some sites require custom CSS to exist, such as RTL support
	customStyle = ""
}

function defaults:latest(data)
	return self.parse(GETDocument(self.baseURL))
end

---@param url string
---@return string
function defaults:getPassage(url)
	local htmlElement = GETDocument(self.expandURL(url)):selectFirst("article.post.h-entry")
	local title = htmlElement:selectFirst("h1.posttitle.p-name"):text()
	htmlElement = htmlElement:selectFirst("div.content.e-content")
	-- Chapter title inserted before chapter text
	-- htmlElement:prepend("<h1>" .. title .. "</h1>");

	htmlElement:select("a"):remove()

	return pageOfElem(htmlElement, true, self.customStyle)
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
    local doc = GETDocument(self.expandURL(url))

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
            if href == "#" or href == "" then return nil end

            return NovelChapter{
                title = a:text() or href,
                link = href,
                order = chapterOrder
            }
        end))

        info:setChapters(novelList)
    end

    return info
end

function defaults:search(data)
	return self.parse(GETDocument(self.baseURL))
end


function defaults:expandURL(url)
	return self.baseURL .. "/" .. url
end

function defaults:shrinkURL(url)
	return url
end

---@param doc Document
function defaults:parse(doc)
    return mapNotNil(doc:select("ul.project-list li"), function(v)
        local a = v:selectFirst("a")
        if not a then return nil end

        local href = a:attr("href") or ""
        if href == "#" or href == "" then return nil end
        href = self.shrinkURL(href)

        local tit = a:text() or a:attr("title") or ""
        -- trim whitespace
        tit = tit:gsub("^%s*(.-)%s*$", "%1")
        if tit == "" then tit = href end

        local novel = Novel()
        novel:setLink(href)

        novel:setTitle(tit)
        return novel
    end)
end

return function(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })

	_self.genres_map = {}
	local keyID = 100

	_self["baseURL"] = baseURL
	_self["listings"] = { Listing("Default", false, _self.latest) }
	_self["updateSetting"] = function(id, value)
		settings[id] = value
	end

	return _self
end
