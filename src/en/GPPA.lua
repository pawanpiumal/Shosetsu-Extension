-- {"id":199824,"ver":"1.0.1","libVer":"1.0.0","author":"GPPA","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://zetrotranslation.com", {
	id = 199824,
	name = "Zetro Translationsqwe",
	imageURL = "https://zetrotranslation.com/wp-content/uploads/2020/12/logo_red-e1607700845220.png",

	-- defaults values
	latestNovelSel = "div.page-listing-item",
	ajaxUsesFormData = true,

	-- There are paid chapters, we can ignore it
	chaptersListSelector= "li.wp-manga-chapter.free-chap",

	genres = {
		"Action",
		"Adventure",
		"Comedy",
		"Dark Elf",
		"Drama",
		"Fantasy",
		"Harem",
		"Isekai",
		"Mecha",
		"Mystery",
		"Original Works",
		"Rom-Com",
		"Romance",
		"School",
		"Shoujo",
		"Slice of Life"
	}
})
