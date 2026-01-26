-- {"id":20260126,"ver":"1.0.0","libVer":"1.0.0","author":"GPPA","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://novel-zlood.github.io", {
	id = 20260126,
	name = "Zetro Translations",
	imageURL = "https://novel-zlood.github.io/images/logo.png",

	-- defaults values
	latestNovelSel = "div.page-listing-item",
	ajaxUsesFormData = true,


	genres = {
		"Action"
	}
})
