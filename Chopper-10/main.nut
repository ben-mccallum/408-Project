class Chopper extends AIController
	{
	/* Store whether loaded from a game, default false, set to true in load event*/
	loaded = false;
	
	/* For debugging, a sign is placed at the top of the map that will remove all other signs when deleted. This stores its ID */
	master_debug_sign = null;
	
	PRODUCE = 0;
	ACCEPT = 1;
	PRODUCE_AND_ACCEPT = 2;
	
	/* The max number of helicopters allowed at each type of airport  */
	/* This is also in the order that airports are generally preferred (small and large (city) airport should only be used if none else are available) */
	HELISTATION_LIMIT = 8;
	HELIDEPOT_LIMIT = 4;
	HELIPORT_LIMIT = 3;
	/* These two limits must be less than or equal to helistation limit, since they get replaced with a helistation */
	SMALL_LIMIT = 3;
	LARGE_LIMIT = 3;
	/* This limit does not include other competitor's aircraft */
	OILRIG_LIMIT = 6;
	
	/* When an aircraft's profit drops below these values, they are sold */
	PROFIT_THRESHOLD_THISYEAR = 2000;
	PROFIT_THRESHOLD_LASTYEAR = 4000;
	YEARS_TO_MAKE_DIFFERENCE = 2;
	/* Same as above, but these values are used insead in certain situations: start of game, few operating aircraft, low amounts of money */
	PROFIT_THRESHOLD_THISYEAR_EARLY = 400;
	PROFIT_THRESHOLD_LASTYEAR_EARLY = 0;
	YEARS_TO_MAKE_DIFFERENCE_EARLY = 4;
	
	/* Max number of stations */
	STATIONS_PER_INDUSTRY = null;
	
	/* The age after which to remove a station with no vehicles visiting it */
	STATION_REMOVE_AGE = 3;
	
	/* Used to cover up lack of function in 0.7.2 */
	check_oilrig_transported = true;
	
	/* When ordered by population, only the top percentage are considered for building airports at */
	town_population_percentage = 50;
	
	/* Once a station with a depot has been built, this is set to false. Other stations then don't require depots as they can be built from the first station. */
	first_station = true;
	
	/* try and do subsidies (disabled if version is too old due to lack of function) */
	attempt_subsidies = true;
	
	/* If the are using an old version of OTTD then there is no function to check the station age */
	improvise_station_age_check = false;
	station_age_list = null;
	
	/* Used for deleting unprofitable vehicles */
	vehicle_to_depot = {};
	
	/* Delay time between building routes, this is redfined later in the constructor */
	delay_build_airport_route = null;
	
	/* Cargo IDs, redefined later as well */
	passenger_cargo_id = -1;
	mail_cargo_id = -1;
	express_cargo_id = -1;
	armoured_cargo_id = -1;
	bulk_cargo_id = -1;
	piece_goods_cargo_id = -1;
	liquid_cargo_id = -1;
	refrigerated_cargo_id = -1;
	hazardous_cargo_id = -1;
	covered_cargo_id = -1;
	
	/* The distances stations shoudl be built from each other. Forces the max to be at least 25 tiles bigger, to give at least a small dougnnut region to build in */
	min_station_dis = null;
	max_station_dis = null;
	min_industry_dis = null;
	max_industry_dis = null;
	
	/* The indent amount used in the log */
	INDENT = "          ";
	
	/* Used to pass the subsidy towns */
	subsidy_town_1 = null;
	subsidy_town_2 = null;
	subsidy_town_tiletouse = null;//when this is set to a value, the build airport script will try and built it at this tile
	
	function Start();
	
	constructor()
		{

		
		station_age_list = AIList();
		
		/* Work out the delay time for routes based upon Chopper's attitude */
		if (GetSetting("attitude") == 4)
			{
			this.delay_build_airport_route = 10;
			}
		if (GetSetting("attitude") == 3)
			{
			this.delay_build_airport_route = 500;
			}
		if (GetSetting("attitude") == 2)
			{
			this.delay_build_airport_route = 1000;
			}
		if (GetSetting("attitude") == 1)
			{
			this.delay_build_airport_route = 2000;
			}
		if (GetSetting("attitude") == 0)
			{
			this.delay_build_airport_route = 4000;
			}
		
		this.STATIONS_PER_INDUSTRY = GetSetting("stations_per_industry");
		
		/* Make sure the max town distance is bigger than the min */
		this.min_station_dis = GetSetting("min_station_dis");
		this.max_station_dis = GetSetting("max_station_dis");
		if (this.max_station_dis < this.min_station_dis + 25)
			{
			this.max_station_dis = this.min_station_dis + 25;
			}
		
		/* Make sure the max industry distance is bigger than the min */
		this.min_industry_dis = GetSetting("min_industry_dis");
		this.max_industry_dis = GetSetting("max_industry_dis");
		if (this.max_industry_dis < this.min_industry_dis + 25)
			{
			this.max_industry_dis = this.min_industry_dis + 25;
			}
		
		/* Hardly any of the following cargo ids are used, I think just passenger, mail and bulk are used, but am leaving them all in anyway */
		local list = AICargoList();
		for (local i = list.Begin(); list.HasNext(); i = list.Next())
			{
			if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS))
				{
				this.passenger_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_MAIL))
				{
				this.mail_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_EXPRESS))
				{
				this.express_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_ARMOURED))
				{
				this.armoured_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_BULK))
				{
				this.bulk_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_PIECE_GOODS))
				{
				this.piece_goods_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_LIQUID))
				{
				this.liquid_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_REFRIGERATED))
				{
				this.refrigerated_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_HAZARDOUS))
				{
				this.hazardous_cargo_id = i;
				}
			if (AICargo.HasCargoClass(i, AICargo.CC_COVERED))
				{
				this.covered_cargo_id = i;
				}
			}
		}
	};

/**
 * Check if we have enough money (via loan and on bank).
 */
function Chopper::HasMoney(money)
	{	
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount()) > money) return true;
	return false;
	}

/**
* Check if a company has built at a town
* Works by checking if they have a station in the town
*/
function Chopper::CheckCompanyBuiltAtTown(company, town)
	{
	/* Create a list of tiles */
	local list = AITileList();
		
	/* Get the tile to check around */
	local tile = AITown.GetLocation(town);
		
	/* Define the grid size to check */
	local grid_size = 15;
		
	/* Add all the tiles within that area to the list */
	list.AddRectangle(tile - AIMap.GetTileIndex(grid_size, grid_size), tile + AIMap.GetTileIndex(grid_size, grid_size));
		
	/* Only keep the station tiles */
	list.Valuate(AITile.IsStationTile);
	list.KeepValue(1);
		
	/* Only keep the tiles that are near that town (some towns may be very close to others) */
	list.Valuate(AITile.GetClosestTown);
	list.KeepValue(town);
		
	/* If the list is empty, there are no stations in that town */
	if (list.Count() == 0)
		{
		return 0;
		}
		
	/* Loop through all the tiles that are stations and near to the town */
	for (local i = list.Begin(); list.HasNext(); i = list.Next())
		{
		if (AITile.GetOwner(i) == company)
			{
			/* Return 1 if we found a station owned by that company near the town */
			return 1;
			}
		}
		
	/* Return 0 if no station was found near that town owned by that company */
	return 0;
	}

/**
* Remove all items with the "identifier" as their value from the list and return it
*/
function Chopper::RemoveFromList(list, identifier)
	{
	/* Cheaty method of replacing the list with one item - first give everything value 1 */
	for (local item = list.Begin(); list.HasNext(); item = list.Next())
		{
		list.SetValue(item,1);
		}
	
	/* Then give the item we want to get rid of value 0 */
	list.SetValue(identifier,0);
	
	/*Then remove everything below value 1... */
	list.RemoveBelowValue(1);
	
	return list;
	}

/**
 * Get the amount of money requested, loan if needed.
 */
function Chopper::GetMoney(money)
	{
	//UseEarlyValues

	
	if (!this.HasMoney(money)) return;
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > money) return;
	local loan = money - AICompany.GetBankBalance(AICompany.COMPANY_SELF) + AICompany.GetLoanInterval() + AICompany.GetLoanAmount();
	loan = loan - loan % AICompany.GetLoanInterval();
	AILog.Info(this.INDENT + "Need a loan to get £" + money);

	if (this.UseEarlyValues())
		{
		if (loan > (AICompany.GetMaxLoanAmount() - 50000))
			{
			AILog.Info(this.INDENT + "We should not take out a loan right now");
			return;
			}
		}
	AICompany.SetLoanAmount(loan);
	AILog.Info(this.INDENT + "Setting loan to £" + loan);
	}

/**
* Checks if there exists an industry with a heliport, e.g. oilrig
*/
function Chopper::IndustryPassengerExists()
	{
	local check = this.FindSuitableIndustryWithHeliport(true);
	if (check.IsEmpty() == true)
		{
		return false;
		}
	else
		{
		return true;
		}
	}

/**
* Decides what route to build
* may it be towns, oilrigs or whatever
*/
function Chopper::BuildRoute()
	{
	AILog.Info(" > Build new route...");
	AILog.Info(" > Checking vehicle numbers...");
	local vehicle_list = AIVehicleList();
	local vehicle_num = vehicle_list.Count();
	local vehicle_max = AIGameSettings.GetValue("vehicle.max_aircraft")
	AILog.Info(this.INDENT + "Currently have " + vehicle_num + " aircraft");
	AILog.Info(this.INDENT + "Max aircraft allowed: " + vehicle_max);
	if (vehicle_max == vehicle_num)
		{
		AILog.Warning(this.INDENT + "I have reached the aircraft limit, please raise it");
		return -1;
		}
	
	/* Get some money to work with */
	AILog.Info(" > Get some money...");
	
	/* Get out less money at the beginning so as not to go bankrupt fast */
	if (this.UseEarlyValues())
		{
		this.GetMoney(60000);
		}
	else
		{
		this.GetMoney(100000);
		}
	
	local value_to_return = -1;
	local value_to_return2 = -1;
	local value_to_return3 = -1;
	
	/* Try an passenger route if you have £50,000 since they are cheap and earn a lot; and check if we can afford an aircraft (to stop building millions of empty stations with no aircraft, because GRFs use expensive aircraft and 50k won't cover it) */
	if (this.HasMoney(50000) && (EngineWeCanAffordExistsForCargo(AIVehicle.VT_AIR,AIAirport.PT_HELICOPTER,this.passenger_cargo_id)))
		{
		AILog.Info(" > Build a route transporting passengers from town to town...");
		local town_list = this.FindSuitableTown();
		town_list.Valuate(AITown.GetPopulation);
			
		value_to_return = this.BuildAirportRoute(town_list);
			
		/* If it is successful, then it has built its first station */
		if (value_to_return >= 0)
			{
			this.first_station = false;
			}
		}
	
	/* Try an industry passenger route if you have £200,000 as they do not produce as many passengers as a town to town route */
	if (this.HasMoney(200000) && (EngineWeCanAffordExistsForCargo(AIVehicle.VT_AIR,AIAirport.PT_HELICOPTER,this.passenger_cargo_id)))
		{
		AILog.Info(" > Build a route transporting passengers from town to an industry...");
		value_to_return2 = this.BuildIndustryPassengerRoute();
		}
	
	/* Only try a cargo route when you have £500,000 since they take a long time to pay themselves back. Also checks for a vehicle since without a GRF there will be no cargo vehicle */
	if (this.HasMoney(500000) && (EngineWeCanAffordExistsForCargo(AIVehicle.VT_AIR,AIAirport.PT_HELICOPTER,this.bulk_cargo_id)))
		{
		AILog.Info(" > Build a route transporting cargo...");
		value_to_return3 = this.BuildIndustryCargoRoute();
		}
	
	/* Returns true if one of the routes succeeded */
	if (value_to_return < 0 && value_to_return2 < 0 && value_to_return3 < 0)
		{
		return 0;
		}
	else
		{
		return 1;
		}
	}

