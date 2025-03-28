class Air extends AIController {
    towns_used = null;
    route_1 = null;
    route_2 = null;
    distance_of_route = {};
    vehicle_to_depot = {};
    passenger_cargo_id = -1;
    funds = 0;

    constructor(){
        this.towns_used = AIList();
        this.route_1 = AIList();
        this.route_2 = AIList();

        local list = AICargoList();
		for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
			if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS)) {
				this.passenger_cargo_id = i;
				break;
			}
		}
    }
};

function Air::BuildAirportRoute(){
    local airport_type = (AIAirport.IsValidAirportType(AIAirport.AT_LARGE) ? AIAirport.AT_LARGE : AIAirport.AT_SMALL);

    AILog.Info("Trying to build an airport route");
    local tile_1 = this.FindSuitableAirportSpot(airport_type, 0);
    if (tile_1 < 0) return -1;
    local tile_2 = this.FindSuitableAirportSpot(airport_type, tile_1);
    if(tile_2 < 0){
        this.towns_used.RemoveValue(tile_1);
        return -2;
    }

    if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW)) {
		AILog.Error("Although the testing told us we could build 2 airports, it still failed on the first airport at tile " + tile_1 + ".");
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return -3;
	}
	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW)) {
		AILog.Error("Although the testing told us we could build 2 airports, it still failed on the second airport at tile " + tile_2 + ".");
		AIAirport.RemoveAirport(tile_1);
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return -4;
	}

    local ret = this.BuildAircraft(tile_1, tile_2);
    if(ret<0){
        AIAirport.RemoveAiport(tile_1);
        AIAirport.RemoveAirport(tile_2);
        this.towns_used.RemoveValue(tile_1);
        this.towns_used.RemoveValue(tile_2);
        return ret;
    }

    AILog.Info("Built a route!");
    return ret;
}

function Air::FindSuitableAirportSpot(airport_type, center_tile){
    local airport_x, airport_y, airport_rad;
    airport_x = AIAirport.GetAirportWidth(airport_type);
    airport_y = AIAirport.GetAirportHeight(airport_type);
    airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

    local town_list = AITownList();
    town_list.RemoveList(this.towns_used);
    town_list.Valuate(AITown.GetPopulation);
    town_list.KeepAboveValue(GetSetting("min_town_size"));
    town_list.KeepTop(10);
    town_list.Valuate(AIBase.RandItem);

    for (local town = town_list.Begin(); !town_list.IsEnd(); town = town_list.Next()){
        Sleep(1);

        local tile = AITown.GetLocation(town);

        local list = AITileList();
        list.AddRectangle(tile - AIMap.GetTileIndex(15, 15),  tile + AIMap.GetTileIndex(15, 15));
        list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
        list.KeepValue(1);
        if (center_tile != 0){
            list.Valuate(AITile.GetDistanceSquareToTile, center_tile);
            list.KeepAboveValue(625);
        }
        list.Valuate(AITile.GetCargoAcceptance, this.passenger_cargo_id, airport_x, airport_y, airport_rad);
        list.RemoveBelowValue(10);

        if (list.Count() == 0) continue;{
            local test = AITestMode();
            local good_tile = 0;

            for (tile = list.Begin(); !list.IsEnd(); tile = list.Next()){
                Sleep(1);
                if (!AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) continue;
                good_tile = tile;
                break;
            }
            if (good_tile == 0) continue;
        }
        AILog.Info("Found a spot in town " + town + " at tile " + tile);
        this.towns_used.AddItem(town, tile);
        return tile;
    }

    AILog.Info("No good spots for an airport.");
    return -1;
}

function Air::BuildAircraft(tile_1, tile_2){
    local hangar = AIAirport.GetHangarOfAirport(tile_1);
    local engine = null;

    local engine_list = AIEngineList(AIVehicle.VT_AIR);

    engine_list.Valuate(AIEngine.GetPrice);
    engine_list.KeepBelowValue(funds < 300000 ? 50000 : (funds < 1000000 ? 300000 : 1000000));

    engine_list.Valuate(AIEngine.GetCargoType);
    engine_list.KeepValue(this.passenger_cargo_id);

    engine_list.Valuate(AIEngine.GetCapacity);
    engine_list.KeepTop(1);

    engine = engine_list.Begin();

    if (!AIEngine.IsValidEngine(engine)){
        AILog.Info("No suitable engine found");
        return -5;
    }
    local vehicle = AIVehicle.BuildVehicle(hangar, engine);
    if (!AIVehicle.IsValidVehicle(vehicle)){
        AILog.Info("Couldn't build the aircraft");
    }

    AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_NONE);
	AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NONE);
    AIVehicle.StartStopVehicle(vehicle);
    this.distance_of_route.rawset(vehicle, AIMap.DistanceManhattan(tile_1, tile_2));
    this.route_1.AddItem(vehicle, tile_1);
    this.route_2.AddItem(vehicle, tile_2);

    AILog.Info("Built an aircraft!");
    return 0;
}

function Air::ManageAirRoutes(){
    local list = AIVehicleList();
    list.Valuate(AIVehicle.GetAge);
    list.KeepAboveValue(730);
    list.Valuate(AIVehicle.GetProfitLastYear);

    for (local i = list.Begin(); list.HasNext(); i = list.Next()){
        local profit = list.GetValue(i);
        if (profit < 10000 && AIVehicle.GetProfitThisYear(i) < 10000){
            if (!vehicle_to_depot.rawin(i) || vehicle_to_depot.rawget(i) != true){
                AILog.Info("Sending vehicle " + i + " to the depot. He's not making enough money.");
                AIVehicle.SendVehicleToDepot(i);
                vehicle_to_depot.rawset(i, true);
            }
        }

        if (vehicle_to_depot.rawin(i) && vehicle_to_depot.rawget(i) == true){
            if (AIVehicle.SellVehicle(i)){
                AILog.Info("Selling vehicle " + i + " from the depot.");
                local list2 = AIVehicleList_Station(AIStation.GetStationID(this.route_1.GetValue(i)));
                if (list2.Count() == 0) this.SellAirports(i);
                vehicle_to_depot.rawdelete(i);
            }
        }
    }

    if (this.funds < 50000) return;

    list = AIStationList(AIStation.STATION_AIRPORT);
    list.Valuate(AIStation.GetCargoWaiting, this.passenger_cargo_id);
    list.KeepAboveValue(250);

    for (local i = list.Begin(); list.HasNext(); i = list.Next()){
        local list2 = AIVehicleList_Station(i);
        if (list2.Count() == 0){
            this.SellAirports(i);
            continue;
        };

        local v = list2.Begin();
        local dist = this.distance_of_route.rawget(v);
        list2.Valuate(AIVehicle.GetAge);
        list2.KeepBelowValue(dist);
        if (list2.Count() != 0) continue;

        return this.BuildAircraft(this.route_1.GetValue(v), this.route_2.GetValue(v));
    }
}

function Air::SellAirports(i){
    AIlog.Info("Removing unserved airports.");
    AIAirport.RemoveAirport(this.route_1.GetValue(i));
    AIAirport.RemoveAirport(this.route_2.GetValue(i));
    this.towns_used.RemoveValue(this.route_1.GetValue(i));
    this.towns_used.RemoveValue(this.route_2.GetValue(i));
    this.route_1.RemoveValue(i);
    this.route_2.RemoveValue(i);
}

function Air::turn(x){
    this.funds = x;
    this.BuildAirportRoute();
    this.ManageAirRoutes();
    return profit;
}