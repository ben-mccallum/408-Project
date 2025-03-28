require("pathfinder/line.nut");
require("pathfinder/coast.nut");

class Sea extends AIController{
    funds = 0;
    max_dock_distance = 15;
    max_distance = 300;
    buoy_distance = 25;
    not_connected = AIList();
    min_passengers = 9999;
    cargo_id = -1;
    line_PF = null;
    coast_PF = null;


    constructor() {
        local cargo_list = AICargoList();
        cargo_list.Valuate(AICargo.HasCargoClass, AICargo.CC_PASSENGERS);
        cargo_list.KeepValue(1);
        cargo_list.Valuate(AICargo.GetTownEffect);
        cargo_list.KeepValue(AICargo.TE_PASSENGERS);
        this.cargo_id = cargo_list.Begin();
        this.line_PF = StraightLinePathfinder();
        this.coast_PF = CoastPathfinder();
    }
}

function SafeAddRectangle(list, tile, range) {
    local tile_x = AIMap.GetTileX(tile);
    local tile_y = AIMap.GetTileY(tile);
    local x1 = max(1, tile_x - range);
    local y1 = max(1, tile_y - range);
    local x2 = min(AIMap.GetMapSizeX() - 2, tile_x + range);
    local y2 = min(AIMap.GetMapSizeY() - 2, tile_y + range);
    list.AddRectangle(AIMap.GetTileIndex(x1, y1), AIMap.GetTileIndex(x2, y2));
}

function IsSimpleSlope(tile) {
    local slope = AITile.GetSlope(tile);
    return slope == AITile.SLOPE_NW
        || slope == AITile.SLOPE_NE
        || slope == AITile.SLOPE_SE
        || slope == AITile.SLOPE_SW;
}

function GetCoastTiles(town, range, cargo_id) {
    local city = AITown.GetLocation(town);
    local tiles = AITileList();
    SafeAddRectangle(tiles, city, range);
    tiles.Valuate(AITile.GetClosestTown);
    tiles.KeepValue(town);
    tiles.Valuate(AITile.IsCoastTile);
    tiles.KeepValue(1);
    tiles.Valuate(IsSimpleSlope);
    tiles.KeepValue(1);
    tiles.Valuate(AITile.GetCargoAcceptance, cargo_id, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_DOCK));
    tiles.KeepAboveValue(7);
    return tiles;
}

function GetBestTile(town, range, cargo_id){
    local tiles = GetCoastTiles(town, range, cargo_id);
    if (tiles.IsEmpty()){
        return -1;
    }

    local city = AITown.GetLocation(town);
    tiles.Valuate(AIMap.DistanceManhattan, city);
    tiles.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
    return tiles.Begin();
}

function Sea::FindDock(town){
    local docks = AIStationList(AIStation.STATION_DOCK);
    docks.Valuate(AIStation.GetNearestTown);
    docks.KeepValue(town);
    if (docks.IsEmpty()){
        return -1;
    }else{
        return AIStation.GetLocation(docks.Begin());
    }
}

function Sea::BuildDock(town){
    local coast = GetCoastTiles(town, this.max_dock_distance, this.cargo_id);
    local coords = AITown.GetLocation(town);
    coast.Valuate(AIMap.DistanceManhattan, coords);
    coast.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);

    if (AIMarine.GetBuildCost(AIMarine.BT_DOCK) < this.funds){
        for (local tile = coast.Begin(); coast.HasNext(); tile = coast.Next()){
            if (AIMarine.BuildDock(tile, AIStation.STATION_NEW)){
                funds -= AIMarine.GetBuildCost(AIMarine.BT_DOCK);
                AILog.Info("Built a dock!");
                return tile;
            }
        }
    }else{
        return -1;
    }
}

function Sea::FindWaterDepot(dock, range){
    local depots = AIDepotList(AITile.TRANSPORT_WATER);
    depots.Valuate(AIMap.DistanceManhattan, dock);
    depots.KeepBelowValue(range);
    depots.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
    if (depots.IsEmpty()){
        AILog.Info("Couldn't find a depot.");
        return -1;
    }else{
        return depots.Begin();
    }
}

