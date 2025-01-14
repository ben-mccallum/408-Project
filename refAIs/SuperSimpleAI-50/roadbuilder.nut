/**
 * This file is part of SuperSimpleAI: An OpenTTD AI.
 *
 * Based on code from SimpleAI, written by Brumi.
 *
 * Author: Jaume Sabater
 *
 * It's free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * any later version.
 *
 * You should have received a copy of the GNU General Public License
 * with it.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * Build a road from one point to another.
 * Builder class variables set: holes
 * @param head1 The starting point.
 * @param head2 The ending point.
 * @return True if the construction succeeded. Note: the function also returns true if the road was
 * constructed, but there are holes remaining.
 */
function cBuilder::BuildRoad(head1, head2)
{
	local reverse = false;
	local pathfinder = MyRoadPF();
	// Set some pathfinder penalties
	if (!Banker.SetMinimumBankBalance(Banker.InflatedValue(500000))) {
		pathfinder._cost_level_crossing = 800;
		pathfinder._cost_coast = 100;
		pathfinder._cost_slope = 100;
		pathfinder._cost_bridge_per_tile = 160;
		pathfinder._cost_tunnel_per_tile = 120;
		pathfinder._max_bridge_length = 7;
		pathfinder._max_tunnel_length = 5;
		pathfinder._cost_farm_tile = 30;
		pathfinder._cost_non_flat_tile = 30;
	} else {
		pathfinder._cost_level_crossing = 1000;
		pathfinder._cost_coast = 100;
		pathfinder._cost_slope = 100;
		pathfinder._cost_bridge_per_tile = 80;
		pathfinder._cost_tunnel_per_tile = 60;
		pathfinder._max_bridge_length = 12;
		pathfinder._max_tunnel_length = 12;
		pathfinder._cost_farm_tile = 0;
	}
	pathfinder.InitializePath([head1], [head2]);
	local counter1 = 0;
	local counter2 = 0;
	local path = false;
	// Try to find a path
	if (!Debug()) LogInfo("Pathfinding...");
	while (path == false && counter1 < 10) {
		LogDebug("Pathfinding (" + counter1 * 10 + "%)...");
		counter2 = 0;
		while (path == false && counter2 < 25) {
			path = pathfinder.FindPath(250);
			counter2++;
			root.manager.MainLoop();
			if (!AreIndustriesAlive()) return false;
		}
		counter1++;
	}
	counter2 += ( counter1 - 1 ) * 25;
	if (path != null && path != false) LogInfo("Path found. (" + counter2 + ")");
	else {
		// If road starts with a bridge findpath can fail at first itinetarion. So
		// try to find path from the other head.
                if (path == null) {
                        LogDebug("Pathfinder failed from head 1, trying from head 2");
                        reverse = true;
                        pathfinder.InitializePath([head2], [head1]);
                        counter1 = 0;
                        counter2 = 0;
                        path = false;
                        // Try to find a path
			while (path == false && counter1 < 10) {
				LogDebug("Pathfinding (" + counter1 * 10 + "%)...");
				counter2 = 0;
				while (path == false && counter2 < 25) {
					path = pathfinder.FindPath(250);
					counter2++;
					root.manager.MainLoop();
					if (!AreIndustriesAlive()) return false;
				}
				counter1++;
			}
			counter2 += ( counter1 - 1 ) * 25;
		}
		if (path != null && path != false) LogInfo("Path found. (" + counter2 + ")");
		else {
			LogWarning("Pathfinding failed. (" + counter2 + ")");
			return false;
		}
	}
	local prev = null;
	local waserror = false;
	local starttile = null;
	// Build the road itself
	while (path != null) {
		if (starttile == null) starttile = path;
		local par = path.GetParent();
		if (par != null) {
			if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1) {
				// If it is not a bridge or a tunnel
				local build_rail = true;
				if (AISettings.FastRoadBuild) {
					if (AITile.IsBuildable(par.GetTile()) && MyAIRoad.CanBuildRoad(starttile.GetTile(), par.GetTile())) {
						build_rail = false;
					} else {
						if (!WaitAndBuildRoad(path.GetTile(), starttile.GetTile())) path = starttile;
						else starttile = path;
					}
				}
				if (build_rail) {
					if (!WaitAndBuildRoad(path.GetTile(), par.GetTile())) {
						local error = AIError.GetLastError();
						if (error != AIError.ERR_ALREADY_BUILT) {
							// If there was some error building the road
							if (error == AIError.ERR_VEHICLE_IN_THE_WAY) {
								// Try again if a vehicle was in the way
								LogInfo("A vehicle was in the way while I was building the road. Retrying...");
								counter1 = 0;
								AIController.Sleep(75);
								while (!WaitAndBuildRoad(path.GetTile(), par.GetTile()) && counter1 < 3) {
									counter1++;
									AIController.Sleep(75);
								}
								if (counter1 > 2) {
									// Report a hole if the vehicles aren't going out of the way
									LogInfo("An error occured while I was building the road: " + AIError.GetLastErrorString());
									cBuilder.ReportHole(path.GetTile(), par.GetTile(), waserror);
									waserror = true;
								} else {
									// Report the end of the hole if the vehicle got out of the way
									if (waserror) {
										waserror = false;
										holes.push([holestart, holeend]);
									}
								}
							} else {
								// If the error was something other than a vehicle in the way
								LogInfo("An error occured while I was building the road: " + AIError.GetLastErrorString());
								cBuilder.ReportHole(path.GetTile(), par.GetTile(), waserror);
								waserror = true;
							}
						} else {
							// If the road has been already built and there was an error beforehand
							if (waserror) {
								waserror = false;
								holes.push([holestart, holeend]);
							}
						}
					} else {
						// If the contruction suceeded normally and there was an error beforehand
						if (waserror) {
							waserror = false;
							holes.push([holestart, holeend]);
						}
					}
				}
			} else {
				if (AISettings.FastRoadBuild) WaitAndBuildRoad(path.GetTile(), starttile.GetTile());
				starttile = null;
				// Build a bridge or a tunnel
				if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
					if (AIRoad.IsRoadTile(path.GetTile())) cBuilder.WaitAndDemolish(path.GetTile());
					if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
						// Build a tunnel
						cBuilder.WaitForMoney(MyAITunnel.GetRoadTunnelCost(par.GetTile()) + AICompany.GetLoanInterval());
						if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
							// If the tunnel couldn't be built
							LogInfo("An error occured while I was building the road: " + AIError.GetLastErrorString());
							if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
								LogWarning("That tunnel would be too expensive. Construction aborted.");
								return false;
							}
							cBuilder.ReportHole(prev.GetTile(), par.GetTile(), waserror);
							waserror = true;
						} else {
							// If the tunnel was built and there was an error beforehand
							if (waserror) {
								waserror = false;
								holes.push([holestart, holeend]);
							}
						}
					} else {
						// Build a bridge
						if (!WaitAndBuildRoadBridge(path.GetTile(), par.GetTile())) {
							// If the bridge couldn't be built
							LogInfo("An error occured while I was building the road: " + AIError.GetLastErrorString());
							if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
								LogWarning("That bridge would be too expensive. Construction aborted.");
								return false;
							}
							cBuilder.ReportHole(prev.GetTile(), par.GetTile(), waserror);
							waserror = true;
						} else {
							if (waserror) {
								waserror = false;
								holes.push([holestart, holeend]);
							}
						}
					}
				}
			}
		}
		prev = path;
		path = par;
		// Check the cash on hand
		if (!cBuilder.WaitForMoney(AICompany.GetLoanInterval())) {
			LogWarning("I don't have enough money to complete the route.");
			return false;
		}
	}
	if (AISettings.FastRoadBuild) WaitAndBuildRoad(prev.GetTile(), starttile.GetTile());
	// If the last piece of road couldn't be built
	if (waserror) {
		waserror = false;
		holes.push([holestart, holeend]);
	}
	return true;
}

