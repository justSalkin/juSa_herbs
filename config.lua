Config = {}
Config.SearchKey = 0xD9D0E1C0 -- [SPACE] Key to press for prompt

Config.ChanceHerbs = 25 --Chance of getting a reward by searching herbs
Config.randomgiveHerb = math.random(1,2) --givs player 1-2 herbs when finding herbs

Config.HerbalBook = "herbalbook" --db name of your herbal book item (with item in inv player gets +1 herb)
Config.HerbalNote = "herbalnote" --db name of your herbal note item
Config.extraChance = 10 -- ChanceHerbs + extraChance = chance to find herbs

Config.Jobs = {"Nativ1", "Nativ2"}
Config.JobChance = 10 --+10% chance to find herbs when player has one of these jobs

Config.HerbItems = { --put items here u can get from herbs
	{item = "parasol_mushroom", name = "parasol"},
	{item = "wild_carrot", name = "carrot"},
	{item = "wild_mint", name = "mint"},
	{item = "toadstool", name = "toadstool"},
	-- double for higher chances
	{item = "wild_carrot", name = "carrot"},
	{item = "wild_mint", name = "mint"}
}

Config.Language = {
	prompt = "search",
	promptherb = "Find wild herbs",
	notifytitelherb = "Herbs",
	notfoundherb = "You found no herbs!",
    invfull = "You can't carry more items.",
	found = "You got: "
}