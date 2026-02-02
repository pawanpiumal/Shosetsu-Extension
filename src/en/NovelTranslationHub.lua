-- {"id":20260203,"ver":"0.0.04","libVer":"1.0.0","author":"GPPA"}
--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---

return Require("Madara")("https://noveltranslationhub.com", {
	id = 20260203,
	name = "Novel Translation Hub",
	imageURL = "https://noveltranslationhub.com/wp-content/uploads/2023/12/picturetopeople.org-258e30f39152c491dd0d01e70cd16b1a800a801ddb45f78836.png",
	hasCloudFlare = false,
	genres = {
	},

	latestNovelSel = "div.page-listing-item"
})