/**
* Build a cargo route
*/
function Chopper::BuildIndustryCargoRoute()
	{
	Sleep(1);
	/* Create a list of all the industries on the map */
	local industry_list = AIIndustryList();
		
	/* Create a list that will be used to store the industry and cargo*/
	local industry_and_cargo_list = AIList();
		
	/* Create a list that will be used to store the industry, cargo and the score, based upon a nify equation */
	local industry_and_cargo_and_score_list = AIList();
	Sleep(1);
		
	/* Loop through them all */
	for (local industry = industry_list.Begin(); industry_list.HasNext(); industry = industry_list.Next())
		{
		/* Skip if the industry type is invalid */
		if (!(AIIndustry.IsValidIndustry(industry)))
			{
			AILog.Error("Invalid industry detected");
			continue;
			}
			
		/* Get the type of industry */
		local industry_type = AIIndustry.GetIndustryType(industry);
			
		/* Get a list of all the cargo types this industry type produces */
		local cargo_produced_list = AIIndustryType.GetProducedCargo(industry_type);
			
		/* Sometimes the cargo_produced_list is null for some reason, causing the for loop to error. Skip to the next item if it is null to avoid this */
		if (cargo_produced_list == null)
			{
			continue;
			}
			
		/* Loop through all the cargos this industry produces (probably one, but two if it is a farm, or some GRF) */
		for (local cargo_produced = cargo_produced_list.Begin(); cargo_produced_list.HasNext(); cargo_produced = cargo_produced_list.Next())
			{
			/* Check if we have a helicopter that can transport this cargo */
			if (this.EngineExistsForCargo(AIVehicle.VT_AIR,AIAirport.PT_HELICOPTER,cargo_produced))
				{
				/* Check that not all of the cargo is being tansported */
				if (this.GetLastMonthTransported_Percentage(industry,cargo_produced) < 80)
					{
					/* Work out the score */
					local score = this.CalculateIndustryScore(industry,cargo_produced);
						
					/* Add all this to the list (industry,cargo,score) - use bitwise operations to get it all in*/
					industry_and_cargo_and_score_list.AddItem(this.IntegerMerge(industry,cargo_produced),score);
						
					/* Show the list of industries and what they produce */
					AILog.Info(AIIndustry.GetName(industry) + " produces " + AIIndustry.GetLastMonthProduction(industry,cargo_produced) + " " + AICargo.GetCargoLabel(cargo_produced) + " per month, and scored " + score);
					}
				}
			}
		}
		
	/* Sort it all by the score */
	industry_and_cargo_and_score_list.Sort(AIList.SORT_BY_VALUE,false);
		
	/* Remove any with a score of 0 (means nothing accepts their cargo) */
	industry_and_cargo_and_score_list.RemoveValue(0);
		
	/* Only keep the top 10000 */
	industry_and_cargo_and_score_list.KeepTop(10000);
		
	/* Display the long list of all industries */
	if (GetSetting("debug_info"))
		{
		AILog.Info(" > Display industry list...");
		}
		
	/* Will store the ids of the airpots */
	local airport_1 = null;
	local airport_2 = null;
	local tile_1 = null;
	local tile_2 = null;
		
	/* Loop through the industry and cargo and score list */
	for (local i = industry_and_cargo_and_score_list.Begin(); industry_and_cargo_and_score_list.HasNext(); i = industry_and_cargo_and_score_list.Next())
		{
		/* Retrieve the industry and cargo from the bitwise storage */
		local industry = this.IntegerReturn1(i);
		local cargo = this.IntegerReturn2(i);
			
		/* We use helidepots for loading */
		local airport_type = AIAirport.AT_HELIDEPOT;
		
		/* If helidepot can't be used, try small airport */
		if (!(AIAirport.IsValidAirportType(airport_type)))
			{
			airport_type = AIAirport.AT_SMALL;
			
			/* If small airport can't be used, try large */
			if (!(AIAirport.IsValidAirportType(airport_type)))
				{
				airport_type = AIAirport.AT_LARGE;
				
				/* If large can't be used, then that makes no sense, since at least one of these three will be available */
				if (!(AIAirport.IsValidAirportType(airport_type)))
					{
					AILog.Error("Wut, neither helidepot, small airport nor large (city) airport are available!");
					return -1;
					}
				}
			}
			
		/* get the score as well */
		local score = industry_and_cargo_and_score_list.GetValue(i);
			
		/* Update log */
		if (GetSetting("debug_info"))
			{
			AILog.Warning(industry + ":" + cargo + " | " + 	this.INDENT + AIIndustry.GetName(industry) + " transporting " + AICargo.GetCargoLabel(cargo) + " scored " + score);
			}
			
		/* Check if there is a station there already */
		local existing_station_1 = this.FindExistingAirport_Industry(industry,airport_type,cargo,this.PRODUCE);
		local existing_station_2 = null;
			
		/* Find a suitable spot for the first station */
		if (existing_station_1 != null)
			{
			AILog.Info(this.INDENT + "We found a station already here!");
			tile_1 = existing_station_1;
			}
		else
			{
			/* Check the number of existing airports servicing this industry. if there are too many, then we will skip it as we won't want to flood an industry with stations */
			if (this.GetAmountOfOurAirportsAtIndustry(industry,airport_type,cargo,this.PRODUCE) >= this.STATIONS_PER_INDUSTRY)
				{
				continue;
				}
			else
				{
				tile_1 = this.FindSuitableAirportSpot_Industry(industry,airport_type,cargo,this.PRODUCE);
				}
			}
			
		/* If it failed to find a space, try the next industry */
		if (tile_1 <= 0)
			{
			continue;
			}
		else
			{
			/* Otherwise, actually build the station */
			if (existing_station_1 == null)
				{
				airport_1 = AIAirport.BuildAirport(tile_1,airport_type,AIStation.STATION_NEW);
				}
			if (!airport_1 && existing_station_1 == null)
				{
				AILog.Error("Although reports said the space was clear, we could not build the first station");
				continue;
				}
			else
				{
				airport_type = AIAirport.AT_HELISTATION;
				
				/* If helistation can't be used, try small airport */
				if (!(AIAirport.IsValidAirportType(airport_type)))
					{
					airport_type = AIAirport.AT_SMALL;
					
					/* If small airport can't be used, try large */
					if (!(AIAirport.IsValidAirportType(airport_type)))
						{
						airport_type = AIAirport.AT_LARGE;
						
						/* If large can't be used, then that makes no sense, since at least one of these three will be available */
						if (!(AIAirport.IsValidAirportType(airport_type)))
							{
							AILog.Error("Wut, neither helistation, small airport nor large (city) airport are available!");
							return -1;
							}
						}
					}
				
				/* First check if this cargo is something that should be delivered to a town isntead of an industry */
				local town_affect = AICargo.GetTownEffect(cargo);
				if (town_affect == AICargo.TE_GOODS || town_affect == AICargo.TE_FOOD)
					{
					local town_list = this.FindSuitableTown();
					tile_2 = FindSuitableAirportSpot(town_list, airport_type, tile_1, AIAirport.AT_HELIDEPOT, cargo);
					}
				else
					{
					/* Now we need to find another industry that accepts this cargo */
					local industry_accepting_list = this.FindSuitableIndustryAcceptsCargo(cargo);
					industry_accepting_list.Valuate(AITile.GetDistanceSquareToTile, tile_1);
						
					/* Keep within reasonable distance TODO: keep within min distance as well */ 
					industry_accepting_list.RemoveAboveValue(this.max_industry_dis*this.max_industry_dis);
					tile_2 = this.FindSuitableAirportSpot_Industry_InList(industry_accepting_list,airport_type,cargo,this.ACCEPT);
					}
					
				if (tile_2 <= 0)
					{
					/* If it is still negative at the end, it couldn't find any accepting industries */
					AILog.Error("Couldn't find any accepting industries");
					/* The first station built isn't deleted, incase it is used for something else */
					continue;
					}
					
				/* If we already have a station on that spot, then it means that FindSuitableAirportSpot_Industry_InList found that there was already a suitable station there we can use */
				if (AIStation.IsValidStation(AIStation.GetStationID(tile_2)))
					{
					existing_station_2 = tile_2;
					}
					
				/* Actually build the station */
				if (existing_station_2 == null)
					{
					airport_2 = AIAirport.BuildAirport(tile_2,airport_type,AIStation.STATION_NEW)
					if (!airport_2)
						{
						/* Try another first industry */
						/* destroy first station */
						AILog.Error("Although reports said the space was clear, we could not build the second station");
						continue;
						}
					}			
				}
			}
			
		/* Build the aircraft */
		local ret = this.BuildAircraft(tile_1, tile_2, cargo, true);
			
		/* Check if building aircraft failed */
		if (ret < 0)
			{
			/* The stations built aren't deleted, incase they are used for something else */
			return ret;
			}
			
		/* Show the route statistics */
		AILog.Info(" > Show route statistics...");
		local dis_min = this.min_station_dis;
		local dis_max = this.max_station_dis;
		AILog.Info(this.INDENT + "Max allowed distance: " + dis_max);
		AILog.Info(this.INDENT + "Min allowed distance: " + dis_min);
		AILog.Info(this.INDENT + "Completed route distance: " + sqrt(AITile.GetDistanceSquareToTile(tile_1, tile_2)));
		AILog.Info(this.INDENT + "Route successfully finished!");
		return ret;
		}
	}

/**
* Returns the number of airports we already have at that industry
* Works it out by looking for stations within the acecpting/producing area
* This means that if the industry is near a town, and the town has an airport, that could be picked up
* That does not matter too much however, it simply means freight and passengers will be at the sameairport
*/
function Chopper::GetAmountOfOurAirportsAtIndustry(industry,airport_type,cargo,produce_or_accept)
	{
	/* Update log */
	if (GetSetting("debug_info"))
		{
		AILog.Error(" > Counting existing stations near " + AIIndustry.GetName(industry) + "...");
		}
		
	/* Create a list of tiles to check for a station on */
	local list = null;
	if (produce_or_accept == this.PRODUCE)
		{
		list = AITileList_IndustryProducing(industry,AIAirport.GetAirportCoverageRadius(airport_type));
		}
	if (produce_or_accept == this.ACCEPT)
		{
		list = AITileList_IndustryAccepting(industry,AIAirport.GetAirportCoverageRadius(airport_type));
		}
		
	/* Only keep the ones that are station tiles */
	list.Valuate(AITile.IsStationTile);
	list.KeepValue(1);
		
	/* If there is nothing in the lists, there is no station */
	if (list.Count() == 0)
		{
		return 0;
		}
		
	local list2 = AIList();
		
	/* Create list of the station IDs from looping through the tiles */
	for (local tile = list.Begin(); list.HasNext(); tile = list.Next())
		{
		/* Check if we own the station */
		if (AIStation.IsValidStation(AIStation.GetStationID(tile)))
			{
			/* Add the station to the list. If it already is in the list it will be ignored */
			list2.AddItem(AIStation.GetStationID(tile),1);
			}
		}
		
	/* Return the number of items in the list */
	return list2.Count();
	}

/**
* Returns the tile of a station existing near "industry" of type "airport_type" that "accepts/produces" "cargo "
*/
function Chopper::FindExistingAirport_Town(town,airport_type,cargo,center_tile)
	{
	/* Update log */
	if (GetSetting("debug_info"))
		{
		AILog.Error(" > Check for existing stations near " + AITown.GetName(town) + "...");
		}
		
	/* The position and coverage of the airport */
	local airport_width, airport_height, airport_radius;
	airport_width = AIAirport.GetAirportWidth(airport_type);
	airport_height = AIAirport.GetAirportHeight(airport_type);
	airport_radius = AIAirport.GetAirportCoverageRadius(airport_type);
		
	/* Create a list of tiles */
	local list = AITileList();
		
	/* Get the location of the town */
	local tile = AITown.GetLocation(town);
		
	/* Define the grid size we are using */
	local grid_size = 15;
		
	/* Add all tiles within this area to the list */
	list.AddRectangle(tile - AIMap.GetTileIndex(grid_size, grid_size), tile + AIMap.GetTileIndex(grid_size, grid_size));
		
	/* Remove any that aren't near the relevant town */
	list.Valuate(AITile.GetClosestTown);
	list.KeepValue(town);
		
	/* Remove any that don't accept the relevant cargo */
	list.Valuate(AITile.GetCargoAcceptance,cargo,airport_width,airport_height,airport_radius);
	list.RemoveBelowValue(10);
		
	/* If it is a passenger or mail route, remove any that don't produce the relevant cargo */
	if (AICargo.HasCargoClass(cargo,AICargo.CC_PASSENGERS) || AICargo.HasCargoClass(cargo,AICargo.CC_MAIL))
		{
		list.Valuate(AITile.GetCargoProduction,cargo,airport_width,airport_height,airport_radius);
		list.RemoveBelowValue(10);
		}
		
	/* We now have a list of all tiles around "town" that accept and produce "cargo" for an airport of type "airport_type" */
	return this.FindSuitableStationInTileList(list,airport_type,center_tile);
	}

/**
* Returns the tile of a station existing near "industry" of type "airport_type" that "accepts/produces" "cargo "
*/
function Chopper::FindExistingAirport_Industry(industry,airport_type,cargo,produce_or_accept)
	{
	/* Update log */
	if (GetSetting("debug_info"))
		{
		AILog.Error(" > Check for existing stations near " + AIIndustry.GetName(industry) + "...");
		}
		
	/* Create a list of tiles to check for a station on */
	local list = null;
	if (produce_or_accept == this.PRODUCE)
		{
		list = AITileList_IndustryProducing(industry,AIAirport.GetAirportCoverageRadius(airport_type));
		}
	if (produce_or_accept == this.ACCEPT)
		{
		list = AITileList_IndustryAccepting(industry,AIAirport.GetAirportCoverageRadius(airport_type));
		}
		
	/* Only keep the ones that are station tiles */
	list.Valuate(AITile.IsStationTile);
	list.KeepValue(1);
		
	/* If there is nothing in the lists, there is no station */
	if (list.Count() == 0)
		{
		return null;
		}
		
	/* Use another function to do the rest */
	return this.FindSuitableStationInTileList(list,airport_type,0);
	}

/**
* Finds a station that can be used from a list of stations
* Checks that the station doesn't have too many planes going to it
* Checks that the station is the appropriate "airport_type"
*/
function Chopper::FindSuitableStationInTileList(list,airport_type,center_tile)
	{
	/* Create a list to add valid stations in to */
	local list2 = AIList();
		
	/* Create list of the station IDs from looping through the tiles */
	for (local tile = list.Begin(); list.HasNext(); tile = list.Next())
		{
		/* Check we own it */
		if (AIStation.IsValidStation(AIStation.GetStationID(tile)))
			{
			/* Add to list */
			list2.AddItem(AIStation.GetStationID(tile),1);
			}
		}
		
	/* Limit the amount of planes allowed at each station */
	local plane_limit = 3;
	if (airport_type == AIAirport.AT_HELISTATION)
		{
		plane_limit = this.HELISTATION_LIMIT;
		}
	if (airport_type == AIAirport.AT_HELIPORT)
		{
		plane_limit = this.HELIPORT_LIMIT;
		}
	if (airport_type == AIAirport.AT_HELIDEPOT)
		{
		plane_limit = this.HELIDEPOT_LIMIT;
		}
	if (airport_type == AIAirport.AT_SMALL)
		{
		plane_limit = this.SMALL_LIMIT;
		}
	if (airport_type == AIAirport.AT_LARGE)
		{
		plane_limit = this.LARGE_LIMIT;
		}
		
	/* Return the first station that is the correct type */
	for (local station = list2.Begin(); list2.HasNext(); station = list2.Next())
		{
		if (AIAirport.GetAirportType(AIStation.GetLocation(station)) == airport_type)
			{
			/* Check that there aren't too many aircraft going to this already, and also very importantly, check this airport isn't the same as the airport we've already built at (center_tile)*/
			local vehicle_list = AIVehicleList_Station(AIStation.GetStationID(AIStation.GetLocation(station)));
			
			if (vehicle_list.Count() < plane_limit && AIStation.GetLocation(station) != center_tile)
				{	
				return AIStation.GetLocation(station);
				}
			}
		}
		
	/* If none were returned earlier, failed */
	return null;
	}

/**
* Finds a suitable spot for an airport next to "industry"
* Takes into account "airport_type", "cargo" and whether it is "produce_or_accept"
*/
function Chopper::FindSuitableAirportSpot_Industry(industry,airport_type,cargo,produce_or_accept)
	{
	/* Get location of industry */
	local tile = AIIndustry.GetLocation(industry);
		
	/* The position and coverage of the airport */
	local airport_width, airport_height, airport_radius;
	airport_width = AIAirport.GetAirportWidth(airport_type);
	airport_height = AIAirport.GetAirportHeight(airport_type);
	airport_radius = AIAirport.GetAirportCoverageRadius(airport_type);
		
	/* Create grid */
	local list = AITileList();
	local grid_size = 10;
		
	/* XXX -- We assume we are more than "grid_size"tiles away from the border! */
	list.AddRectangle(tile - AIMap.GetTileIndex(grid_size, grid_size), tile + AIMap.GetTileIndex(grid_size, grid_size));
		
	/* Only keep the tiles where there is enough space to build an airport, so even though in debug only one tile is marked with a sign, that sign represents where the top corner of the airport would be! */
	list.Valuate(AITile.IsBuildableRectangle, airport_width, airport_height);
	list.KeepValue(1);
		
	/* Mark whether they produce/accept */
	if (produce_or_accept == this.PRODUCE)
		{
		list.Valuate(AITile.GetCargoProduction,cargo,airport_width,airport_height,airport_radius);
		}
	if (produce_or_accept == this.ACCEPT)
		{
		list.Valuate(AITile.GetCargoAcceptance,cargo,airport_width,airport_height,airport_radius);
		}
		
	/* Only keep the ones that produce/accept */
	list.KeepAboveValue(0);
		
	/* Create signs in increasing number, number 1 being the best spot, and the last sign being the worst spot */
	if (GetSetting("debug_signs") == 1)
		{
		local count = 1;
		for (local a_tile = list.Begin(); list.HasNext(); a_tile = list.Next())
			{
			AISign.BuildSign(a_tile,count);
			count += 1;
			}
		}
		
	/* Indent so that testing mode ends at the other end of this code block! */
		{
		/* Switch to testing mode for testing of building airport */
		local test = AITestMode();
		local good_tile = 0;
		for (tile = list.Begin(); list.HasNext(); tile = list.Next())
			{
			/* Don't hog CPU */
			Sleep(1);
				
			/* Build the airport in testing mode */
			local airport_test = AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)
				
			/* If the airport could not be built... */
			if (!airport_test)
				{
				/* Show why it couldn't be built */
				AILog.Warning(this.INDENT + "Can't build airport, reason: " + AIError.GetLastErrorString());
				
				/* ERR_UNKNOWN seems to be reported when the authority won't allow another airport */
				if (AIError.GetLastError() == AIError.ERR_LOCAL_AUTHORITY_REFUSES || AIError.GetLastError() == AIError.ERR_UNKNOWN)
					{
					AILog.Error("Local authority won't allow an airport to be built");
					//TODO: Plant trees and retry!
					break;
					}
					
				/* If it was from not being flat land, flatten the land */
				if (AIError.GetLastError() == AIError.ERR_FLAT_LAND_REQUIRED)
					{
					AILog.Info(" > Land isn't flat, checking if flattening will help...");
					local exec = AIExecMode();
					this.FlattenForAirport(tile, airport_width airport_height);
					Sleep(1);
						
					/* Back to test mode for the airport */
					local test2 = AITestMode();
						
					/* Now try and build it */
					airport_test = AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW);
					}
				}
				
			/* If it failed, try next in loop */
			if (!airport_test)
				{
				continue;
				}
				
			good_tile = tile;
			break;
			}
			
		/* Did we find a place to build the airport on? */
		if (good_tile == 0) return -1;
		}
	/* Testing mode ends here */
		
	/* Update log */
	AILog.Info(this.INDENT + "Found a good spot for an airport near industry " + AIIndustry.GetName(industry) + " at tile " + tile);
		
	/* Put Xs on the airport tiles if in debug mode */
	if (GetSetting("debug_signs") == 1)
		{
		if (airport_type == AIAirport.AT_HELIPORT)
			{
			AISign.BuildSign(tile + AIMap.GetTileIndex(0,0),"X");
			}
		if (airport_type == AIAirport.AT_HELIDEPOT)
			{
			AISign.BuildSign(tile + AIMap.GetTileIndex(0,0),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(1,0),"X");
				
			AISign.BuildSign(tile + AIMap.GetTileIndex(0,1),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(1,1),"X");
			}
		if (airport_type == AIAirport.AT_HELISTATION)
			{
			AISign.BuildSign(tile + AIMap.GetTileIndex(0,0),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(1,0),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(2,0),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(3,0),"X");
				
			AISign.BuildSign(tile + AIMap.GetTileIndex(0,1),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(1,1),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(2,1),"X");
			AISign.BuildSign(tile + AIMap.GetTileIndex(3,1),"X");
			}
		}
		
	/* Return the tile */
	return tile;
	}

