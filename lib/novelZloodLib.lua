-- {"ver":"2.9.2","author":"TechnoJo4","dep":["url"]}

local encode = Require("url").encode
local text = function(v)
	return v:text()
end

local settings = {}

local defaults = {
	latestNovelSel = "ul.project-list",
	searchNovelSel = "div.c-tabs-item__content",
	novelListingURLPath = "novel",
	-- Certain sites like TeamXNovel do not use [novelListingURLPath] and instead use a suffix to the query to declare what is expected.
	novelListingURLSuffix = "",
	novelPageTitleSel = "li.project-item",
	shrinkURLNovel = "",
	searchHasOper = false, -- is AND/OR operation selector present?
	hasCloudFlare = false,
	hasSearch = false,
	chapterType = ChapterType.HTML,
	chaptersOrderReversed = false,
	-- If chaptersScriptLoaded is true, then a ajax request has to be made to get the chapter list.
	-- Otherwise the chapter list is already loaded when loading the novel overview.
	chaptersScriptLoaded = false,
	chaptersListSelector= "li.wp-manga-chapter",
	-- If ajaxUsesFormData is true, then a POST request will be send to baseURL/ajaxFormDataUrl.
	-- Otherwise to baseURL/shrinkURLNovel/novelurl/ajaxSeriesUrl .
	ajaxUsesFormData = false,
	ajaxFormDataSel= "a.wp-manga-action-button",
	ajaxFormDataAttr = "data-post",
	ajaxFormDataUrl = "/wp-admin/admin-ajax.php",
	ajaxSeriesUrl = "ajax/chapters/",
	isSearchIncrementing = false,

	--- Some sites require custom CSS to exist, such as RTL support
	customStyle = "",
}

local ORDER_BY_FILTER_EXT = { "Relevance", "Latest", "A-Z", "Rating", "Trending", "Most Views", "New" }
local ORDER_BY_FILTER_KEY = 2
local AUTHOR_FILTER_KEY = 3
local ARTIST_FILTER_KEY = 4
local RELEASE_FILTER_KEY = 5
local STATUS_FILTER_KEY_COMPLETED = 6
local STATUS_FILTER_KEY_ONGOING = 7
local STATUS_FILTER_KEY_CANCELED = 8
local STATUS_FILTER_KEY_ON_HOLD = 9

function defaults:latest(data)
	return self.parse(GETDocument(self.baseURL))
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


---@param document Document The page containing novel information
---@return string the novel description
function defaults:parseNovelDescription(document)
	local summaryContent = document:selectFirst("div.summary__content")
	if summaryContent then
		return table.concat(map(document:selectFirst("div.summary__content"):select("p"), text), "\n")
	end
	local mangaExcerpt = document:selectFirst("div.manga-excerpt")
	if mangaExcerpt then
		return mangaExcerpt:text()
	end
	return ""
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))
	local content = doc:selectFirst("div.content")

	-- Temporarily saves a Jsoup selection for repeated use. Initial value used for status.
	-- local selectedContent = doc:selectFirst("div.post-status"):select("div.post-content_item")

	-- -- For some that doesn't have thumbnail
	-- local imgUrl = doc:selectFirst("div.summary_image")
	-- if imgUrl then
	-- 	imgUrl = img_src(imgUrl:selectFirst("img.img-responsive"))
	-- end

	local info = NovelInfo {
		title = titleElement:text()
	}

	-- Chapters
	-- Overrides `doc` if self.chaptersScriptLoaded is true.
	if loadChapters then

		local chapterList = content:selectFirst("p")
		local chapterOrder = -1
		if self.chaptersOrderReversed then
			chapterOrder = chapterList:size()
		end
		local novelList = AsList(mapNotNil(chapterList, function(v)
			if self.chaptersOrderReversed then
				chapterOrder = chapterOrder - 1
			else
				chapterOrder = chapterOrder + 1
			end
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

---@param doc Document
---@param search boolean
function defaults:parse(doc, search)
	return map(doc:select(search and self.searchNovelSel or self.latestNovelSel), function(v)
		local novel = Novel()
		local data = v:selectFirst("a")
		novel:setLink(self.shrinkURL(data:attr("href")))
		local tit = data:text()
		if tit == "" then
			tit = data:text()
		end
		novel:setTitle(tit)
		local e = data:selectFirst("img")
		if e then
			novel:setImageURL(img_src(e))
		end
		return novel
	end)
end

function defaults:expandURL(url)
	return self.baseURL .. "/" .. self.shrinkURLNovel .. "/" .. url
end

function defaults:shrinkURL(url)
	return url:gsub("https?://.-/" .. self.shrinkURLNovel .. "/", "")
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