function Sea::BuildWaterDepot(dock, max_distance){
    local depotArea = AITileList();
    SafeAddRectangle(depotArea, dock, max_distance);
    depotArea.Valuate(AITile.IsWaterTile);
    depotArea.KeepValue(1);
    depotArea.Valuate(AIMap.DistanceManhattan, dock);
    depotArea.KeepAboveValue(4);
    depotArea.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);

    if (AIMarine.GetBuildCost(AIMarine.BT_DEPOT) < this.funds){
        for (local depot = depotArea.Begin(); depotArea.HasNext(); depotArea.Next()){
            local x = AIMap.GetTileX(depot);
            local y = AIMap.GetTileY(depot);
            local front = AIMap.GetTileIndex(x, y + 1);

            if (!AITile.IsWaterTile(front) ||
                !AITile.IsWaterTile(AIMap.GetTileIndex(x, y + 1)) ||
                !AITile.IsWaterTile(AIMap.GetTileIndex(x - 1, y)) ||
                !AITile.IsWaterTile(AIMap.GetTileIndex(x + 1, y))){
                    continue;
                }
            if (AIMarine.BuildWaterDepot(depot, front)){
                funds -= AIMarine.GetBuildCost(AIMarine.BT_DEPOT);
                AILog.Info("Built a depot!");
                return depot;
            }
        }
    }
    AILog.Info("Failed to build a depot.");
    return -1;
}

function Sea::GetBuoy(tile){
    local tiles = AITileList();
    SafeAddRectangle(tiles, tile, 3);
    tiles.Valuate(AIMarine.IsBuoyTile);
    tiles.KeepValue(1);
    if (tiles.IsEmpty()){
        AIMarine.BuildBuoy(tile);
        return tile;
    }else{
        return tiles.Begin();
    }
}

function Sea::GetFerryModels(){
    local engine_list = AIEngineList(AIVehicle.VT_WATER);
    engine_list.Valuate(AIEngine.GetCargoType);
    engine_list.KeepValue(this.cargo_id);
    return engine_list;
}

function FerryModelRating(model){
    return AIEngine.GetCapacity(model) * AIEngine.GetMaxSpeed(model);
}

function Sea::GetBestFerry(){
    local engines = GetFerryModels();
    if (engines.IsEmpty()){
        return -1;
    }

    engines.Valuate(FerryModelRating);
    engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
    local best = engines.Begin();
    this.min_passengers = floor(AIEngine.GetCapacity(best) * 1.25);
    return best;
}

function Sea::CloneFerry(dock1, dock2){
    local dock1_vs = AIVehicleList_Station(AIStation.GetStationID(dock1));
    local dock2_vs = AIVehicleList_Station(AIStation.GetStationID(dock2));
    dock1_vs.KeepList(dock2_vs);
    if (dock1_vs.IsEmpty()){
        return 0;
    }
    local depot = FindWaterDepot(dock1, 10);
    if (depot == -1){
        depot = FindWaterDepot(dock2, 10);
        if (depot == -1){
            depot = BuildWaterDepot(dock1, 10);
            if (depot == -1){
                return 1;
            }
        }
    }

    local vehicle = dock1_vs.Begin();
    local engine = AIVehicle.GetEngineType(vehicle);

    if (AIEngine.GetPrice(engine) < this.funds) {
        local cloned = AIVehicle.CloneVehicle(depot, vehicle, true);
        funds -= AIEngine.GetPrice(engine);
        AILog.Info("Built a boat!");
        if (!AIVehicle.IsValidVehicle(cloned)){
            return 1;
        }
        AIVehicle.StartStopVehicle(cloned);
        return 2;
    }
    return 3;
}