/**
* Checks for a suitable spot for an airport next to an industry from a list of industries
*/
function Chopper::FindSuitableAirportSpot_Industry_InList(list,airport_type,cargo,produce_or_accept)
	{
	/* Stores if there is an existing station to be used */
	local existing_station = null;
		
	/* Defines tile as negative, so that if it finds nothing it returns failure */
	local tile = -1;
		
	/* Loop through all the industries in the list */
	for (local item = list.Begin(); list.HasNext(); item = list.Next())
		{
		/* If a station already exists, return that tile */
		existing_station = this.FindExistingAirport_Industry(item,airport_type,cargo,produce_or_accept);
			
		/* If it does, return that */
		if (existing_station != null)
			{
			return existing_station;
			}	
			
		/* Otherwise, find a spot for a new airport and return that */
		tile = this.FindSuitableAirportSpot_Industry(item,airport_type,cargo,produce_or_accept);
		if (tile > 0)
			{
			return tile;
			}
		}
		
	/* Return negative if epic fail */
	return -1;
	}

/**
* Combines two numbers into one
*/
function Chopper::IntegerMerge(in1,in2)
	{
	/* Combine two numbers into one */
	return (in1 + (in2 << 16));
	}
	
/**
* Retrieves the first number
*/
function Chopper::IntegerReturn1(processed)
	{
	/* Return the second number */
	return (processed - ((processed >> 16) << 16));
	}

/**
* Retrieves the second number
*/	
function Chopper::IntegerReturn2(processed)
	{
	/* Return the first number */
	return (processed >> 16);
	}

/**
* Gives the industry a score based on many different factors
* May need tweaking, but seems to work very well at the moment =)
*/
function Chopper::CalculateIndustryScore(industry,cargo)
	{
	/* Define the score variables */
	local score = 0;
		
	/* Get the cargo production */
	local cargo_production = AIIndustry.GetLastMonthProduction(industry,cargo);
		
	/* Get the industry position */
	local industry_tile = AIIndustry.GetLocation(industry);
		
	/* Choose a suitable engine */
	local engine = this.EngineGetForCargo(AIVehicle.VT_AIR,AIAirport.PT_HELICOPTER,cargo);
		
	/* If "engine" is negative, we can't afford any of them (very rarely happens, only happened when I spent lots of money right before the AI ran this script and I was on his team, so he thought he had enough money) but I am adding this in just to stop it from crashing */
	if (engine <= 0)
		{
		AILog.Error("Couldn't calculate score because no suitable/affordable aircraft are available");
		return 0;
		}
		
	/* Get its speed */
	local engine_speed = AIEngine.GetMaxSpeed(engine);
		
	/* Get the average distance from "industry_tile" to industries that accept "cargo" */
	local distance = this.AverageDistanceToIndustriesAcceptingCargo(industry_tile,cargo);
		
	/* If this distance is negative, then no industries accept that cargo */
	if (distance <= 0)
		{
		AILog.Error(this.INDENT + AIIndustry.GetName(industry) + " transporting " + AICargo.GetCargoLabel(cargo) + " scored " + score);
		return 0;
		}
		
	local speed_factor = 1;
	if (GetSetting("use_plane_speed_factor") == 1)
		{
		speed_factor = AIGameSettings.GetValue("vehicle.plane_speed");
		}
		
	/* Calculate the score */
	score = (cargo_production*AICargo.GetCargoIncome(cargo,distance,distance/(engine_speed*speed_factor)));
		
	return score;
	}

/**
* Checks if there is an engine available to transport "cargo"
*/
function Chopper::EngineExistsForCargo(vehicle_type,specific_vehicle_type,cargo)
	{
	/* Create a list of all air type engines */
	local engine_list = AIEngineList(vehicle_type);
		
	/* Loop through all the engines */
	for (local engine = engine_list.Begin(); engine_list.HasNext(); engine = engine_list.Next())
		{
		/* If en engine can be refitted to that cargo, and is a helicopter, return true */
		if (AIEngine.CanRefitCargo(engine,cargo) && (AIEngine.GetPlaneType(engine) == specific_vehicle_type))
			{
			return true;
			}
		}
			
	/* Return false if true was not returned, since return exists the function */
	return false;
	}

/**
* Finds a suitable engine that can transport "cargo"
*/
function Chopper::EngineGetForCargo(vehicle_type,specific_vehicle_type,cargo)
	{
	/* Tell what we are doing */
	AILog.Info(" > Produce list of suitable helicopters");
		
	/* Create a list of all air type engines */
	local engine_list = AIEngineList(vehicle_type);
		
	/* Loop through all the engines */
	for (local engine = engine_list.Begin(); engine_list.HasNext(); engine = engine_list.Next())
		{
		/* If en engine can be refitted to that cargo, and is a helicopter, return true */
		if (AIEngine.CanRefitCargo(engine,cargo) && (AIEngine.GetPlaneType(engine) == specific_vehicle_type))
			{
			/* We want to take into account the capacity and speed */
			/* Running cost, life span, design date and reliability does not make much difference */
			/* Cost doesn't matter, if we can't afford it we can get the next engine down in the list */
			local capacity = AIEngine.GetCapacity(engine);
			local speed = AIEngine.GetMaxSpeed(engine);
			local score = (capacity*4)+(speed);
			engine_list.SetValue(engine,score);
			
			/* Display the vehicle score */
			if (GetSetting("debug_info"))
				{
				AILog.Warning(this.INDENT + AIEngine.GetName(engine) + " scored: " + score);
				}
			}
		else
			{
			engine_list.SetValue(engine,0);
			}
		}
		
	/* Only keep the engines in the list that have the correct cargo type and engine type */
	engine_list.RemoveValue(0);
		
	/* Sort by its score, descending */
	engine_list.Sort(AIList.SORT_BY_VALUE,false);
		
	if (engine_list.IsEmpty())
		{
		AILog.Error("No suitable helicopter available");
		return -1;
		}
		
	/* Loop through all the engines */
	for (local engine = engine_list.Begin(); engine_list.HasNext(); engine = engine_list.Next())
		{
		/* Get the cost */
		local engine_cost = AIEngine.GetPrice(engine);
			
		/* Try and get the money to cover the cost, plus £1000 incase money has gone down a bit due to running costs by the time we get to building it */
		this.GetMoney(engine_cost + 1000);	
		if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) <= engine_cost)
			{
			if (GetSetting("debug_info"))
				{
				AILog.Warning("Can't afford to build a " + AIEngine.GetName(engine) + ", checking next engine on list");
				}
			continue;
			}
		else
			{
			AILog.Info("The best possible helicopter we can afford is a " + AIEngine.GetName(engine));
			return engine;
			}
		}
		
	/* could afford none */
	return -2;
	}

/**
* Checks if there is an engine available to transport "cargo" that we can afford
*/
function Chopper::EngineWeCanAffordExistsForCargo(vehicle_type,specific_vehicle_type,cargo)
	{
	/* Create a list of all air type engines */
	local engine_list = AIEngineList(vehicle_type);
		
	/* Loop through all the engines */
	for (local engine = engine_list.Begin(); engine_list.HasNext(); engine = engine_list.Next())
		{
		/* If en engine can be refitted to that cargo, and is a helicopter, return true */
		if (AIEngine.CanRefitCargo(engine,cargo) && (AIEngine.GetPlaneType(engine) == specific_vehicle_type))
			{
			engine_list.SetValue(engine,1);
			}
		else
			{
			engine_list.SetValue(engine,0);
			}
		}
		
	/* Only keep the engines in the list that have the correct cargo type and engine type */
	engine_list.RemoveValue(0);
		
	if (engine_list.IsEmpty())
		{
		AILog.Error("No suitable helicopter available");
		return -1;
		}
		
	/* Loop through all the engines */
	for (local engine = engine_list.Begin(); engine_list.HasNext(); engine = engine_list.Next())
		{
		/* Get the cost */
		local engine_cost = AIEngine.GetPrice(engine);
			
		/* Try and get the money to cover the cost, plus £1000 incase money has gone down a bit due to running costs by the time we get to building it */
		this.GetMoney(engine_cost + 1000);	
		if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) <= engine_cost)
			{
			continue;
			}
		else
			{
			return true;
			}
		}
		
	/* can afford none */
	return false;
	}

/**
* Works out the average distance from "tile" to industries that accept "cargo"
* Used to rougly estimate route distances
*/
function Chopper::AverageDistanceToIndustriesAcceptingCargo(tile,cargo)
	{
	local industry_list = AIIndustryList_CargoAccepting(cargo);
	local divider = 0;
	local distance_before = 0;
		
	/* Loop through and add up all distances */
	for (local industry = industry_list.Begin(); industry_list.HasNext(); industry = industry_list.Next())
		{
		/* I know that helicopters don't follow the manhattan distance, but it doesn't need the be amazingly accurate, and this is the closest there is without involving trigonometry */
		distance_before += AIMap.DistanceManhattan(tile,AIIndustry.GetLocation(industry));
		divider += 1;
		}
			
	/* Return the average distance */
	if (divider == 0)
		{
		/* If divider==0, then it is a cargo that goes to towns, and so we estimate the town distance very badly... =( */
		return (this.min_station_dis+this.max_station_dis)/2;
		}
	else
		{
		return (distance_before/divider);
		}
	}

/**
* An exact function for this exists in the trunk, but not in 0.7.2, so I made this for compatibility
*/
function Chopper::GetLastMonthTransported_Percentage(industry,cargo)
	{
	/* percentage =transpoted/production e.g. 96/128 =  75%*/
	if (AIIndustry.GetLastMonthProduction(industry,cargo) == 0)
	return 0;
	else
	return ((AIIndustry.GetLastMonthTransported(industry,cargo)*100)/AIIndustry.GetLastMonthProduction(industry,cargo));
	}
	
/**
* Finds a passenger industry (oilrig)
* Then finds nearby town
* Then builds helicopter and gives it orders to go to passenger industry
*/
function Chopper::BuildIndustryPassengerRoute()
	{
	/* The station type to build */
	local airport_1_type = AIAirport.AT_HELIDEPOT;
		
	/* Define tiles */
	local tile_1 = null;
	local tile_2 = null;
		
	/* Generate a list of the industries */
	AILog.Info(" > Checking passenger industries...");
		
	/* Gets a list of industries that can be used, list is arranged randomly! */
	local industry_list = this.FindSuitableIndustryWithHeliport(false);
		
	/* Choose an industry from the list */
	AILog.Info(this.INDENT + "Chosen industry: " + AIIndustry.GetName(industry_list.Begin()));
	tile_2 = AIIndustry.GetHeliportLocation(industry_list.Begin());
		
	/* If there are no towns in the list, give up */
	if (industry_list.Count() == 0)
		{
		AILog.Error("No industries can be built at!");
		return -1;
		}
		
	/* Generate a list of towns that would be a good place to build an airport at */
	AILog.Info(" > Checking who has built where...");
	local town_list = this.FindSuitableTown();
		
	/* If there are no towns in the list, give up */
	if (town_list.Count() == 0)
		{
		AILog.Error("No towns can be built at!");
		return -1;
		}
		
	tile_1 = this.FindSuitableAirportSpot(town_list, airport_1_type, 0, 0,this.passenger_cargo_id);
		
	/* Now we have both tile_1 and tile_2, so we can build the airport, but only if there is no airport there already */
	if (!(this.CheckIfOurStationAtTile(tile_1)))
		{
		/* Build the airports for real */
		if (!AIAirport.BuildAirport(tile_1, airport_1_type, AIStation.STATION_NEW))
			{
			AILog.Error("Although the testing told us we could build 2 airports, it still failed on the first airport at tile " + tile_1 + ".");
			return -3;
			}
		}
		
	local ret = this.BuildAircraft(tile_1, tile_2, this.passenger_cargo_id, false);
	if (ret < 0)
		{
		return ret;
		}
	
	AILog.Info(" > Show route statistics...");
	local dis_min = this.min_station_dis;
	local dis_max = this.max_station_dis;
	AILog.Info(this.INDENT + "Max allowed distance: " + dis_max);
	AILog.Info(this.INDENT + "Min allowed distance: " + dis_min);
	AILog.Info(this.INDENT + "Completed route distance: " + sqrt(AITile.GetDistanceSquareToTile(tile_1, tile_2)));
	AILog.Info(this.INDENT + "Route successfully finished!");
	return ret;
	}

/**
* Checks if we already have a station built at this tile
*/
function Chopper::CheckIfOurStationAtTile(tile)
	{
	/* Check if it's anyone's station */
	if (AITile.IsStationTile(tile))
		{
		/* If there is a station, check that it is ours */
		if (AIStation.IsValidStation(AIStation.GetStationID(tile)))
			{
			return true;
			}
		}
			
	/* Return false if it isn't ours, or there is no station */
	return false;
	}

