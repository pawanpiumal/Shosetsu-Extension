-- {"id":260126,"ver":"1.0.0","libVer":"1.0.0","author":"GPPA","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://novel-zlood.github.io", {
	id = 260126,
	name = "Novel Zlood",
	imageURL = "https://novel-zlood.github.io/images/logo.png",

	-- defaults values
	novelPageTitleSel = "li.project-item",
	hasSearch = false,


	genres = {
		"Action"
	}
})
