mapName <- GetMapName();
if (mapName == "dm_desert" || mapName == "dm_deima" || mapName == "dm_residential" || mapName == "dm_testlab" || mapName == "dm_lavarena")
	IncludeScript("deathmatch_with_bots_or_main.nut");