function Sea::BuildAndStartFerry(dock1, dock2, path){
    local engine = GetBestFerry();
    if (engine == -1){
        AILog.Info("Line 222 error");
        return false;
    }

    if (AIEngine.GetPrice(engine) < funds){
        local depot = FindWaterDepot(dock1, 10);
        if (depot == -1){
            depot = BuildWaterDepot(dock1, 10);
            if (depot == -1){
                return false;
            }
        }

        local buoys = [];
        for (local i = 25; i < path.len() - 25 / 2; i += 25){
            buoys.push(GetBuoy(path[i]));
        }

        local vehicle = AIVehicle.BuildVehicle(depot, engine);
        funds -= AIEngine.GetPrice(engine);
        if (AIVehicle.IsValidVehicle(vehicle)){
            if (!AIOrder.AppendOrder(vehicle, dock1, AIOrder.OF_NONE)){
                AIVehicle.SellVehicle(vehicle);
                funds += AIEngine.GetPrice(engine);
                return false;
            }

            foreach(buoy in buoys){
                AIOrder.AppendOrder(vehicle, buoy, AIOrder.OF_NONE);
            }

            if (!AIOrder.AppendOrder(vehicle, dock2, AIOrder.OF_NONE)){
                AIVehicle.SellVehicle(vehicle);
                funds += AIEngine.GetPrice(vehicle);
                return false;
            }

            buoys.reverse();
            foreach(buoy in buoys){
                AIOrder.AppendOrder(vehicle, buoy, AIOrder.OF_NONE);
            }

            if (!AIOrder.InsertConditionalOrder(vehicle, 0, 0)
                || !AIOrder.InsertOrder(vehicle, 1, depot, AIOrder.OF_NONE)
                || !AIOrder.SetOrderCondition(vehicle, 0, AIOrder.OC_REMAINING_LIFETIME)
                || !AIOrder.SetOrderCompareFunction(vehicle, 0, AIOrder.CF_MORETHAN)
                || !AIOrder.SetOrderCompareValue(vehicle, 0, 0)){
                    AIVehicle.SellVehicle(vehicle);
                    funds += AIEngine.GetPrice(vehicle);
                    return false;
                }

            if (!AIVehicle.StartStopVehicle(vehicle)){
                AIVehicle.SellVehicle(vehicle);
                funds += AIEngine.GetPrice(vehicle);
                return false;
            }

            return true;
        }else{
            return false;
        }
    }
    return false;
}

function Sea::BuildFerryRoutes(){
    local ferries_built = 0;
    local all_towns = AITownList();
    local towns = AIList();
    for (local i = 0; i < all_towns.Count(); i += 50){
        local part = AIList();
        part.AddList(all_towns);
        part.RemoveTop(i);
        part.KeepTop(50);
        part.Valuate(AITown.GetPopulation);
        part.KeepAboveValue(500);
        part.Valuate(GetBestTile, this.max_dock_distance, this.cargo_id)
        part.RemoveValue(-1);
        towns.AddList(part);
    }

    for (local town = towns.Begin(); towns.HasNext(); town = towns.Next()){
        local dock1 = FindDock(town);

        if (dock1 != -1 && AIStation.GetCargoWaiting(AIStation.GetStationID(dock1), this.cargo_id) < this.min_passengers){
            continue;
        }

        local coast1 = dock1;
        if (coast1 == -1){
            coast1 = GetBestTile(town, this.max_dock_distance, this.cargo_id);
        }

        local temp = AIList();
        temp.AddList(towns);
        temp.RemoveItem(town);
        temp.Valuate(AITown.GetDistanceManhattanToTile, AITown.GetLocation(town));
        temp.KeepBelowValue(this.max_distance);
        temp.KeepAboveValue(20);
        temp.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);

        for (local town2 = temp.Begin(); temp.HasNext(); town2 = temp.Next()){
            local dock2 = FindDock(town2);
            if (dock2 != -1 && AIStation.GetCargoWaiting(AIStation.GetStationID(dock2), this.cargo_id) < this.min_passengers){
                continue;
            }
            if (dock1 != -1 && dock2 != -1){
                local clone_res = CloneFerry(dock1, dock2);
                if (clone_res == 2){
                    ferries_built++;
                    continue;
                }
            }

            local coast2 = dock2;
            if (coast2 == -1){
                coast2 = GetBestTile(town2, this.max_dock_distance, this.cargo_id);
            }

            if (AIMap.DistanceManhattan(coast1, coast2) < 20){
                continue;
            }

            if (this.not_connected.HasItem((coast1 << 32) | coast2)){
                continue;
            }

            local path = null;
            if (this.line_PF.FindPath(coast1, coast2, 450)){
                path = this.line_PF.path;
            } else if (this.coast_PF.FindPath(coast1, coast2, 450)){
                path = this.coast_PF.path;
            }else{
                this.not_connected.AddItem((coast1 << 32) | coast2, 0);
                this.not_connected.AddItem((coast2 << 32) | coast1, 0);
                continue;
            }

            if (dock1 == -1){
                dock1 = BuildDock(town);
                if (dock1 == -1){
                    continue;
                }
            }

            if (dock2 == -1){
                dock2 = BuildDock(town2);
                if (dock2 == -1){
                    continue;
                }
            }

            if (BuildAndStartFerry(dock1, dock2, path)){
                ferries_built++;
            }
        }
    }
    return ferries_built;
}


function Sea::turn(inp){
    this.funds = inp;
    local new_ferries = this.BuildFerryRoutes();
}