/**
* Converts airport_type to string
*/
function Chopper::AirportTypeToString(airport_type)
	{
	switch (airport_type)
		{
		case AIAirport.AT_SMALL:
		return "Small airport";
		break;
		case AIAirport.AT_LARGE:
		return "City airport";
		break;
		case AIAirport.AT_HELISTATION:
		return "Helistation";
		break;
		case AIAirport.AT_HELIDEPOT:
		return "Helidepot";
		break;
		case AIAirport.AT_HELIPORT:
		return "Heliport";
		break;
		case AIAirport.AT_METROPOLITAN:
		return "Metropolitan airport";
		break;
		case AIAirport.AT_INTERNATIONAL:
		return "International airport";
		break;
		case AIAirport.AT_COMMUTER:
		return "Commuter airport";
		break;
		case AIAirport.AT_INTERCON:
		return "Intercontinental airport";
		break;
		case AIAirport.AT_INVALID:
		return "Invalid airport";
		break;
		default:
		return "Even more invalid airport";
		break;
		}
	}
	
/**
 * Overview of function:
 * >Declare airport types
 * >Try and build the biggest aiport available for the first station
 * >Try and build a Heliport for the second station
 * >Create a helicopter and give it orders to go from first station to second
 */
function Chopper::BuildAirportRoute(town_list)
	{
	/* If there are no towns in the list, give up */
	if (town_list.Count() == 0)
		{
		AILog.Error("No towns can be built at!");
		return -1;
		}

	/* Create lists to store the airports that can be built */
	local airport_1_type_list = AIList();
	local airport_2_type_list = AIList();
	
	/* These will store the chosen airport type */
	local airport_1_type = null;
	local airport_2_type = null;
	
	/* Populate the first list, the value is used to determine which should be attempted to be built first (0 = first, 4 = last) */
	/* We try helistation first because we want an airport that can take a lot of air traffic */
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELISTATION))
		{
		airport_1_type_list.AddItem(AIAirport.AT_HELISTATION,0);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELIDEPOT))
		{
		airport_1_type_list.AddItem(AIAirport.AT_HELIDEPOT,1);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELIPORT))
		{
		airport_1_type_list.AddItem(AIAirport.AT_HELIPORT,2);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_SMALL))
		{
		airport_1_type_list.AddItem(AIAirport.AT_SMALL,3);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_LARGE))
		{
		airport_1_type_list.AddItem(AIAirport.AT_LARGE,4);
		}

	/* Populate the second list, the value is used to determine which should be attempted to be built first (0 = first, 4 = last) */
	/* We try heliport first because we want it as close to the middle of the town as possible */
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELISTATION))
		{
		airport_2_type_list.AddItem(AIAirport.AT_HELISTATION,2);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELIDEPOT))
		{
		airport_2_type_list.AddItem(AIAirport.AT_HELIDEPOT,1);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELIPORT))
		{
		airport_2_type_list.AddItem(AIAirport.AT_HELIPORT,0);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_SMALL))
		{
		airport_2_type_list.AddItem(AIAirport.AT_SMALL,3);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_LARGE))
		{
		airport_2_type_list.AddItem(AIAirport.AT_LARGE,4);
		}
	
	/* This should never happen, since there is always an airport available, but you can never be too carfeul, eh? */
	if (airport_1_type_list.Count() == 0 || airport_2_type_list.Count() == 0)
		{
		AILog.Error("There are no available airports!");
		return -1;
		}
	
	/* Whether a spot has been found */
	local found_spot_1 = false;
	
	/* tile_1 stores the position of the first airport */
	local tile_1 = null;
	local tile_2 = null;
	
	/* Get some money to work with */
	this.GetMoney(150000);
	
	/* Sort the lists ascending */
	airport_1_type_list.Sort(AIAbstractList.SORT_BY_VALUE,true);
	airport_2_type_list.Sort(AIAbstractList.SORT_BY_VALUE,true);

	/* If it is a subsidy, then this passes the town to build near to FindSuitableAirportSpot */
	if (this.subsidy_town_tiletouse != null)
		{
		AILog.Info(" > Attempting to do a subsidy route from " + AITown.GetName(this.subsidy_town_1) + " to " + AITown.GetName(this.subsidy_town_2));
		AILog.Info(" > Passing first tile value...");
		this.subsidy_town_tiletouse = this.subsidy_town_1;
		}
	
	/* Loop through the first types of airport */
	for (airport_1_type = airport_1_type_list.Begin(); airport_1_type_list.HasNext(); airport_1_type = airport_1_type_list.Next())
		{
		AILog.Info(" > Attempting to find a suitable spot for airport type: " + AirportTypeToString(airport_1_type));
		tile_1 = this.FindSuitableAirportSpot(town_list, airport_1_type, 0, 0,this.passenger_cargo_id);
		if (tile_1 < 0)
			{
			AILog.Info(this.INDENT + "Couldn't find a spot for: " + AirportTypeToString(airport_1_type));
			continue;
			}
		else
			{
			AILog.Info(this.INDENT + "Found a spot for: " + AirportTypeToString(airport_1_type));
			break;
			}
		}
	
	/* If a space wasn't found... */
	if (tile_1 < 0)
		{
		if (this.subsidy_town_tiletouse != null)
			{
			/* Subsidys are more likely to fail since they are forced to check certain towns */
			AILog.Warning(this.INDENT + "Subsidy route could not be built");
			this.subsidy_town_tiletouse = null;
			this.subsidy_town_1 = null;
			this.subsidy_town_2 = null;
			return -1;
			}
		else
			{
			/* Found no space for any airport in any town */
			AILog.Warning(this.INDENT + "Couldn't find any space in any town for any airport!");
			}
		}
	
	/* If it is a subsidy, then this passes the town to build near to FindSuitableAirportSpot */
	if (this.subsidy_town_tiletouse != null)
		{
		AILog.Info(" > Passing second tile value...");
		this.subsidy_town_tiletouse = this.subsidy_town_2;
		}
	
	/* If intercity routes or multiple stations are disabled, remove the previously used station from the list of stations for the second airport search */
	if (GetSetting("allow_intercity_routes") == 0 || GetSetting("multiple_stations_per_town") == 0)
		{
		AILog.Info(" > Removing just used town from list");
		town_list = this.RemoveFromList(town_list, AITile.GetClosestTown(tile_1));
		}
	
	/* Loop through the first types of airport */
	for (airport_2_type = airport_2_type_list.Begin(); airport_2_type_list.HasNext(); airport_2_type = airport_2_type_list.Next())
		{
		AILog.Info(" > Attempting to find a suitable spot for airport type: " + AirportTypeToString(airport_2_type));
		tile_2 = this.FindSuitableAirportSpot(town_list, airport_2_type, tile_1, 0,this.passenger_cargo_id);
		if (tile_2 < 0)
			{
			AILog.Info(this.INDENT + "Couldn't find a spot for: " + AirportTypeToString(airport_2_type));
			continue;
			}
		else
			{
			AILog.Info(this.INDENT + "Found a spot for: " + AirportTypeToString(airport_2_type));
			break;
			}
		}

	/* If a space wasn't found... */
	if (tile_2 < 0)
		{
		if (this.subsidy_town_tiletouse != null)
			{
			/* Subsidys are more likely to fail since they are forced to check certain towns */
			AILog.Warning(this.INDENT + "Subsidy route could not be built");
			this.subsidy_town_tiletouse = null;
			this.subsidy_town_1 = null;
			this.subsidy_town_2 = null;
			return -1;
			}
		else
			{
			/* Found no space for any airport in any town */
			AILog.Warning(this.INDENT + "Couldn't find any space in any town for a second airport!");
			}
		}
	
	/* Execution mode */
	local exec = AIExecMode();
	
	/* Build the airports for real */
	if (!(this.CheckIfOurStationAtTile(tile_1)))
		{
		if (!AIAirport.BuildAirport(tile_1, airport_1_type, AIStation.STATION_NEW))
			{
			AILog.Error("Although the testing told us we could build 2 airports, it still failed on the first airport at tile " + tile_1 + ".");
			return -3;
			}
		}
	
	if (!(this.CheckIfOurStationAtTile(tile_2)))
		{
		if (!AIAirport.BuildAirport(tile_2, airport_2_type, AIStation.STATION_NEW))
			{
			AILog.Error("Although the testing told us we could build 2 airports, it still failed on the second airport at tile " + tile_2 + ".");
			return -4;
			}
		}
	
	/* Actually build the aircraft */
	local ret = this.BuildAircraft(tile_1, tile_2, this.passenger_cargo_id, false);
	if (ret < 0)
		{
		return ret;
		}
	
	/* Show route statistics */
	AILog.Info(" > Show route statistics...");
	local dis_min = this.min_station_dis;
	local dis_max = this.max_station_dis;
	AILog.Info(this.INDENT + "Max allowed distance: " + dis_max);
	AILog.Info(this.INDENT + "Min allowed distance: " + dis_min);
	AILog.Info(this.INDENT + "Completed route distance: " + sqrt(AITile.GetDistanceSquareToTile(tile_1, tile_2)));
	AILog.Info(this.INDENT + "Route successfully finished!");

	return ret;
	}

/**
* I don't think this is used
*/
function Pop()
	{
	local c = this.Peek();
	this.RemoveItem(this.list.Begin());
	return c;
	}

/**
* Returns the approximate square root of "num"
*/
function sqrt(num)
	{
    if (0 == num)
		{
       return 0;
		}
		
    local n = (num / 2) + 1;
    local n1 = (n + (num / n)) / 2;
		
    while (n1 < n)
		{
      n = n1;
      n1 = (n + (num / n)) / 2;
		}
		
    return n;
	}
	
/**
 * Build an aircraft with orders from tile_1 to tile_2.
 *  The best available aircraft of that time will be bought.
 */
function Chopper::BuildAircraft(tile_1, tile_2, cargo, full_load_at_first_station)
	{
	/* Define the possible airport hangars*/
	local hangar_1 = AIAirport.GetHangarOfAirport(tile_1);
	local hangar_2 = AIAirport.GetHangarOfAirport(tile_2);
	local hangar = hangar_1;
	if (AIAirport.GetNumHangars(tile_1) <= 0)
		{
		AILog.Error("Cannot find a depot at station 1, checking other station");
		if (AIAirport.GetNumHangars(tile_2) <= 0)
			{
			AILog.Error("Cannot find a depot at station 2 either.");
			AILog.Error("Going to search for a nearby depot instead.");
			local station_list = AIStationList(AIStation.STATION_AIRPORT);
				
			/*Attempt to find a nearby depot*/
			for (local station = station_list.Begin(); station_list.HasNext(); station = station_list.Next())
				{
				/* Use station ID to get a list of the tiles the station occupies that are airport tiles*/
				local station_tile_list = AITileList_StationType(station,AIStation.STATION_AIRPORT);
					
				/* Use first tile in list to check if airport has hangar*/
				if (AIAirport.GetNumHangars(station_tile_list.Begin()))
					{
					/*Airport has hangar, use this to build plane*/
					hangar = AIAirport.GetHangarOfAirport(station_tile_list.Begin());
					AILog.Info("Found a nearby depot");
					}
				}
			}
		else
			{
			hangar = hangar_2;
			}
		}
		
	/* Choose an engine for this cargo */
	local engine = this.EngineGetForCargo(AIVehicle.VT_AIR,AIAirport.PT_HELICOPTER,cargo);
		
	if (engine == null)
		{
		AILog.Error("None of the aircraft are suitable/affordable");
		return -8;
		}
		
	/* Build the vehicle */
	AILog.Info(" > Building helicopter...");
	local vehicle = AIVehicle.BuildVehicle(hangar, engine);
	if (!AIVehicle.IsValidVehicle(vehicle))
		{
		AILog.Error("Couldn't build the aircraft");
		return -6;
		}
	AILog.Info(this.INDENT + "Successfully built helicopter");
		
	/* Store a tile of the station that can be used to give orders, as the top tile on some airports is a depot and would result in go to depot order */
	local tile_1_station = tile_1;
	local tile_2_station = tile_2;
		
	if (AIAirport.IsHangarTile(tile_1_station))
		{
		tile_1_station += AIMap.GetTileIndex(1,0);
		}
	if (AIAirport.IsHangarTile(tile_2_station))
		{
		tile_2_station += AIMap.GetTileIndex(1,0);
		}
		
	AILog.Info(" > Assigning helicopter order...");
	
	local first_order_success = false;
	
	/* Give order to go to first airport*/
	if (AIAirport.GetAirportType(tile_1) == AIAirport.AT_HELIPORT)
		{
		if (full_load_at_first_station == true)
			{
			first_order_success = AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_FULL_LOAD_ANY);
			}
		else
			{
			if (this.UseEarlyValues())
				{
				first_order_success = AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_FULL_LOAD_ANY);
				}
			else
				{
				first_order_success = AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_NONE);
				}
			}
		}
	else
		{
		if (full_load_at_first_station == true)
			{
			first_order_success = AIOrder.AppendOrder(vehicle, tile_1 + AIMap.GetTileIndex(1,1), AIOrder.AIOF_FULL_LOAD_ANY);
			}
		else
			{
			if (this.UseEarlyValues())
				{
				first_order_success = AIOrder.AppendOrder(vehicle, tile_1 + AIMap.GetTileIndex(1,1), AIOrder.AIOF_FULL_LOAD_ANY);
				}
			else
				{
				first_order_success = AIOrder.AppendOrder(vehicle, tile_1 + AIMap.GetTileIndex(1,1), AIOrder.AIOF_NONE);
				}
			}
		}
	
	if (first_order_success == true)
		AILog.Info("Successfully assigned first order");
	else
		AILog.Error("Failed to assign first order");
	
	local second_order_success = false;
	
	/* Give order to go to second airport*/
	if (AIAirport.GetAirportType(tile_2) == AIAirport.AT_HELIDEPOT || AIAirport.GetAirportType(tile_2) == AIAirport.AT_HELISTATION)
		{
		if (this.UseEarlyValues() && full_load_at_first_station == false)
			{
			second_order_success = AIOrder.AppendOrder(vehicle, tile_2 + AIMap.GetTileIndex(1,1), AIOrder.AIOF_FULL_LOAD_ANY);	
			}
		else
			{
			second_order_success = AIOrder.AppendOrder(vehicle, tile_2 + AIMap.GetTileIndex(1,1), AIOrder.AIOF_NONE);
			}
		}
	else
		{
		if (this.UseEarlyValues() && full_load_at_first_station == false)
			{
			second_order_success = AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_FULL_LOAD_ANY);
			}
		else
			{
			second_order_success = AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NONE);
			}
		}

	if (second_order_success == true)
		AILog.Info("Successfully assigned second order");
	else
		AILog.Error("Failed to assign second order");

	if (AIOrder.GetOrderCount(vehicle) == 1)
		{
		AILog.Error("Helicopter only got assigned one order!!");
		}
		
	/* Refit the vehicle to the correct cargo */
	AIVehicle.RefitVehicle(vehicle, cargo);
		
	/* Send him on his way */
	AIVehicle.StartStopVehicle(vehicle);
		
	/* Update log */
	AILog.Info(this.INDENT + "Finished assigning orders");
		
	return 1;
}