/**
 * Register a new hole in the route to be later corrected.
 */
function cBuilder::ReportHole(start, end, waserror)
{
	if (!waserror) holestart = start;
	holeend = end;
}

/**
 * Try to connect the holes in the route.
 * Builder class variables used: holes
 * @return True if the action succeeded.
 */
function cBuilder::RepairRoute()
{
	if (recursiondepth > 10) {
		LogError("It looks like I got into an infinite loop.");
		return false;
	}
	local holelist = holes;
	holes = [];
	foreach (idx, hole in holelist) if (!cBuilder.BuildRoad(hole[0], hole[1])) return false;
	return true;
}

/**
 * Upgrade the registered road bridges.
 * @return True if some bridge was upgraded.
 */
function cBuilder::UpgradeRoadBridges()
{
	local count = 0;
	foreach (tile, route in root.roadbridges) {
		if (!AITile.HasTransportType(tile, AITile.TRANSPORT_ROAD) || !AIBridge.IsBridgeTile(tile)) {
			LogDebug("Found a non-bridge tile in roadbridge list!");
			root.roadbridges.RemoveItem(tile);
			continue;
		}
		// Stop if we cannot afford it
		local otherend = AIBridge.GetOtherBridgeEnd(tile);
		local len = AIMap.DistanceManhattan(tile, otherend) + 1;
		local bridgelist = AIBridgeList_Length(len);
		local group = cBuilder.GetGroupFromRoute(route);
		bridgelist.Valuate(AIBridge.GetMaxSpeed);
		if (AIBridge.GetBridgeID(tile) == bridgelist.Begin()) continue;
		// Stop if we cannot afford it
		if (!Banker.SetMinimumBankBalance(AISettings.MiniumMoneyToUpgradeBridges() + AIBridge.GetPrice(bridgelist.Begin(), len))) {
			LogDebug("We don't have money to continue upgrading road bridges!");
			continue;
		}
		if (AIBridge.GetMaxSpeed(AIBridge.GetBridgeID(tile)) < MyRoutes.GetRouteMaxCurrentSpeed(group) && AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridgelist.Begin(), tile, otherend)) count++;
	}
	if (count > 0) {
		LogInfo("Upgrading road bridges (" + root.roadbridges.Count() + " bridges registered, " + count + " bridges upgraded)");
		return true;
	}
	return false;
}

