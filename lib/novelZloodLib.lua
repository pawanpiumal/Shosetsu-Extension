-- {"ver":"2.9.2","author":"TechnoJo4","dep":["url"]}

local settings = {}

local defaults = {
	latestNovelSel = "ul.project-list",

	novelPageTitleSel = "li.project-item",

	--- Some sites require custom CSS to exist, such as RTL support
	customStyle = ""
}

function defaults:latest(data)
	return GETDocument(self.baseURL)
end

---@param url string
---@return string
function defaults:getPassage(url)
	local htmlElement = GETDocument(self.expandURL(url)):selectFirst("div.post.h-entry")
	local title = htmlElement:selectFirst("h1.posttitle.p-name"):text()
	htmlElement = htmlElement:selectFirst("div.content.e-content")
	-- Chapter title inserted before chapter text
	htmlElement:prepend("<h1>" .. title .. "</h1>");

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:select("a"):remove()
	-- htmlElement:select("i.icon.j_open_para_comment.j_para_comment_count"):remove() -- BoxNovel, VipNovel numbers

	return pageOfElem(htmlElement, true, self.customStyle)
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))
	local content = doc:selectFirst("div.content")

	local info = NovelInfo {
		title = titleElement:text()
	}

	-- Chapters
	-- Overrides `doc` if self.chaptersScriptLoaded is true.
	if loadChapters then

		local chapterList = content:selectFirst("p")
		local chapterOrder = -1

		local novelList = AsList(mapNotNil(chapterList, function(v)

			local link = self.shrinkURL(v:selectFirst("a"):attr("href"))
			if link == "#" then return nil end
			return NovelChapter{
				title = v:selectFirst("a"):text(),
				link = link,
				order = chapterOrder
			}
		end))
		if self.chaptersOrderReversed then
			Reverse(novelList)
		end
		info:setChapters(novelList)
	end

	return info
end

function defaults:search(data)
	return GETDocument(url)
end


function defaults:expandURL(url)
	return url
end

function defaults:shrinkURL(url)
	return url
end

return function(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })

	_self.genres_map = {}
	local keyID = 100

	_self["baseURL"] = baseURL
	_self["listings"] = { Listing("Default", true, _self.latest) }
	_self["updateSetting"] = function(id, value)
		settings[id] = value
	end

	return _self
end