/**
* Searches for any industry with a heliport
* The only one I know of is the oilrig, but if there are more added, it will still work! :)
*/
function Chopper::FindSuitableIndustryWithHeliport(silent)
	{
	/* Create a list of all the industries */
	local industry_list = AIIndustryList();
		
	local industries_to_remove = AIList();
		
	/* First we remove any industries that aren't accessible by helicopter */
	for (local industry = industry_list.Begin(); industry_list.HasNext(); industry = industry_list.Next())
		{
		/* Don't hog CPU */
		Sleep(1);
			
		/* If that industry has no heliport, remove it from the list */
		if ((AIIndustry.HasHeliport(industry)) == false)
			{
			industries_to_remove.AddItem(industry,AIIndustry.GetLocation(industry));
			}
		}
		
	/* Remove the selected industries, then clear the list as it will be reused */
	industry_list.RemoveList(industries_to_remove);
	industries_to_remove.Clear();
		
	/* Loop through them all */
	for (local industry = industry_list.Begin(); industry_list.HasNext(); industry = industry_list.Next())
		{
		local remove_from_list = false;
		local industry_canbuild = "O";
		local excuse_1 = "";
		local excuse_2 = "";
		local excuse_3 = "";
			
		/* Don't hog CPU */
		Sleep(1);
			
		/* Remove from list if monthly passenger production is less than 8 */
		if (AIIndustry.GetLastMonthProduction(industry,this.passenger_cargo_id) < 8)
			{
			remove_from_list = true;
			excuse_1 = "(Only produces " + AIIndustry.GetLastMonthProduction(industry,this.passenger_cargo_id) + " passengers)";
			}
			
		/* Remove the industry from list if it has greater than 60% passengers transported */
		if (this.check_oilrig_transported == true)
			{
			if (AIIndustry.GetLastMonthTransportedPercentage(industry,this.passenger_cargo_id) > 80)
				{
				remove_from_list = true;
				excuse_2 = "(" + AIIndustry.GetLastMonthTransportedPercentage(industry,this.passenger_cargo_id) + "% is already transported)";
				}
			}
			
		/* Remove the industry from the list if there are already this.OILRIG_LIMIT helicopters that visit there */
		local vehicle_list = AIVehicleList_Station(AIStation.GetStationID(AIIndustry.GetHeliportLocation(industry)));
		if (vehicle_list.Count() >= this.OILRIG_LIMIT )
			{	
			remove_from_list = true;
			excuse_3 = "(There are already " + this.OILRIG_LIMIT + " aircraft servicing this industry)";
			}
		if (remove_from_list == true)
			{
			industries_to_remove.AddItem(industry,AIIndustry.GetLocation(industry));
			industry_canbuild = "X"
			}
		local excuse_divider = "";
		local excuse_divider2 = "";
		if (excuse_1 != "" && excuse_2 != "")
			{
			excuse_divider = " ";
			}
		if (excuse_2 != "" && excuse_3 = "")
			{
			excuse_divider2 = " ";
			}
		if (silent == 0 || silent == false)
			{
			AILog.Warning(this.INDENT + industry_canbuild + "     " + AIIndustry.GetName(industry) + " " + excuse_1 + excuse_divider + excuse_2 + excuse_divider2 + excuse_3);
			}
		}
		
	/* Now remove industries */
	industry_list.RemoveList(industries_to_remove);
	if (silent == 0 || silent == false)
		{
		AILog.Info(" > Generating list of industries I can build at...")
		}
	for (local industry = industry_list.Begin(); industry_list.HasNext(); industry = industry_list.Next())
		{
		AILog.Warning(this.INDENT + AIIndustry.GetName(industry));
		}
		
	/* Now we are left with a list of all industries with heliports that produce passengers and aren't being used too much by anyone else(so probably all the oilrigs :P ) */
		
	/* Valuate by their production */
	industry_list.Valuate(AIIndustry.GetLastMonthProduction,this.passenger_cargo_id);
		
	/* Return random list */
	return industry_list;
	}

/**
* Returns a list of industries that accept "cargo"
*/
function Chopper::FindSuitableIndustryAcceptsCargo(cargo)
	{
	/* Create list of all industries */
	local industry_list = AIIndustryList();
		
	/* Give them a value of 1 or 0, depending on whether they accept "cargo" or not */
	industry_list.Valuate(AIIndustry.IsCargoAccepted,cargo);
		
	/* Only keep the ones that have a value of 1, meaning they do accept the cargo */
	industry_list.KeepValue(1);
		
	/* Return this list */
	return industry_list;
	}

/**
* Returns a list of industries that produce "cargo"
*/
function Chopper::FindSuitableIndustryProducesCargo(cargo)
	{
	/* Loop through all industries */
	for (local industry = industry_list.Begin(); industry_list.HasNext(); industry = industry.Next())
		{
		/* Create a ist of cargos this industry produces */
		local cargo_list = AICargoList_IndustryProducing(industry);
			
		/* Define whether it accepts the cargo as first initally */
		local accepts = false;
			
		/* Check each cargo in the list (probably only one or two) against the cargo supplied in the argument */
		for (cargo_i = cargo_list.Begin(); cargo_list.HasNext(); cargo_i = cargo_list.Next())
			{
			/* If it produces that cargo, then set that it accepts it to true */
			if (cargo_i == cargo)
				{
				accepts = true;
				}
			}
			
		/* If it accepts the cargo, set the value to 1, else 0 */
		if (accepts == true)
			{
			industry_list.SetValue(industry,1);
			}
		else
			{
			industry_list.SetValue(industry,0);
			}
		}
		
	/* Only keep the industries that have a value of 1 */
	industry_list.KeepValue(1);
		
	/* Return the list */
	return industry_list;
	}

/**
* Creates a list of suitable towns that can be built in
*/
function Chopper::FindSuitableTown()
	{
	/* Create a list of all towns */
	local town_list = AITownList();
		
	/* For subsidy, remove all towns except subsidy town*/
	if (this.subsidy_town_tiletouse != null)
		{
		/* Cheaty method of replacing the list with one item - first give everything value 0 */
		for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next())
			{
			town_list.SetValue(town,0);
			}
			
		/* Then give the town we want to keep value 1 */
		town_list.SetValue(this.subsidy_town_tiletouse,1);
			
		/*Then remove everything below value 1... */
		town_list.RemoveBelowValue(1);
		}
		
	/* List of towns that will be removed from town_list */
	local towns_to_remove = AIList();
		
	/* Remove any towns that you are allowed to build at from the list */
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next())
		{
		/* Text used to store reasons if we can/can't build there */
		local town_text1 = "";
		local town_text2 = "";
			
		/* "O" means we can build there, "X" means we can't */
		local town_canbuild = "O";
			
		/* Check for towns the player has built at if necessary */
		if (GetSetting("can_build_at_player_towns") == 0)
			{
			if (CheckCompanyBuiltAtTown(0,town) == 1)
				{
				towns_to_remove.AddItem(town,AITown.GetLocation(town));
				town_canbuild = "X";
				town_text1 = "Player has built at " + AITown.GetName(town)
				}			
			else
				{
				town_text1 = "Player hasn't built at " + AITown.GetName(town);
				}			
			}
			
		/* Check for towns Chopper has already built at if necessary */
		if (GetSetting("multiple_stations_per_town") == 0)
			{
			/* Check if we have already built there */
			if (CheckCompanyBuiltAtTown(AICompany.COMPANY_SELF,town) == 1)
				{
				towns_to_remove.AddItem(town,AITown.GetLocation(town));
				town_canbuild = "X";
				town_text2 = "I have built at " + AITown.GetName(town)
				}			
			else
				{
				town_text2 = "I haven't built at " + AITown.GetName(town)
				}
			}
			
		local town_text_middle = "";
		if (town_text1 != "" && town_text2 != "")
			{
			town_text_middle = ", ";
			}
			
		/* Display the list of towns */
		if (town_text1 != "" || town_text2 != "" && GetSetting("debug_info"))
			{
			AILog.Warning("          " + town_canbuild + "     " + town_text1 + town_text_middle + town_text2);
			}
		}
		
	/* Remove towns we can't build at */
	town_list.RemoveList(towns_to_remove);	
		
	/* Update log */
	AILog.Info(" > Generating list of towns I can build at...");
		
	/* Only show the list if extended debug info is on, because it is often quite long */
	if (GetSetting("debug_info"))
		{
		for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next())
			{
			AILog.Warning("         " + AITown.GetName(town));
			}
		}
		
	/* Keep the ones above the min size allowed */
	town_list.Valuate(AITown.GetPopulation);
	town_list.KeepAboveValue(GetSetting("min_town_size"));
		
	/* Only remove towns from the list if there are enough, if there are less than 5 then it would be unfair on the AI */
	if (town_list.Count() > 4)
		{
		/* Only search through the top percentage of population for towns. This percentage increases over time to allow Chopper to eventually build to all towns.  */
		local multiplier = 100/this.town_population_percentage;
		local amount_to_keep = (town_list.Count()/multiplier);
		town_list.KeepTop(amount_to_keep);
		}
		
	/* Return the list of towns */
	return town_list;
	}

/**
 * Find a suitable spot for an airport, walking all towns hoping to find one.
 *  When a town is used, it is marked as such and not re-used.
 */
function Chopper::FindSuitableAirportSpot(town_list, airport_type, center_tile, airport_type_other, cargo)
	{
	/* Size of grid to search for a place around the town */
	local grid_size = 15;
	
	/* Used to store the tile of an existing airport we can use */
	local existing_airport = null;

	/* For smaller heliports we want to force it nearer the center of town */
	/* Bigger stations have a larger grid size, since they will probably not have space near the middle of town */
	
	/* Town controller noise levels affect airport placement*/
	AILog.Info(" > Checking town controlled noise levels")
	if (AIGameSettings.GetValue("economy.station_noise_level") == 1)
		{
		AILog.Info(this.INDENT + "Town controlled noise levels are on");
		}
	else
		{
		AILog.Info(this.INDENT + "Town controlled noise levels are off");
		}
		
	/**
	* If town controlled noise levels are off, then the value from "economy.station_noise_level" is the number of airports the town will allow
	* Otherwise, it's the number of noise. And the noise number is 1,2,3 for heliport, helidepot and helistation respectively
	* If it is off then each is assigned a value of 1, since there is 1 station being built 
	*/
	town_list.Valuate(AITown.GetAllowedNoise);
	if (airport_type == AIAirport.AT_HELIPORT)
		{
		grid_size = 5;
		town_list.RemoveBelowValue(1);
		}
	if (airport_type == AIAirport.AT_HELIDEPOT)
		{
		grid_size = 10;
		if (AIGameSettings.GetValue("economy.station_noise_level") == 1)
			{
			town_list.RemoveBelowValue(2);
			}
		else
			{
			town_list.RemoveBelowValue(1);
			}
		}
	if (airport_type == AIAirport.AT_HELISTATION)
		{
		grid_size = 15;
		if (AIGameSettings.GetValue("economy.station_noise_level") == 1)
			{
			town_list.RemoveBelowValue(3);
			}
		else
			{
			town_list.RemoveBelowValue(1);
			}
		}
		
	/* Sort Economically or Aesthetically */
	if (AIGameSettings.GetValue("concern") == 1)
		{
		town_list.Valuate(AITown.GetPopulation);
		}
	else
		{
		town_list.Valuate(AIBase.RandItem);
		}
	
	/* Sort the list */
	town_list.Sort(AIAbstractList.SORT_BY_VALUE,false);
	
	/* The position and coverage of the airport */
	local airport_x, airport_y, airport_rad;
	airport_x = AIAirport.GetAirportWidth(airport_type);
	airport_y = AIAirport.GetAirportHeight(airport_type);
	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);
	
	if (center_tile == 0)
		{
		AILog.Info(" > Deciding on which town to build first station at...");
		}
	else
		{
		AILog.Info(" > Deciding on which town to build second station at...");
		}
	
	/* Faster plane speed = further apart stations */
	if (GetSetting("use_plane_speed_factor") == 1)
		{
		local plane_speed_factor = AIGameSettings.GetValue("vehicle.plane_speed");
		AILog.Info(" > Taking into account plane speed factor: 1/" + plane_speed_factor);
		}
	
	/* Loop through all towns */
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next())
		{
		AILog.Info(" > Checking town " + AITown.GetName(town) + "...");
		
		/* Don't make this a CPU hog */
		Sleep(1);

		/* Get the tile the town is on */
		local tile = AITown.GetLocation(town);
		
		
		/* Check if there is already a suitable airport in the town that we can use */
		/* Don't check early on */
		if (this.UseEarlyValues())
			{
			existing_airport = this.FindExistingAirport_Town(town,airport_type,cargo,center_tile);
			if (existing_airport != null)
				{
				return existing_airport;
				}
			}
		
		/* Create a 30x30 grid around the core of the town and see if we can find a spot for a small airport */
		local list = AITileList();
		
		/* XXX -- We assume we are more than "grid_size"tiles away from the border! */
		list.AddRectangle(tile - AIMap.GetTileIndex(grid_size, grid_size), tile + AIMap.GetTileIndex(grid_size, grid_size));
		
		/* Only keep the tiles where there is enough space to build an airport, so even though in debug only one tile is marked with a sign, that sign represents where the top corner of the airport would be! */
		list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
		list.KeepValue(1);
		
		if (center_tile != 0) {
			/* If we have a tile defined, we don't want to be within min_station_dis tiles of this tile */
			list.Valuate(AITile.GetDistanceSquareToTile, center_tile);
			list.KeepBetweenValue(this.min_station_dis*this.min_station_dis,this.max_station_dis*this.max_station_dis);
			
			/* Set it back them all back to 1s */
			list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
			
			/* Mark areas as taken */
			if (airport_type_other == AIAirport.AT_HELIPORT)
				{
				list.SetValue(center_tile + AIMap.GetTileIndex(0,0),0);
				}
			if (airport_type_other == AIAirport.AT_HELIDEPOT)
				{
				list.SetValue(center_tile + AIMap.GetTileIndex(0,0),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(1,0),0);

				list.SetValue(center_tile + AIMap.GetTileIndex(0,1),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(1,1),0);
				}
			if (airport_type_other == AIAirport.AT_HELISTATION)
				{
				list.SetValue(center_tile + AIMap.GetTileIndex(0,0),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(1,0),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(2,0),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(3,0),0);
				
				list.SetValue(center_tile + AIMap.GetTileIndex(0,1),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(1,1),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(2,1),0);
				list.SetValue(center_tile + AIMap.GetTileIndex(3,1),0);
				}
			
			/* Remove all those taken areas from the search area */
			list.RemoveValue(0);
				
			/* If the setting is enabled, it will build longer routes for faster planes. This though means that if the setting is changed from 1/1 to 1/4 mid game, some routes may become unprofitable! */
			local max_dis_divider = 4;
			if (GetSetting("use_plane_speed_factor") == 1)
				{
				local plane_speed_factor = AIGameSettings.GetValue("vehicle.plane_speed");
				max_dis_divider = plane_speed_factor;
				}
			
			/* Remove all stations that are too far away */
			list.RemoveAboveValue(this.max_station_dis*this.max_station_dis*(4/max_dis_divider));
			}
		
		
		/* Only keep the tiles within the influence area of the town */
		//list.Valuate(AITile.IsWithinTownInfluence, town);
		list.Valuate(AITile.GetClosestTown);
		//list.KeepValue(1);
		
		/* Sort on acceptance, remove places that don't have acceptance */
		list.Valuate(AITile.GetCargoAcceptance, cargo, airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(10);

		/* Stop it from building the station in the wrong town! */
		list.Valuate(AITile.GetClosestTown);
		list.KeepValue(town);
		
		/* Also remove places that don't produce passengers */
		/* Cargos and foods don't need to be checked, because they don't need to get stuff from the town, they are a one way trip */
		if (AICargo.HasCargoClass(cargo,AICargo.CC_PASSENGERS) || AICargo.HasCargoClass(cargo,AICargo.CC_MAIL))
			{
			list.Valuate(AITile.GetCargoProduction, cargo, airport_x, airport_y, airport_rad);
			list.RemoveBelowValue(10);
			}
		
		/* Sort the list */
		list.Sort(AIList.SORT_BY_VALUE,false);
		
		/* Create signs in increasing number, number 1 being the best spot, and the last sign being the worst spot */
		if (GetSetting("debug_signs") == 1)
			{
			local count = 1;
			for (local a_tile = list.Begin(); list.HasNext(); a_tile = list.Next())
				{
				AISign.BuildSign(a_tile,count);
				count += 1;
				}
			}

		/* If the list is empty, there are no suitable places, so give up */
		if (list.Count() == 0) continue;
		
		/* Loop through all the tiles and see if we can build the airport */
		{
		/* Switch to testing mode for testing of building airport */
		local test = AITestMode();
		local good_tile = 0;
		for (tile = list.Begin(); list.HasNext(); tile = list.Next())
			{
			Sleep(1);
				
			/* Build the airport in testing mode */
			local airport_test = AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)
				
			/* Display the noise that is allowed */
			AILog.Info(" > Checking allowed noise");
			AILog.Info(this.INDENT + "Amount of allowed noise: " + AITown.GetAllowedNoise(town));
				
			local noise_increase = AIAirport.GetNoiseLevelIncrease(tile, airport_type);
				
			AILog.Info(this.INDENT + "Building an airport here would produce noise level: " + noise_increase);
				
			if (noise_increase > AITown.GetAllowedNoise(town))
				{
				AILog.Info(this.INDENT + "Cannot build airport here due to noise concerns");
				continue;
				}
			else
				{
				AILog.Info(this.INDENT + "Noise level is acceptable");
				}
				
			if (AIError.GetLastError() == AIError.ERR_LOCAL_AUTHORITY_REFUSES)
				{
				AILog.Error("Local authority won't allow an airport to be built");
				//TODO: Plant trees and retry!
				break;
				}
				
				
			/* If the airport could not be built... */
			if (!airport_test)
				{
				AILog.Info(this.INDENT + "Could not build airport: " + AIError.GetLastErrorString());
				
				/* If it was from not being flat land, flatten the land */
				if (AIError.GetLastError() == AIError.ERR_FLAT_LAND_REQUIRED)
					{
					AILog.Info(" > Land isn't flat, checking if flattening will help...");
					local exec = AIExecMode();
					this.FlattenForAirport(tile, airport_x, airport_y);

					Sleep(1);
					
					/* Back to test mode for the airport */
					local test2 = AITestMode();
					
					/* Now try and build it */
					airport_test = AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW);
					}
				}
				
			/* If it do */
			if (!airport_test)
				{
				continue;
				}
			
			good_tile = tile;
			break;
			}
			/* Did we found a place to build the airport on? */
		if (good_tile == 0) continue;
		}
		

		//AILog.Info("Found a good spot for an airport in town " + AITown.GetName(town) + " at tile " + tile);
		
		AILog.Info(this.INDENT + "Found a good spot for an airport in town " + AITown.GetName(AITile.GetClosestTown(tile)) + " at tile " + tile);
		
		if (GetSetting("debug_signs") == 1)
			{
			if (airport_type == AIAirport.AT_HELIPORT)
				{
				AISign.BuildSign(tile + AIMap.GetTileIndex(0,0),"X");
				}
			if (airport_type == AIAirport.AT_HELIDEPOT)
				{
				AISign.BuildSign(tile + AIMap.GetTileIndex(0,0),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(1,0),"X");
				
				AISign.BuildSign(tile + AIMap.GetTileIndex(0,1),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(1,1),"X");
				}
			if (airport_type == AIAirport.AT_HELISTATION)
				{
				AISign.BuildSign(tile + AIMap.GetTileIndex(0,0),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(1,0),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(2,0),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(3,0),"X");
				
				AISign.BuildSign(tile + AIMap.GetTileIndex(0,1),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(1,1),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(2,1),"X");
				AISign.BuildSign(tile + AIMap.GetTileIndex(3,1),"X");
				}
			}
		
		
		/* Mark the town as used, so we don't use it again */
		////this.towns_used.AddItem(town, tile);

		return tile;
	}
	
	if (this.subsidy_town_tiletouse != null)
		{
		AILog.Info(this.INDENT + "Couldn't find a suitable spot to build the airport at " + AITown.GetName(this.subsidy_town_tiletouse));
		}
	else
		{
		AILog.Info(this.INDENT + "Couldn't find a suitable town to build an airport in");
		}
	return -1;
	}