/*
 * Build a piece of rail, if we have money.
 * @param arg1 first argument of AIRoad.BuildRoad.
 * @param arg2 second argument of AIRoad.BuildRoad.
 * @return true if success.
 */
function cBuilder::WaitAndBuildRoad(arg1, arg2)
{
	if (MyAIRoad.CanBuildRoad(arg1, arg2)) {
		if (cBuilder.WaitForMoney(MyAIRoad.GetRoadCost(arg1, arg2))) {
			if (AIRoad.BuildRoad(arg1, arg2)) return true;
			else {
				if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) return true;
			}
		}
	}
	return false;
}

/*
 * Build and register a road bridge, if we have money.
 * @param arg1 Start tile of the bridge.
 * @param arg2 End tile of the bridge.
 * @return true if success.
 */
function cBuilder::WaitAndBuildRoadBridge(arg1, arg2)
{
	if (!WaitAndBuildBridge(arg1, arg2, AIVehicle.VT_ROAD)) return false;
	root.roadbridges.AddTile(arg1);
	root.roadbridges.SetValue(arg1, root.routes.len());
	return true;
}

/*
 * Build a road depot, if we have money.
 * @param arg1 first argument of AIRoad.BuildRoadDepot.
 * @param arg2 second argument of AIRoad.BuildRoadDepot.
 * @return true if success.
 */
function cBuilder::WaitAndBuildRoadDepot(arg1, arg2) {
	if (MyAIRoad.CanBuildRoadDepot(arg1, arg2)) return cBuilder.WaitForMoney(MyAIRoad.GetRoadDepotCost(arg1, arg2)) && AIRoad.BuildRoadDepot(arg1, arg2);
	return false;
}

