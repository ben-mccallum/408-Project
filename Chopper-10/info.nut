class Chopper extends AIInfo {
	function GetAuthor()      { return "marbs"; }
	function GetName()        { return "Chopper"; }
	function GetShortName()   { return "CHOP"; }
	function GetDescription() { return "Uses only helicopters, which provides competition for air travel. If you use AV8, Chopper will take full advantage of other cargos."; }
	function GetVersion()     { return 10; }
	function GetDate()        { return "2011-08-21"; }//8th September 2009, now 21st August 2011
	function CreateInstance() { return "Chopper"; }
	function GetSettings() {
		AddSetting({name = "min_town_size", description = "The minimal size of towns to work on.", min_value = 0, max_value = 1000, easy_value = 250, medium_value = 150, hard_value = 50, custom_value = 50, flags = 0});
		AddSetting({name = "attitude", description = "Chopper's attitude.", min_value = 0, max_value = 4, easy_value = 0, medium_value = 2, hard_value = 4, custom_value = 3, flags = 0});
		AddLabels("attitude", {_0="Sleepy", _1="Lazy", _2="Average", _3="Motivated", _4="Caffeine high"});
		AddSetting({name = "concern", description = "Chopper's main concern", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 1, custom_value = 1, flags = 0});
		AddLabels("concern", {_0="Aesthetics", _1="Economics"});
		AddSetting({name = "subsidy_chance", description = "Chopper's stance towards attempting subsidies.", min_value = 0, max_value = 4, easy_value = 0, medium_value = 3, hard_value = 4, custom_value = 4, flags = 0});
		AddLabels("subsidy_chance", {_0="What's the point", _1="What an effort", _2="Why not", _3="Probably a good idea", _4="I'd be a fool not to"});
		AddSetting({name = "min_station_dis", description = "Minimum tile distance between two towns on one route.", min_value = 1, max_value = 2048, easy_value = 24, medium_value = 24, hard_value = 24, custom_value = 24, flags = 0});
		AddSetting({name = "max_station_dis", description = "Maximum tile distance between two towns on one route.", min_value = 1, max_value = 2048, easy_value = 128, medium_value = 128, hard_value = 128, custom_value = 128, flags = 0});
		AddSetting({name = "min_industry_dis", description = "Minimum tile distance between two industries on one route.", min_value = 1, max_value = 2048, easy_value = 64, medium_value = 64, hard_value = 64, custom_value = 64, flags = 0});
		AddSetting({name = "max_industry_dis", description = "Maximum tile distance between two industries on one route.", min_value = 1, max_value = 2048, easy_value = 256, medium_value = 256, hard_value = 256, custom_value = 256, flags = 0});
		AddSetting({name = "stations_per_industry", description = "Maximum amount of loading stations Chopper is allowed per industry.", min_value = 1, max_value = 5, easy_value = 1, medium_value = 2, hard_value = 3, custom_value = 2, flags = 0});
		AddSetting({name = "use_plane_speed_factor" description = "Take plane speed factor into account (affects max tile distance).", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = AICONFIG_BOOLEAN});
		AddSetting({name = "can_build_at_player_towns" description = "Whether Chopper can build stations at towns the player has built at.", easy_value = 0, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN});
		AddSetting({name = "multiple_stations_per_town" description = "Whether to allow Chopper to build multiple stations per town.", easy_value = 0, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN});
		AddSetting({name = "allow_intercity_routes" description = "Whether Chopper can build intercity routes (requires multiple stations per town).", easy_value = 0, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN});
		AddSetting({name = "debug_signs" description = "Should Chopper show his debug signs.", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = AICONFIG_BOOLEAN});
		AddSetting({name = "debug_info" description = "Display more debugging information.", easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = AICONFIG_BOOLEAN});
	}
}

RegisterAI(Chopper());