/**
* Starting with tile as the corner, this flattens an area of land of "width" and "height"
* Doesn't always seem to work 100% though, but it usually helps... =)
*/
function Chopper::FlattenForAirport(tile, width, height)
	{
	/* It will probably cost a few thousand */
	this.GetMoney(2000);
	if (!(this.HasMoney(2000)))
		{
		AILog.Warning("Couldn't get enough money to flatten land");
		return -1;
		}
		
	/* List of all the tiles */
	local tile_list = AITileList();
	tile_list.AddRectangle(tile,tile + AIMap.GetTileIndex(width-1, height-1));
		
	/* minimum and maximum height of tiles */
	local tile_height_max = 0;
	local tile_height_min = 999;
	local tile_height_flatten = 999;
		
	/* Get max and min height of tiles */
	for (local t = tile_list.Begin(); tile_list.HasNext(); t = tile_list.Next())
		{
		/* Show = sign on places where Chopper will flatten */
		if (GetSetting("debug_signs") == 1)
			{
			AISign.BuildSign(t, "=");
			}
			
		if (AITile.GetMaxHeight(t) > tile_height_max)
			{
			tile_height_max = AITile.GetMaxHeight(t);
			}
			
		if (AITile.GetMinHeight(t) < tile_height_min)
			{
			tile_height_min = AITile.GetMinHeight(t);
			}
		}
		
	/* Zzzz... */
	Sleep(1);
		
	/* Get difference between max and min */
	local tile_difference = tile_height_max - tile_height_min;
		
	if (tile_difference > 2)
		{
		/* If tile difference is too big, then we cannot test flatting, because we can only flatten one depth at a time */
		AILog.Info(this.INDENT + "It's not worth trying to flatten this area");
		return -1;
		}
	else
		{
		/* Builds a sign saying flatten on the top tile where it might flatten */
		if (GetSetting("debug_signs") == 1)
			{
			AISign.BuildSign(tile, "Flatten");
			}
			
		/* Work out what height we should flatten to */
		tile_height_flatten = ((tile_height_max+tile_height_min)/2);
			
		/* If testing succeeds, then it will  be told it should lower the land */
		local shall_i_lower = true;
			
		/* Loop through all tiles in the lust */
		for (local t = tile_list.Begin(); tile_list.HasNext(); t = tile_list.Next())
			{
			/* If any of the tiles are above the height we want... */
			if (AITile.GetMaxHeight(t) > tile_height_flatten)
				{
				/* ... test if we can flatten them */
				local test = AITestMode();
				local test_place = AITile.LowerTile(t, AITile.GetSlope(t));
					
				/* If we can't flatten a tile, then return that it was unsuccessful */
				if (!(test_place))
					{
					shall_i_lower = false;
					AILog.Info(this.INDENT + "Can't flatten this area: " + AIError.GetLastErrorString());
					return -2;
					}
				}
			}
			
		/* If all tiles were able to be flattened, now we loop through and actually flatten them */
		if (shall_i_lower == true)
			{
			/* loop... */
			for (local t = tile_list.Begin(); tile_list.HasNext(); t = tile_list.Next())
				{
				/* Check again, we only want to lower the ones that are too high */
				for (local rep = 0; rep < 1; rep += 1)
					{
					/* Get the ones that are too high */
					if (AITile.GetMaxHeight(t) > tile_height_flatten)
						{
						/* Put us into execution mode, so stuff actually happens */
						local exec = AIExecMode();
							
						/* Flatten the tile for real this time */
						local test_place = AITile.LowerTile(t, AITile.GetSlope(t));
							
						/* If for whatever reason it didn't work, give up (e.g. something else was built there before we could finish) */
						if (!(test_place))
							{
							AILog.Error("Could not flatten");
							return -3;
							}
						}
					}
				}
			AILog.Info(this.INDENT + "Successfully flattened the land");
			}
		else
			{
			AILog.Error(this.INDENT + "Land is already flat!");
			}
		}
	}

/**
* Checks planes and stations
*/
function Chopper::ManageAirRoutes()
	{
	AILog.Info(" > Checking bank balance...");
	this.ManageMoney();
	
	/* Update log */
	AILog.Info(" > Checking vehicle profits...");
		
	/* Create a list of all our vehicles */
	local list = AIVehicleList();
	list.Valuate(AIVehicle.GetAge);
		

		local profit_threshold_lastyear;
		local profit_threshold_thisyear;
		local years_to_make_difference
		if (this.UseEarlyValues())
			{
			profit_threshold_lastyear = this.PROFIT_THRESHOLD_LASTYEAR_EARLY;
			profit_threshold_thisyear = this.PROFIT_THRESHOLD_THISYEAR_EARLY;
			years_to_make_difference = this.YEARS_TO_MAKE_DIFFERENCE_EARLY;
			}
		else
			{
			profit_threshold_lastyear = this.PROFIT_THRESHOLD_LASTYEAR;
			profit_threshold_thisyear = this.PROFIT_THRESHOLD_THISYEAR;
			years_to_make_difference = this.YEARS_TO_MAKE_DIFFERENCE;
			}
		
	/* Give the plane at least 2 years to make a difference */
	list.KeepAboveValue(365 * 2);
	list.Valuate(AIVehicle.GetProfitLastYear);
		
	for (local i = list.Begin(); list.HasNext(); i = list.Next())
		{

		
		local profit = list.GetValue(i);
		/* Profit last year and this year bad? Let's sell the vehicle */
		if (profit < profit_threshold_lastyear && AIVehicle.GetProfitThisYear(i) < profit_threshold_thisyear) 
			{
			/* Send the vehicle to depot if we didn't do so yet */
			if (!vehicle_to_depot.rawin(i) || vehicle_to_depot.rawget(i) != true)
				{
				AILog.Info(this.INDENT + "Sending " + i + " to depot as profit is: " + profit + " / " + AIVehicle.GetProfitThisYear(i));
				AIVehicle.SendVehicleToDepot(i);
				vehicle_to_depot.rawset(i, true);
				}
			}
		/* Try to sell it over and over till it really is in the depot */
		if (vehicle_to_depot.rawin(i) && vehicle_to_depot.rawget(i) == true)
			{
			if (AIVehicle.SellVehicle(i))
				{
				AILog.Info(this.INDENT + "Selling " + i + " as it finally is in a depot.");
				vehicle_to_depot.rawdelete(i);
				}
			}
		}
		
	/* Remove any unused stations that are older than one year */
	AILog.Info(" > Remove any unused stations older than " + this.STATION_REMOVE_AGE + " year(s)");
	ManageStations_RemoveUnused(this.STATION_REMOVE_AGE);
	
	AILog.Info(" > Checking for airports that need upgrading...");
	ManageStations_Upgrade();
	
	/* Don't try to add planes when we are short on cash */
	if (!this.HasMoney(50000)) return;

	/* Update log */
	AILog.Info(" > Checking routes to see if more aircraft are needed...");
	local cargo_list = AICargoList();
	for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
		{
		ManageAirRoutes_CheckCargos(cargo);
		}
		
	/* Require half a million before autoreplacing */
	if (!this.HasMoney(500000)) return;
		
	AILog.Info(" > Checking for vehicles that need upgrading...");
	for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
		{
		ManageAirRoutes_AutoReplace(cargo);
		}
	}

/**
* Returns whether to use earlier values
* For example, early in the game when there are only a few vehicles, profit is primary
* And we don't want to go deleting routes that aren't making more than X amount of money if they're making a profit
* However once we have a steady profit the not so profitable routes can be sold to get money to try and find even better routes
*/
function Chopper::UseEarlyValues()
	{
	local vehicle_list = AIVehicleList();
	local vehicle_num = vehicle_list.Count();
	return (vehicle_num <= 4)
	}
	
/**
* Upgrades all vehicles to the best ones possible, if money is available
*/
function Chopper::ManageAirRoutes_AutoReplace(cargo)
	{
	/* Create a list of vehicles  */
	local vehicle_list = AIVehicleList();
		
	/* Keep the ones that take "cargo" */
	vehicle_list.Valuate(AIVehicle.GetCapacity,cargo);
	vehicle_list.KeepAboveValue(0);
		
	/* Loop through all the vehicles */
	for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next())
		{
		/* If the cargo we are checking is mail */
		if (cargo == this.mail_cargo_id)
			{
			/* And if it can also take passengers */
			if (AIVehicle.GetCapacity(vehicle,this.passenger_cargo_id) > 0)
				{
				/* Don't autoreplace this, because we don't want to replace a passenger and mail vehicle with just a mail vehicle */
				continue;
				}
			}
			
		/* Get the engine type */
		local engine_existing = AIVehicle.GetEngineType(vehicle);
			
		/* Get the best engine possible for this cargo */
		local engine_best = this.EngineGetForCargo(AIVehicle.VT_AIR,AIAirport.PT_HELICOPTER,cargo)
			
		/* Found a vehicle that can be upgraded? */
		if (engine_existing != engine_best)
			{
			/* Set all engines of that type to autoreplace */
			AIGroup.SetAutoReplace(AIGroup.GROUP_ALL,engine_existing,engine_best);
			}
		}
	}
	
/**
* Removes stations that have no vehicles visiting them and are old
*/
function Chopper::ManageStations_RemoveUnused(age)
	{
	/* Create a list of all stations we own that are airports */
	local list = AIStationList(AIStation.STATION_AIRPORT);
		
	/* Loop through all the stations, "i" being each station ID */
	for (local i = list.Begin(); list.HasNext(); i = list.Next())
		{
		/* Create a list of all vehicles that go to this station */
		local list2 = AIVehicleList_Station(i);
			
		/* Check if no vehicles go to the station */
		if (list2.Count() == 0)
			{
			/* Variable that controls if it is deleted */
			local delete_station = false;
				
			if (improvise_station_age_check == false)
				{
				/* Check how old the station is first. If it is not very old, then don't delete it, because if it is deleted the AI can sometimes get into a loop of building and deleting in the same place, wasting lots of money! */ //AIBaseStation
				/* Check if it's over a year old */
				local station_construction_year = AIDate.GetYear(AIStation.GetConstructionDate(i));
				if ((AIDate.GetYear(AIDate.GetCurrentDate()) - station_construction_year) > age)
					{
					delete_station = true;
					}
				}
			else
				{
				/* If this station is not in the list of ages, add it */
				if (!(station_age_list.HasItem(i)))
					{
					/* Give it an initial age of 0 */
					station_age_list.AddItem(i,0);
					}
				else
					{
					/* If it already exists in the list, get its age */
					local current_age = station_age_list.GetValue(i);
						
					/* Then increase its age by one */
					station_age_list.SetValue(i,current_age + 1);
						
					if ((current_age + 1) > 20)
						{
						delete_station = true;
						}
					}
				}
				
			if (this.IsAirportChopperCentral(i))
				{
				delete_station = false;
				}
				
			if (delete_station)
				{
				/* Make sure we're in execution mode */
				local exec = AIExecMode();
					
				AILog.Info(this.INDENT + "Removing " + AIStation.GetName(i) + " as nobody serves it anymore and it's over " + this.STATION_REMOVE_AGE + " year(s) old.");
				local removed = AIAirport.RemoveAirport(AIStation.GetLocation(i));
				if (!removed)
					{
					AILog.Error("Airport could not be removed: " + AIError.GetLastErrorString());
					}
				}
				
			/* Continue to the next in the loop, because there are no vehicles to check */
			continue;
			}
		else
			{
			/* If the station does have vehicles going to it, and if the improvise station age check is on */
			if (improvise_station_age_check == true)
				{
				/* If the station is in the list of ones that will eventually be deleted */
				if (station_age_list.HasItem(i))
					{
					/* Remove it from the list as it is now in use! */
					station_age_list.RemoveItem(i);
					}
				}
			}
		}
	}

/**
* Upgrades small and large (city) airports to helistations
*/
function Chopper::ManageStations_Upgrade()
	{
	this.GetMoney(10000);
	if (!(this.HasMoney(10000)))
		{
		/* Not got enough monies */
		return -1;
		}
	
	if (!(AIAirport.IsValidAirportType(AIAirport.AT_HELISTATION)))
		{
		AILog.Info(this.INDENT + "No newer airport to upgrade to");
		/* Helistation is not yet available */
		return 1;
		}
	
	/* Create a list of all stations we own that are airports */
	local list = AIStationList(AIStation.STATION_AIRPORT);

	/* Get the hangar of the central airport */
	local destination = AIAirport.GetHangarOfAirport(this.GetCentralAirportTile());
	
	/* Loop through all the stations, "i" being each station ID */
	for (local i = list.Begin(); list.HasNext(); i = list.Next())
		{
		if (this.IsAirportChopperCentral(i))
			{
			/* Don't try and upgrade Chopper Central (TODO: make Chopper Central upgrade - don't let helicopters use Chopper Central) */
			continue;
			}
		
		local type = AIAirport.GetAirportType(AIStation.GetLocation(i));
		/* Only search the small and large (city) airports */
		if (type == AIAirport.AT_SMALL || type == AIAirport.AT_LARGE)
			{
			AILog.Info(this.INDENT + "Found an airport to upgrade: " + AIStation.GetName(i));
			
			/* Get all the vehicles that go to this station */
			local vehicle_list = AIVehicleList_Station(i);
			
			/* Loop through all the vehicles */
			for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next())
				{
				/* This stops the order being assigned over and over */
				if (AIOrder.GetOrderCount(vehicle) == 2)
					{
					/* Tell them to go to Chopper Central and stop in the depot */
					AIOrder.AppendOrder(vehicle,destination,AIOrder.AIOF_STOP_IN_DEPOT);
					
					/* Skip to order 2, which should be the one above that we just appended! */
					AIOrder.SkipToOrder(vehicle,2);
					}
				}
			/* All vehicles going to that station have been sent to go straight to Chopper Central depot and stop there */
			
			/* Wait a bit to let the aircraft clear */
			Sleep(20);
			
			/* Has it been removed? */
			local remove_success = false;
			
			local tile = AIStation.GetLocation(i);
			
			local airport_width = AIAirport.GetAirportWidth(AIAirport.AT_HELISTATION);
			local airport_height = AIAirport.GetAirportHeight(AIAirport.AT_HELISTATION);
			local airport_radius = AIAirport.GetAirportCoverageRadius(AIAirport.AT_HELISTATION);
			
			/* Remeber the tile to build the airport on */
			
			
			local tile_list = AITileList();
			tile_list.AddRectangle(tile,tile + AIMap.GetTileIndex(AIAirport.GetAirportWidth(type)-airport_width,AIAirport.GetAirportHeight(type)-airport_height));
			/*
			tile_list.Valuate(AITile.IsBuildableRectangle,airport_width,airport_height);
			tile_list.KeepValue(1);
			*/
			
			/* Find the spot that accepts and produces the most cargo, because we want the new smaller airport to be in the best place possible */
			/* The value if the tiles is how many surrounding tiles accept/produce any cargo */
			/* The highest value is the best */
			/* Loop through all tiles */
			for (local i_tile = tile_list.Begin(); tile_list.HasNext(); i_tile = tile_list.Next())
				{
				/* First make sure all values are at 0 */
				tile_list.SetValue(i_tile,0);
				
				/* Then loop through all cargos */
				local cargo_list = AICargoList();
				for (local i_cargo = cargo_list.Begin(); cargo_list.HasNext(); i_cargo = cargo_list.Next())
					{
					/* Get the existing value */
					local old_value = tile_list.GetValue(i_tile);
					local new_value = 0;
					/* Work out how much it accepts and produces of this cargo */
					new_value += AITile.GetCargoAcceptance(i_tile,i_cargo,airport_width,airport_height,airport_radius);
					new_value += AITile.GetCargoProduction(i_tile,i_cargo,airport_width,airport_height,airport_radius);
					/* Add the new value onto the old value */
					tile_list.SetValue(i_tile,old_value+new_value);
					}
				/* Don't hog CPU, since this loop takes a while */
				Sleep(1);
				}
			/* The tile_list is now valuated by which accepts and produces the most, so we want to sort it descending */
			tile_list.Sort(AIAbstractList.SORT_BY_VALUE,false);
			
			/* Make a list of tiles that cannot be built on for the airport */ //ALL tiles should be free because the airport has just gone. Hopefully no one will build there really fast!
			/**
			local tile_list_takeaway = AITileList();
			for (local i_tile = tile_list.Begin(); tile_list.HasNext(); i_tile = tile_list.Next())
				{
				if (!(AITile.IsBuildableRectangle(i_tile,airport_width,airport_height)))
					{
					AISign.BuildSign(i_tile,"NO");
					tile_list_takeaway.AddTile(i_tile);
					}
				}
			tile_list.RemoveList(tile_list_takeaway);
			*/
			for (local i_tile = tile_list.Begin(); tile_list.HasNext(); i_tile = tile_list.Next())
				{
				AISign.BuildSign(i_tile,tile_list.GetValue(i_tile));
				}

			
			/* Now we actually destroy the station */
			local exec = AIExecMode();
			
			local tile = AIStation.GetLocation(i);
			
			/* Try and destroy the station */
			for (local j = 0; j < 100; j++)
				{
				/* Try and remove the airport */
				if (remove_success == false)
					{
					remove_success = AIAirport.RemoveAirport(tile);
					AILog.Warning(AIError.GetLastErrorString());
					j = 10;
					if (remove_success == false)
						{
						/* Wait a bit before trying again if it failed to give the aircraft time to clear */
						Sleep(50);
						}
					}
				}
				
			if (remove_success == false)
				{
				/* Even after all these attempts, it failed to remove the airport */
				AILog.Info(this.INDENT + "Failed to remove airport");
				continue;
				}
			
			this.ManageStations_UpgradeContinued(tile_list,vehicle_list,i);
			}
		}
	}

/**
* Second part of above fuction
*/
function Chopper::ManageStations_UpgradeContinued(tile_list,vehicle_list,join)
	{
	/* Execution mode */
	local exec = AIExecMode();
	
	/* Loop through all the tiles */
	local airport_tile;
	for (local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next())
		{
		/* Attempt to build the airport */
		airport_tile = AIAirport.BuildAirport(tile,AIAirport.AT_HELISTATION,join);
		AILog.Warning(AIError.GetLastErrorString());
		if (airport_tile)
			{
			break;
			}
		}
	
	/* Build it with the same ID as the last airport */
	if (!(airport_tile))
		{
		/* Failed to rebuild airport */
		AILog.Error("Failed to rebuild airport! oh noez :(");
		//TODO: Sell aircraft going to this airport
		}
	else
		{
		/* Airport was replaced! */
		/* Better send the aircraft off again */
		/* Loop through all the vehicles */
		for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next())
			{
			/* Go back to first order */
			AIOrder.SkipToOrder(vehicle,0);
			
			/* Remove the stop order */
			AIOrder.RemoveOrder(vehicle,2);
			
			/* Start it if it was stopped */
			if (AIVehicle.IsStoppedInDepot(vehicle))
				{
				AIVehicle.StartStopVehicle(vehicle);
				}
			}
		}
	}
	
function Chopper::ManageMoney()
	{
	/* If we have minus monies, take out a loan else we'll be declared bankrupt */
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < 0)
		{
		/* Take out one more loan interval */
		AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
		AILog.Warning(this.INDENT + "Taking out a loan to stop going bankrupt!");
		}
	}
	
/**
* Get the tile that Chopper Central is on
*/
function Chopper::GetCentralAirportTile()
	{
	/* Create a list of all stations we own that are airports */
	local list = AIStationList(AIStation.STATION_AIRPORT);
	
	/* Loop through all the stations, "i" being each station ID */
	for (local i = list.Begin(); list.HasNext(); i = list.Next())
		{
		if (this.IsAirportChopperCentral(i))
			{
			return AIStation.GetLocation(i);
			}
		}
	}
	
/**
* Builds the central airport, used to build the first few aircraft if no other airports have hangars
* Also used to send helicopters to whilst upgrading airports
*/
function Chopper::BuildCentralAirport(town_list)
	{
	town_list.Sort(AIAbstractList.SORT_BY_VALUE,true);
	
	/* Create lists to store the airports that can be built */
	local airport_1_type_list = AIList();
	
	/* These will store the chosen airport type */
	local airport_1_type = null;
	
	/* Populate the first list, the value is used to determine which should be attempted to be built first (0 = first, 4 = last) */
	/* We try helistation first because we want an airport that can take a lot of air traffic */
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELISTATION))
		{
		airport_1_type_list.AddItem(AIAirport.AT_HELISTATION,1);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_HELIDEPOT))
		{
		airport_1_type_list.AddItem(AIAirport.AT_HELIDEPOT,0);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_SMALL))
		{
		airport_1_type_list.AddItem(AIAirport.AT_SMALL,2);
		}
	if (AIAirport.IsValidAirportType(AIAirport.AT_LARGE))
		{
		airport_1_type_list.AddItem(AIAirport.AT_LARGE,3);
		}

	/* tile_1 stores the position of the first airport */
	local tile_1 = null;
	
	/* Get some money to work with */
	this.GetMoney(50000);
	
	/* Sort the lists ascending */
	airport_1_type_list.Sort(AIAbstractList.SORT_BY_VALUE,true);
	
	/* Loop through the first types of airport */
	for (airport_1_type = airport_1_type_list.Begin(); airport_1_type_list.HasNext(); airport_1_type = airport_1_type_list.Next())
		{
		AILog.Info(" > Attempting to find a suitable spot for airport type: " + AirportTypeToString(airport_1_type));
		tile_1 = this.FindSuitableAirportSpot(town_list, airport_1_type, 0, 0,this.passenger_cargo_id);
		if (tile_1 < 0)
			{
			AILog.Info(this.INDENT + "Couldn't find a spot for: " + AirportTypeToString(airport_1_type));
			continue;
			}
		else
			{
			AILog.Info(this.INDENT + "Found a spot for: " + AirportTypeToString(airport_1_type));
			break;
			}
		}
	
	/* If a space wasn't found... */
	if (tile_1 < 0)
		{
			{
			/* Found no space for any airport in any town */
			AILog.Error(this.INDENT + "Couldn't find any space for the central airport!");
			return -1;
			}
		}

	/* Execution mode */
	local exec = AIExecMode();
	
	/* Build the airports for real */
	if (!(this.CheckIfOurStationAtTile(tile_1)))
		{
		if (!AIAirport.BuildAirport(tile_1, airport_1_type, AIStation.STATION_NEW))
			{
			AILog.Error(this.INDENT + "Failed to build central airport!");
			return -1;
			}
		}
		
	/* Name the company */
	if (!AIStation.SetName(AIStation.GetStationID(tile_1),"Chopper Central"))
		{
		/* Loop through, if name is taken increase number */
		local i = 2;
		while (!AIStation.SetName(AIStation.GetStationID(tile_1),"Chopper Central #" + i))
			{
			i+=1;
			}
		}
	
	/* Find a space for the HQ */
	local tile_list = AITileList();
	local grid_size = 10;
	tile_list.AddRectangle(tile_1 - AIMap.GetTileIndex(grid_size, grid_size), tile_1 + AIMap.GetTileIndex(grid_size, grid_size));
	tile_list.Valuate(AITile.IsBuildableRectangle,2,2);
	tile_list.KeepValue(1);
	tile_list.Valuate(AIMap.DistanceSquare,tile_1);
	tile_list.Sort(AIAbstractList.SORT_BY_VALUE,true);
	local test = AIExecMode();
	local good_tile = 0;
	AILog.Info(" > Building HQ");
	for (local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next())
		{
		/* Don't hog CPU */
		Sleep(1);
			
		/* Build the airport in testing mode */
		local hq_test = AICompany.BuildCompanyHQ(tile);
			
		/* If the airport could not be built... */
		if (!hq_test)
			{
			/* Show why it couldn't be built */
			AILog.Warning(this.INDENT + "Can't build HQ, reason: " + AIError.GetLastErrorString());

			/* If it was from not being flat land, flatten the land */
			if (AIError.GetLastError() == AIError.ERR_FLAT_LAND_REQUIRED)
				{
				AILog.Info(" > Land isn't flat, checking if flattening will help...");
				local exec = AIExecMode();
				this.FlattenForAirport(tile, 2 2);
				Sleep(1);
					
				/* Back to test mode for the airport */
				local test2 = AIExecMode();
					
				/* Now try and build it */
				local hq_test = AICompany.BuildCompanyHQ(tile);
				}
			}
			
		/* If it failed, try next in loop */
		if (!hq_test)
			{
			continue;
			}
		else
			{
			break;
			}
		}
	}

/**
* Check if it is Chopper Central
*/
function Chopper::IsAirportChopperCentral(station_id)
	{
	if (AIStation.IsValidStation(station_id))
		{
		/* It is ours */
		local station_name = AIStation.GetName(station_id);
		if (station_name == "Chopper Central")
			{
			return true;
			}
		
		/* I doubt anyone will be running more than 10 Chopper AIs... */
		for (local i = 0; i < 10; i++ )
			{
			if (station_name == "Chopper Central #" + i)
				{
				/* It has the central name */
				return true;
				}
			}
		/* It does not have the central name */
		return false;
		}
	else
		{
		/* It is not ours */
		return false;
		}
	}
	
/**
* Adds new vehicles to routes with too much cargo
*/
function Chopper::ManageAirRoutes_CheckCargos(cargo)
	{
	/* Create a list of all stations we own that are airports */
	local list = AIStationList(AIStation.STATION_AIRPORT);
	list.Valuate(AIStation.GetCargoWaiting, cargo);
		
	/* We are checking for stations that have too much cargo */
	list.KeepAboveValue(250);
		
	/* Loop through all the stations, "i" being each station ID */
	for (local i = list.Begin(); list.HasNext(); i = list.Next())
		{
		/* Create a list of all vehicles that go to this station */
		local list2 = AIVehicleList_Station(i);
			
		/* No point if there are no vehicles */
		if (list2.Count() != 0) continue;
			
		/* Find the youngest vehicle that is going to this station */
		list2.Valuate(AIVehicle.GetAge);
		list2.Sort(AIAbstractList.SORT_BY_VALUE,true);
		local v = list2.Begin();
			
		/* Work out the distance of the route */
		local tile_1 = AIOrder.GetOrderDestination(v,0);
		local tile_2 = AIOrder.GetOrderDestination(v,1);
		local dist = AIMap.DistanceManhattan(tile_1,tile_2);
			
		/* Do not build a new vehicle if we bought a new one in the last "dist" days */
		list2.KeepBelowValue(dist);
			
		/* Update log */ //AIBaseStation
		AILog.Info(this.INDENT +  AIStation.GetName(AIStation.GetStationID(i)) + " has too much " + AICargo.GetCargoLabel(cargo));
			
		/* Make sure we have enough money */
		this.GetMoney(200000);
			
			
		/* Build an aircraft that goes from 1 to 2 and refit it to cargo */
		if (cargo == this.passenger_cargo_id || cargo == this.mail_cargo_id)
			{
			/* If it is passenger of mail, it does not full load at first station (argument 4) */
			this.BuildAircraft(tile_1, tile_2, cargo, false);
			}
		else	
			{
			/* If it is another cargo, e.g. coal or goods or whatever, then full load at first station (argument 4) */
			this.BuildAircraft(tile_1, tile_2, cargo, true);
			}
		}
	}

/**
* Handles events, such as accepting new vehicle previews
*/
function Chopper::HandleEvents()
	{
	while (AIEventController.IsEventWaiting())
		{
		local e = AIEventController.GetNextEvent();
		switch (e.GetEventType())
			{
			case AIEvent.AI_ET_VEHICLE_CRASHED:
				{
				local ec = AIEventVehicleCrashed.Convert(e);
				local v = ec.GetVehicleID();
				AILog.Info("We have a crashed vehicle (" + v + "), buying a new one as replacement");
				this.BuildAircraft(AIOrder.GetOrderDestination(v,0), AIOrder.GetOrderDestination(v,1), AIEngine.GetCargoType(AIVehicle.GetEngineType(v)),false);
				} 
			break;
				
			/* Check out the subsidy offers */
			case AIEvent.AI_ET_SUBSIDY_OFFER:
				{
				AILog.Info(" > Checking if I can attempt subsidies...");
				if (this.attempt_subsidies == false)
					{
					AILog.Info(this.INDENT + "There is a subsidy, but I will not attempt it because the function does not exist in this revision!");
					break;
					}
				else
					{
					AILog.Info(this.INDENT + "Excellent, I'm allowed to attempt subsidies!");
					}
					
				AILog.Info(" > Deciding whether to pursue subsidy...");
				if (AIBase.RandRange(100) > ((GetSetting("subsidy_chance")/4)*100))
					{
					AILog.Info(this.INDENT + "Decided not to do it... :(");
					break;
					}
				else
					{
					AILog.Info(this.INDENT + "Decided to pursue it");
					}
				local subsidy_offer = AIEventSubsidyOffer.Convert(e);
				local subsidy_id = subsidy_offer.GetSubsidyID();
					
				AILog.Info(" > Check if subsidy is relevent to my interests...");
				if (AISubsidy.DestinationIsTown(subsidy_id))
					{
					AILog.Info(this.INDENT + "Excellent, it's a passenger subsidy!");
						
					/* Use variables to pass the two towns */
					this.subsidy_town_1 = AISubsidy.GetSource(subsidy_id);
					this.subsidy_town_2 = AISubsidy.GetDestination(subsidy_id);
					this.subsidy_town_tiletouse = this.subsidy_town_1//this is set because this variable is used to check if subsidy values are being passed, so it just has to be anything other than null. it gets changed later on!
						
					local town_list = this.FindSuitableTown();
					BuildAirportRoute(town_list);
					/* reset it to null, otherwise it would keep trying the same town! */
					this.subsidy_town_tiletouse = null;
					}
				else
					{
					AILog.Warning(this.INDENT + "This subsidy is not relevant to my interests");
					}
				}
			break;
				
			case AIEvent.AI_ET_ENGINE_PREVIEW:
				{
				/* Accept a vehicle preview if it is an aircraft */
				local ec = AIEventEnginePreview.Convert(e);
				if (ec.GetVehicleType() == AIVehicle.VT_AIR)
					{
					AILog.Warning("Accepted preview for a aircraft: " + ec.GetName());
					ec.AcceptPreview();
					}
				else
					{
					AILog.Warning("Rejected preview because it was not an aircraft");
					}
				}
			break;
				
			default:
				{
				/* Nothing here */
				}
			break;
			}
		}
	}

/**
* The main function
*/
function Chopper::Start()
	{
	/* Name the company */
	if (AICompany.GetName(AICompany.COMPANY_SELF) != "Chopper")
		{
		if (!AICompany.SetName("Chopper"))
			{
			/* Loop through, if name is taken increase number */
			local i = 2;
			while (!AICompany.SetName("Chopper #" + i))
				{
				i+=1;
				}
			}
		}
		
	/* If for whatever reason there is no passenger cargo, give up */
	if (this.passenger_cargo_id == -1)
		{
		AILog.Error("Chopper could not find the passenger cargo");
		return;
		}
		
	/* Give a welcome message */
	AILog.Info(" > Display welcome message");
	AILog.Info(this.INDENT + "Hello, this is Chopper. I am an AI for Open Transport Tycoon Deluxe.");
	AILog.Info(this.INDENT + "I like to build helicopters all day long.");
	AILog.Info(this.INDENT + "If none are available yet, I will have a nap.");
	AILog.Info(this.INDENT + "I will then wake up every once in a while to check again.");
	AILog.Info(this.INDENT + "Enjoy the game!");
		
	/* Check the verson number */
	local version = GetVersion();
	AILog.Info(" > Checking version for compatibility...");
		
	/* Display the version - Special thanks to Nark Pvermars for this code */
	AILog.Info(this.INDENT + "Version " + ((version & (15 << 28)) >> 28) + "." + ((version & (15 << 24)) >> 24) + " Build " + ((version & (15 << 20)) >> 20) + "" + (((version & (1 << 19)) >> 19)?" stable release, ":" not really a release, " + "revision ") + ((version & ((1 << 18) - 1))));
	
	/* Disable certain things in earlier versions due to lack of functions */
	if ((version & ((1 << 18) - 1)) < 17425)
		{
		AILog.Warning(this.INDENT + "Disabling AI doing subsidies, since it doesn't work below about version 17425.");
		AILog.Warning(this.INDENT + "Disabling Oilrig production check, since the function doesn't exist in this version.");

		this.check_oilrig_transported = false;
		this.attempt_subsidies = false;
		}
		
	/* it is 0.7.0, 0.7.1, or 0.7.2 */
	if ((((version & (15 << 20)) >> 20) <= 2) && (((version & (15 << 24)) >> 24) == 7) && (((version & (15 << 28)) >> 28) == 0))
		{
		AILog.Warning(this.INDENT + "Using improvised check for station age, as the function doesn't exist in this version.");
		AILog.Error(this.INDENT + "Chopper AI will work, but will work better if you upgrade to the newest version of OTTD.");
		this.improvise_station_age_check = true;
		}
		
	/* The exact release numbers aren't correct, but most people won't be using those versions any more so it doesn't amtter */
	if ((version & ((1 << 18) - 1)) > 17405 && (version & ((1 << 18) - 1)) < 17490)
		{
		AILog.Warning(this.INDENT + "Helicopters may circle infinitely - this is a bug with OTTD, not the AI! (http://bugs.openttd.org/task/3176)");
		}
		
	/* If the plane speed factor setting is on, display that Chopper realises this */
	if (GetSetting("use_plane_speed_factor") == 1)
		{
		AILog.Info(" > Checking plane speed factor...");
		local plane_speed_factor = AIGameSettings.GetValue("vehicle.plane_speed");
		AILog.Info(this.INDENT + "Plane speed factor: 1/" + plane_speed_factor)
		}
		
	/* Check whether noise levels are on */
	AILog.Info(" > Checking town controlled noise levels...")
	if (AIGameSettings.GetValue("economy.station_noise_level") == 1)
		{
		AILog.Info(this.INDENT + "Town controlled noise levels are on");
		}
	else
		{
		AILog.Info(this.INDENT + "Town controlled noise levels are off");
		}
		
	/* Display the minimum town size that will be worked on */
	AILog.Info(" > Checking minimum town size allowed to work on...");
	AILog.Info(this.INDENT + "Min population: " + GetSetting("min_town_size"));
		
	/* Display the max amount of aircraft */
	AILog.Info(" > Checking maximum number of aircraft allowed...");
	AILog.Info(this.INDENT + "Max aircraft: " + AIGameSettings.GetValue("vehicle.max_aircraft"));
		
	/* Check if helicopters are available*/
	local can_build_helicopters = false;
	local can_build_helicopters_loop = true;
	
	/* Loop until helicopters become available */
	while (can_build_helicopters_loop)
		{
		if (this.loaded == true)
			{
			/* Don't check if it is a loaded game, because sometimes there will be a gap of where no helicopters are available and so loading will cause chopper to sleep endlessly and not maintain the existing aircraft! */
			break;
			}
		
		AILog.Info(" > Checking if helicopters can be built...");
		local engine_list = AIEngineList(AIVehicle.VT_AIR);
		local engine = null;
			
		/* Loop through all available engines */
		for (local engine_i = engine_list.Begin(); engine_list.HasNext(); engine_i = engine_list.Next())
			{
			/* Check if any are helicopters */
			if (AIEngine.GetPlaneType(engine_i) == AIAirport.PT_HELICOPTER)
				{
				/* Quit the loop if one is */
				AILog.Info(this.INDENT + "Excellent, found a helicopter.");
				can_build_helicopters = true;
				engine = engine_i;
				break;
				}
			}
			
		/* If there aren't any, repay loan and sleep for a bit */
		if (engine == null)
			{
			AILog.Info(this.INDENT + "Apparently there are no helicopters currently available.");
			AILog.Info(this.INDENT + "I'll have a sleep for the moment and check back in a while.");
			AICompany.SetLoanAmount(0);
			local counting = 10;
			while (counting > 0)
				{
				AILog.Info("Zzzz... ("+counting+")");
				Sleep(20);
				counting -= 1;
				}
			}
			
		/* If there are some, quit the loop */
		if (can_build_helicopters == true)
			{
			can_build_helicopters_loop = false;
			}
		}

		
	/* If debug signs are on, create the master debug sign that deletes them all when deleted */
	if (GetSetting("debug_signs") == 1)
		{
		AILog.Warning("To delete all debug signs, delete/edit the sign at the top of the map");
		this.master_debug_sign = AISign.BuildSign(AIMap.GetTileIndex(1,1),"=MASTER SIGN=");
		}
		
	/* Make sure autorenew is on, it is very important */
	AILog.Info(" > Enabling autorenew...");
	AICompany.SetAutoRenewStatus(true);	
		
	/* End of start up sequence */
	AILog.Info(this.INDENT + "Now I'll begin!");
		
	/* We start with almost no loan, and we take a loan when we want to build something */
	AICompany.SetLoanAmount(AICompany.GetLoanInterval());
		
	/* We need our local ticker, as GetTick() will skip ticks */
	local ticker = 0;
	
	if (loaded == false)
		{
		AILog.Info(" > Build central airport");
		local town_list = this.FindSuitableTown();
		town_list.Valuate(AITown.GetPopulation);
		this.BuildCentralAirport(town_list);
		}
	
	/* Determine time we may sleep */
	local sleepingtime = 100;
	if (this.delay_build_airport_route < sleepingtime)
		{
		sleepingtime = this.delay_build_airport_route;
		}
		
	/* When this loop ends, the AI crashes */
	while (true)
		{
		/* Once in a while, with enough money, try to build something */
		if ((ticker % this.delay_build_airport_route == 0 || ticker == 0) && this.HasMoney(50000))
			{
			local ret = this.BuildRoute();
			if (ret == -1 && ticker != 0)
				{
				/* No more route found, delay even more before trying to find an other */
				//this.delay_build_airport_route = 500;
				}
			else if (ret < 0 && ticker == 0 && loaded == false)
				{
				/* Give up if a first route cannot be built */
				AICompany.SetName("Failed " + AICompany.GetName(AICompany.COMPANY_SELF));
				AILog.Error("Chopper could not find any possible way to make money on this map, bye bye!");
				AICompany.SetLoanAmount(0);
				return;
				}
			}
			
		/* Manage the routes once in a while */
		if (ticker % 2000 == 0)
			{
			this.ManageAirRoutes();
			}
			
		/* Try to get rid of our loan once in a while */
		if (ticker % 5000 == 0)
			{
			AICompany.SetLoanAmount(0);
			}
			
		/* Check for events once in a while */
		if (ticker % 100 == 0)
			{
			this.HandleEvents();
			}
			
		/* Increase the number of towns to search through occasionally */
		if (ticker % 5000 == 0 && ticker != 0)
			{
			/* Don't increase past 100% */
			if (this.town_population_percentage < 100)
				{
				this.town_population_percentage += 5;
				AILog.Warning(this.INDENT + "Increasing town population percentage to check through by 5 up to " + this.town_population_percentage + "%");
				}
			}
			
		/* Display date every once in a while (so that if the AI crashes, I can see around when it crashed) */
		if (ticker % 50 == 0)
			{
			/* Make sure autorenew is on, it is very useful */
			AICompany.SetAutoRenewStatus(true);
				
			/* If show more debug info is on, display the date and ticks every 50 ticks */
			if (GetSetting("debug_info"))
				{
				local date = AIDate.GetCurrentDate();
				AILog.Info(this.INDENT + this.INDENT + "Date: " + AIDate.GetDayOfMonth(date) + "/" + AIDate.GetMonth(date) + "/" + AIDate.GetYear(date) + ", Ticker: " + ticker);
				}
				
			/* Check on the debug sign (it is not null if it exists) */
			if (this.master_debug_sign != null)
				{
				AILog.Info(" > Checking master sign...");
				AILog.Info(AISign.IsValidSign(this.master_debug_sign));
					
				/* If it is deleted, delete all signs */
				if ((AISign.IsValidSign(this.master_debug_sign)) == false)
					{
					AILog.Info("It has vanished!");
						
					/* Loop through and remove all signs */
					local all_my_signs = AISignList();
					for (local sign = all_my_signs.Begin(); all_my_signs.HasNext(); sign = all_my_signs.Next())
						{
						AISign.RemoveSign(sign);
						}
						
					/* Update log */
					AILog.Info(this.INDENT + "Deleted all signs");
						
					/* But then replace the master sign */
					this.master_debug_sign = AISign.BuildSign(AIMap.GetTileIndex(1,1),"Delete me to remove all signs");
					}
				}
			}
			
		/* Make sure we do not create infinite loops */
		Sleep(sleepingtime);
		ticker += sleepingtime;
		}
	}

/**
* Nothing is actually saved
*/
function Chopper::Save()
	{
	/* Nothing is saved, it is all red from the map */
	AILog.Info("Save successful");
	local data = {};
	return data;
	}

/**
* Nothing is loaded
*/
function Chopper::Load(version, data)
	{
	AILog.Info("Load successful");
		
	/* This variable is used to check that if building a route fails, that the AI shouldn't give up, because if it is loaded it probably already has some routes */
	this.loaded = true;
	}