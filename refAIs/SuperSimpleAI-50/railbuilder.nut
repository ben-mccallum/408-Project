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
 * Build a rail line between two given points.
 * @param head1 The starting points of the rail line.
 * @param head2 The ending points of the rail line.
 * @param depot1 Temporaly depot to prevent 90 grade turns. 
 * @param depot2 Temporaly depot to prevent 90 grade turns. 
 * @return True if the construction succeeded.
 */
function cBuilder::BuildRail(head2, head1, depot1, depot2)
{
	if (depot1[0] != null && depot1[1] != null) if (cBuilder.WaitAndBuildRailDepot(depot1[0],depot1[1]) || cBuilder.WaitAndBuildRailDepot(depot1[0],depot1[0] + (depot1[0] - depot1[1]))) builddepot1 = depot1[0];
	if (depot2[0] != null && depot2[1] != null) if (cBuilder.WaitAndBuildRailDepot(depot2[0],depot2[1]) || cBuilder.WaitAndBuildRailDepot(depot2[0],depot2[0] + (depot2[0] - depot2[1]))) builddepot2 = depot2[0];
	root.buildingstage = root.BS_PATHFINDING;
	local reverse = false;
	local pathfinder = MyRailPF();
	// Set some pathfinder penalties
	local bridge_type_max_speed = false;
	if (!Banker.SetMinimumBankBalance(Banker.InflatedValue(200000))) {
		pathfinder._max_cost = 10000000;
	} else {
		if (!Banker.SetMinimumBankBalance(Banker.InflatedValue(600000))) {
			pathfinder._max_cost = 20000000;
		} else {
			pathfinder._max_cost = 40000000;
			bridge_type_max_speed = true;
		}
	}
	// At begining of the game try to build cheaper.
	pathfinder._cost_farm_tile = 11 - MyMath.Min(11, root.routes_active);
	pathfinder._cost_non_flat_tile = 11 - MyMath.Min(11, root.routes_active);
	pathfinder._cost_steep_slope_tile = (21 - MyMath.Min(11, root.routes_active)) * 2;
	pathfinder._cost_over_height = 50;
	local Head1TileHeight = AITile.GetMaxHeight(head1[0]);
	local Head2TileHeight = AITile.GetMaxHeight(head2[0]);
	local MaxHeightDifference = AISettings.MaxDiffPassingLaneHeigh() - MyMath.Abs(Head1TileHeight - Head2TileHeight) + (AISettings.MaxDiffPassingLaneHeigh() / 2).tointeger();
	pathfinder._min_tile_height = MyMath.Min(Head1TileHeight, Head2TileHeight);
	pathfinder._max_tile_height = MyMath.Max(Head1TileHeight, Head2TileHeight);
	pathfinder._cost_slope = MyMath.Min(250 + root.routes_active * 3, 300);
	pathfinder._cost_coast = MyMath.Max(30 - root.routes_active * 2, 10);
	pathfinder._cost_bridge_per_tile = MyMath.Max(200 - root.routes_active * 3, 105);
	pathfinder._cost_tunnel_per_tile = MyMath.Max(250 - root.routes_active * 4, 125);
	pathfinder._cost_level_crossing = MyMath.Min(500 + 30 * root.routes_active, 1500);
	pathfinder._max_bridge_length = MyMath.Clamp(root.routes_active, 4, AIGameSettings.GetValue("construction.max_bridge_length"));
	pathfinder._max_tunnel_length = MyMath.Clamp(root.routes_active, 2, AIGameSettings.GetValue("construction.max_tunnel_length"));
	//pathfinder.PrintAllValues();
	pathfinder.InitializePath([head1], [head2]);
	local counter1 = 0;
	local counter2 = 0;
	local path = false;
	Banker.PayLoan();
	// Try to find a path
	if (!Debug()) LogInfo("Pathfinding...");
	while (path == false && counter1 < 10) {
		LogDebug("Pathfinding (" + counter1 * 10 + "%)...");
		counter2 = 0;
		while (path == false && counter2 < 30) {
			path = pathfinder.FindPath(300);
			counter2++;
			root.manager.MainLoop();
			if (!AreIndustriesAlive()) return cBuilder.RemoveTmpDepotsAndFalse();
		}
		counter1++;
	}
	counter2 += ( counter1 - 1 ) * 30;
	if (path != null && path != false) {
		LogInfo("Path found. (" + counter2 + ")");
	} else {
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
				while (path == false && counter2 < 30) {
					path = pathfinder.FindPath(300);
					counter2++;
					root.manager.MainLoop();
					if (!AreIndustriesAlive()) return cBuilder.RemoveTmpDepotsAndFalse();
				}
				counter1++;
			}
			counter2 += ( counter1 - 1 ) * 30;
		}
		if (path != null && path != false) {
			LogInfo("Path found. (" + counter2 + ")");
		} else {
			LogWarning("Pathfinding failed. (" + counter2 + ")");
			return cBuilder.RemoveTmpDepotsAndFalse();
		}
	}
	Banker.GetMaxBankBalance();
	return cBuilder.BuildTracks(path, head1, depot1, depot2);
}

/**
 * Build tracks listed in path.
 * @param trackslist list of tracks to build.
 * @return True if the construction succeeded.
 */
function cBuilder::BuildTracks(trackslist, head1, depot1, depot2)
{
	local prev = null;
	local prevprev = null;
	local pp1 = null, pp2 = null, pp3 = null;
	local railstobuild = 0;
	local pendingfrom = null, pendingtile = null;
	while (trackslist != null) {
		if (!AreIndustriesAlive()) return cBuilder.RemoveTmpDepotsAndFalse();
		root.buildingstage = root.BS_BUILDING;
		if (prevprev != null) {
			if (AIMap.DistanceManhattan(prev, trackslist.GetTile()) > 1) {
				if (railstobuild > 0) {
					if (cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, prev) || cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, prev)) {
						railstobuild = 0;
						pendingfrom = null;
						pendingtile = null;
					} else {
						LogInfo("An error occured while I was building the rail: (3)" + AIError.GetLastErrorString());
						if (!cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, pp2)) return cBuilder.RemoveTmpDepotsAndFalse();
						if (!cBuilder.RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)) return cBuilder.RemoveTmpDepotsAndFalse();
						else return !cBuilder.RemoveTmpDepotsAndFalse();
					}
				}
				// If we are building a tunnel or a bridge
				if (AITunnel.GetOtherTunnelEnd(prev) == trackslist.GetTile()) {
					// If we are building a tunnel
					if (!cBuilder.WaitAndBuildRailTunnel(prev, AITunnel.GetOtherTunnelEnd(prev))) {
						if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) LogInfo("That tunnel would be too expensive.");
						else LogInfo("An error occured while I was building the rail: " + AIError.GetLastErrorString());
						// Try again if we have the money
						if (!cBuilder.RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)) return cBuilder.RemoveTmpDepotsAndFalse();
						else return !cBuilder.RemoveTmpDepotsAndFalse();
					}
				} else {
					// If we are building a bridge
					if (!WaitAndBuildRailBridge(prev, trackslist.GetTile())) {
						LogInfo("An error occured while I was building the rail: " + AIError.GetLastErrorString());
						if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
							LogWarning("That bridge would be too expensive. Construction aborted.");
							return cBuilder.RemoveTmpDepotsAndFalse();
						}
						// Try again if we have the money
						if (!cBuilder.RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)) return cBuilder.RemoveTmpDepotsAndFalse();
						else return !cBuilder.RemoveTmpDepotsAndFalse();
					}
				}
				// Step these variables after a tunnel or bridge was built
				pp3 = pp2;
				pp2 = pp1;
				pp1 = prevprev;
				prevprev = prev;
				prev = trackslist.GetTile();
				trackslist = trackslist.GetParent();
			} else {
				// If we are building a piece of rail track
				if (AISettings.FastRailBuild()) {
					if (railstobuild == 0) {
						if (pendingfrom == null) pendingfrom = prevprev;
						if (pendingtile == null) pendingtile = prev;
						railstobuild++;
					} else {
						if (railstobuild < 5 && (!MyAIRail.CanBuildRail(pendingfrom, pendingtile, trackslist.GetTile()) || !MyAIRail.CanBuildRail(trackslist.GetTile(), prev, pendingfrom))
						   || railstobuild > 4 && !MyAIRail.CanBuildRail(pp2, pp1, trackslist.GetTile())) {
							if (cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, prev) || cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, prev)) {
								railstobuild = 1;
								pendingfrom = prevprev;
								pendingtile = prev;
							} else {
								LogInfo("An error occured while I was building the rail: " + AIError.GetLastErrorString());
								if (!cBuilder.RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)) return cBuilder.RemoveTmpDepotsAndFalse();
								else return !cBuilder.RemoveTmpDepotsAndFalse();
							}
						} else {
							if (!MyAIRail.CanBuildRail(prevprev, prev, trackslist.GetTile())) {
								LogInfo("An error occured while I was building the rail:" + AIError.GetLastErrorString());
								if (!cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, pp2)) return cBuilder.RemoveTmpDepotsAndFalse();
								if (!cBuilder.RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)) return cBuilder.RemoveTmpDepotsAndFalse();
								else return !cBuilder.RemoveTmpDepotsAndFalse();
							}
							railstobuild++;
						}
					}
				} else {
					if (!cBuilder.WaitAndBuildRail(prevprev, prev, trackslist.GetTile()) && !cBuilder.WaitAndBuildRail(prevprev, prev, trackslist.GetTile())) {
						LogInfo("An error occured while I was building the rail: " + AIError.GetLastErrorString());
						if (!cBuilder.RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)) return cBuilder.RemoveTmpDepotsAndFalse();
						else return !cBuilder.RemoveTmpDepotsAndFalse();
					}
				}
			}
		}
		// Step these variables at the start of the construction
		if (trackslist != null) {
			pp3 = pp2;
			pp2 = pp1;
			pp1 = prevprev;
			prevprev = prev;
			prev = trackslist.GetTile();
			trackslist = trackslist.GetParent();
		}
		// Check if we still have the money
		if (!cBuilder.WaitForMoney(AICompany.GetLoanInterval())) {
			LogWarning("I don't have enough money to complete the route.");
			return cBuilder.RemoveTmpDepotsAndFalse();
		}
	}
	if (railstobuild > 0) {
		if (!cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, prev) && !cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, prev)) {
			LogInfo("An error occured while I was building the rail: " + AIError.GetLastErrorString());
			if (!cBuilder.WaitAndBuildRail(pendingfrom, pendingtile, pp2)) return cBuilder.RemoveTmpDepotsAndFalse();
			if (!cBuilder.RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)) return cBuilder.RemoveTmpDepotsAndFalse();
		}
	}
	Banker.PayLoan();
	return !cBuilder.RemoveTmpDepotsAndFalse();
}

/**
 * Remove temporal depot builded to aviod 90 grade turns.
 * @param depot1 first depot to demolish.
 * @param depot2 second depot to demolish.
 * @return false for code economy.
 */
function cBuilder::RemoveTmpDepotsAndFalse()
{
	if (builddepot1 != null && cBuilder.WaitAndDemolish(builddepot1)) builddepot1 = null;
	if (builddepot2 != null && cBuilder.WaitAndDemolish(builddepot2)) builddepot2 = null;
	return false;
}

/**
 * Remove a continuous segment of rail track starting from a single point. This includes depots
 * and stations, in all directions and braches. Basically the function deletes all rail tiles
 * which are reachable by a train from the starting point. This function is not static.
 * @param start_tile The starting point of the rail.
 */
function cBuilder::RemoveRailLine(start_tile)
{
	if (start_tile == null) return;
	// Rail line removal works without a valid start tile if the root object's removelist is not empty, needed for save/load compatibility
	if (!AIMap.IsValidTile(start_tile) && root.removelist.len() == 0) return;
	// Starting date is needed to avoid infinite loops
	local startingdate = AIDate.GetCurrentDate();
	root.buildingstage = root.BS_REMOVING;
	// Get the four directions
	local all_vectors = [AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(-1, 0), AIMap.GetTileIndex(0, -1)];
	if (AIMap.IsValidTile(start_tile)) root.removelist = [start_tile];
	local tile = null;
	while (root.removelist.len() > 0) {
		// Avoid infinite loops
		if (AIDate.GetCurrentDate() - startingdate > 180) {
			LogError("It looks like I got into an infinite loop when removing line.");
			root.removelist = [];
			return;
		}
		tile = root.removelist.pop();
		// Step further if it is a tunnel or a bridge, because it takes two tiles
		if (AITunnel.IsTunnelTile(tile)) tile = AITunnel.GetOtherTunnelEnd(tile);
		if (AIBridge.IsBridgeTile(tile)) {
			root.railbridges.RemoveTile(tile);
			tile = AIBridge.GetOtherBridgeEnd(tile);
			root.railbridges.RemoveTile(tile);
		}
		if (!AIRail.IsRailDepotTile(tile)) {
			// Get the connecting rail tiles
			foreach (idx, vector in all_vectors) {
				if (MyAIRail.AreConnectedRailTiles(tile, tile + vector)) {
					root.removelist.push(tile + vector);
				}
			}
		}
		// Removing rail from a level crossing cannot be done with DemolishTile
		if (AIRail.IsLevelCrossingTile(tile)) {
			local track = AIRail.GetRailTracks(tile);
			if (!AIRail.RemoveRailTrack(tile, track)) {
				// Try again a few times if a road vehicle was in the way
				local counter = 0;
				AIController.Sleep(75);
				while (!AIRail.RemoveRailTrack(tile, track) && counter < 10) {
					counter++;
					AIController.Sleep(75);
				}
			}
		} else {
			AIRail.RemoveRailTrack(tile, AIRail.GetRailTracks(tile))
			if (!AITile.IsBuildable(tile)) cBuilder.WaitAndDemolish(tile);
		}
	}
	root.buildingstage = root.BS_NOTHING;
}

/**
 * Retry building a rail track after it was interrupted. The last three pieces of track
 * are removed, and then pathfinding is restarted from the other end.
 * @param prevprev The last successfully built piece of track.
 * @param pp1 The piece of track before prevprev.
 * @param pp2 The piece of track before pp1.
 * @param pp3 The piece of track before pp2. It is not removed.
 * @param head1 The other end to be connected.
 * @return True if the construction succeeded.
 */
function cBuilder::RetryRail(prevprev, pp1, pp2, pp3, head1, depot1, depot2)
{
	// Avoid infinite loops
	recursiondepth++;
	if (recursiondepth > 10) {
		LogError("It looks like I got into an infinite loop when retrying rail.");
		return cBuilder.RemoveTmpDepotsAndFalse();
	}
	// pp1 is null if no track was built at all
	if (pp1 == null) return cBuilder.RemoveTmpDepotsAndFalse();
	local head2 = [null, null];
	local tiles = [pp3, pp2, pp1, prevprev];
	// Set the rail end correctly
	foreach (idx, tile in tiles) {
		if (tile != null) {
			head2[1] = tile;
			break;
		}
	}
	tiles = [prevprev, pp1, pp2, pp3]
	foreach (idx, tile in tiles) {
		if (tile == head2[1]) {
			// Do not remove it if we reach the station
			break;
		} else {
			// Removing rail from a level crossing cannot be done with DemolishTile
			if (AIRail.IsLevelCrossingTile(tile)) {
				local track = AIRail.GetRailTracks(tile);
				if (!AIRail.RemoveRailTrack(tile, track)) {
					// Try again a few times if a road vehicle was in the way
					local counter = 0;
					AIController.Sleep(75);
					while (!AIRail.RemoveRailTrack(tile, track) && counter < 5) {
						counter++;
						AIController.Sleep(75);
					}
				}
			} else {
				cBuilder.WaitAndDemolish(tile);
			}
			head2[0] = tile;
		}
	}
	// Restart pathfinding from the other end
	if (cBuilder.BuildRail(head2, head1, depot1, depot2)) return !cBuilder.RemoveTmpDepotsAndFalse();
	else return cBuilder.RemoveTmpDepotsAndFalse();
}

/**
 * Upgrade a segment of normal rail to electrified rail from a given starting point.
 * Tiles which are reachable by a train from a given starting point are electrified,
 * including stations and depots. This function is not static.
 * @param start_tile The starting point from which rails are electrified.
 */
function cBuilder::ElectrifyRail(start_tile)
{
	// The starting date is needed to avoid infinite loops
	local startingdate = AIDate.GetCurrentDate();
	root.buildingstage = root.BS_ELECTRIFYING;
	// Get all four directions
	local all_vectors = [AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(-1, 0), AIMap.GetTileIndex(0, -1)];
	// If start_tile is not a valid tile we're probably loading a game
	if (AIMap.IsValidTile(start_tile)) root.removelist = [start_tile];
	local tile = null;
	while (root.removelist.len() > 0 ) {
		// Avoid infinite loops
		if (AIDate.GetCurrentDate() - startingdate > 360) {
			LogError("It looks like I got into an infinite loop when electrifying rail.");
			root.removelist = [];
			root.buildingstage = root.BS_NOTHING;
			return false;
		}
		tile = root.removelist.pop();
		// Step further if it is a tunnel or a bridge
		if (AITunnel.IsTunnelTile(tile)) tile = AITunnel.GetOtherTunnelEnd(tile);
		if (AIBridge.IsBridgeTile(tile)) tile = AIBridge.GetOtherBridgeEnd(tile);
		if (!AIRail.IsRailDepotTile(tile) && (AIRail.GetRailType(tile) != AIRail.GetCurrentRailType())) {
			// Check the neighboring rail tiles, only tiles from the old railtype are considered
			foreach (idx, vector in all_vectors) {
				if (MyAIRail.AreConnectedRailTiles(tile, tile + vector)) {
					root.removelist.push(tile + vector);
				}
			}
		}
		AIRail.ConvertRailType(tile, tile, AIRail.GetCurrentRailType());
	}
	root.buildingstage = root.BS_NOTHING;
	return true;
}

/**
 * Upgrade the registered rail bridges.
 * @return True if some bridge was upgraded.
 */
function cBuilder::UpgradeRailBridges()
{
	local count = 0;
	local railtype = AIRail.GetCurrentRailType();
	foreach (tile, route in root.railbridges) {
		if (!AIBridge.IsBridgeTile(tile) || !AITile.HasTransportType(tile, AITile.TRANSPORT_RAIL)) {
			LogDebug("Found a non-bridge tile in railbridge list with RouteID = " + route + "!");
			root.railbridges.RemoveItem(tile);
			continue;
		}
		AIRail.SetCurrentRailType(AIRail.GetRailType(tile));
		local otherend = AIBridge.GetOtherBridgeEnd(tile);
		local len = AIMap.DistanceManhattan(tile, otherend) + 1;
		local bridgelist = AIBridgeList_Length(len);
		local group = cBuilder.GetGroupFromRoute(route);
		bridgelist.Valuate(AIBridge.GetMaxSpeed);
		if (AIBridge.GetBridgeID(tile) == bridgelist.Begin()) continue;
		// Stop if we cannot afford it
		if (!Banker.SetMinimumBankBalance(AISettings.MiniumMoneyToUpgradeBridges() + AIBridge.GetPrice(bridgelist.Begin(), len))) {
			LogDebug("We don't have money to continue upgrading rail bridges!");
			continue;
		}
		if (AIBridge.GetMaxSpeed(AIBridge.GetBridgeID(tile)) < MyRoutes.GetRouteMaxCurrentSpeed(group) && AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridgelist.Begin(), tile, otherend)) count++;
	}
	AIRail.SetCurrentRailType(railtype);
	if (count > 0) {
		LogInfo("Upgrading rail bridges (" + root.railbridges.Count() + " bridges registered, " + count + " bridges upgraded)");
		return true;
	}
	return false;
}

/**
 * Get the platform length..
 * @param dist Distance between stations.
 * @param crg Cargo of source station.
 * @return Platform lenght, from 2 to 15.
 */
function cBuilder::GetPlatformLength(dist, crg)
{
	local platform = 2;
	local train_length = AISettings.GetCargoTrainMaxLength();
	local min_train_length = GetTrainMinLength(crg);
	if (AISettings.IsOldStyleRailLine()) {
		// Old TTD AI style.
		if (dist > 50) platform = 3;
		else platform = 2;;
	} else {
		local sdist = (dist / (AISettings.GetNumberOfPassingLanes(dist, true) + 1 )).tointeger();
		if (MyAICargo.IsPassengersCargo(crg)) {
			platform = AISettings.GetPassTrainMaxLength();
			if (dist < 90) platform--;
			if (dist < 65) platform--;
			//if (dist < 45) platform--;
		} else {
			if (train_length > 7) platform = 6;
			else platform = train_length - 1;
			local prod = AIIndustry.GetLastMonthProduction(src,crg);
			if (prod > 500) platform++;
			if (prod > 460) platform++;
			if (prod > 430) platform++;
			if (prod > 400) platform++;
			if (prod > 370) platform++;
			if (prod > 340) platform++;
			if (prod > 330 && sdist > 150) platform++;
			if (prod > 310) platform++;
			if (prod > 280) platform++;
			if (prod > 250) platform++;
			if (prod > 220) platform++;
			if (prod > 200 && sdist > 150) platform++;
			if (prod > 190) platform++;
			if (prod > 160) platform++;
			if (prod > 130) platform++;
			if (prod < 100) platform--;
			if (prod < 70) platform--;
			if (sdist > 120) platform++;
			if (sdist > 135) platform++;
			if (sdist > 150) platform++;
			if (sdist > 165) platform++;
			if (sdist > 180) platform++;
			if (sdist < 105) platform--;
			if (sdist < 90) platform--;
			if (sdist < 75) platform--;
			if (sdist < 60 && platform > 5) platform--;
		}
		if (sdist < 45) platform--;
		if (sdist < 30) platform--;
		if (platform > train_length) platform = train_length;
		if (platform < min_train_length) platform = min_train_length;
	}
	return MyMath.Min(MyAIGameSettings.EfectiveMaxTrainLength(), platform);
}

/**
 * Build a piece of rail, if we have money
 * @param arg1 first argument of AIRail.BuildRail
 * @param arg2 second argument of AIRail.BuildRail
 * @param arg3 thirth argument of AIRail.BuildRail
 * @return true if success
 */
function cBuilder::WaitAndBuildRail(arg1, arg2, arg3) {
	if (arg1 == null || arg2 == null || arg3 == null) return false;
	if (MyAIRail.CanBuildRail(arg1, arg2, arg3)) return cBuilder.WaitForMoney(MyAIRail.GetRailCost(arg1, arg2, arg3)) && AIRail.BuildRail(arg1, arg2, arg3);
	return false;
}

/**
 * Build a train depot, if we have money.
 * @param arg1 first argument of AIRail.BuildRailDepot.
 * @param arg2 second argument of AIRail.BuildRailDepot.
 * @return true if success.
 */
function cBuilder::WaitAndBuildRailDepot(arg1, arg2) {
	if (arg1 == null || arg2 == null) return false;
	if (MyAIRail.CanBuildRailDepot(arg1, arg2)) return cBuilder.WaitForMoney(MyAIRail.GetRailDepotCost(arg1, arg2)) && AIRail.BuildRailDepot(arg1, arg2);
	return false;
}

/**
 * Build and register a rail bridge, if we have money.
 * @param arg1 Start tile of the bridge.
 * @param arg2 End tile of the bridge.
 * @return true if success.
 */
function cBuilder::WaitAndBuildRailBridge(arg1, arg2)
{
	if (arg1 == null || arg2 == null) return false;
	if (!cBuilder.WaitAndBuildBridge(arg1, arg2, AIVehicle.VT_RAIL)) return false;
	root.railbridges.AddTile(arg1);
	root.railbridges.SetValue(arg1, root.routes.len());
	return true;
}

/**
 * Test if we can build a rail bridge.
 * @param arg1 first argument of AIRail.BuildRailBridge.
 * @param arg2 second argument of AIRail.BuildRailBridge.
 * @return true if success.
 */
function cBuilder::CanBuildRailBridge(arg1, arg2)
{
	return MyAIBridge.CanBuildRailBridge(arg1, arg2) && AIMap.DistanceManhattan(arg1, arg2) < root.routes_active;
}

/**
 * Build a rail tunnel, if we have money.
 * @param arg1 start tile of the tunnel.
 * @param arg2 other end of tunnel.
 * @return true if success.
 */
function cBuilder::WaitAndBuildRailTunnel(arg1, arg2)
{
	if (arg1 == null || arg2 == null) return false;
	if (MyAITunnel.CanBuildRailTunnel(arg1, arg2)) {
		if (!cBuilder.WaitForMoney(MyAITunnel.GetRailTunnelCost(arg1))) return false;
		return AITunnel.BuildTunnel(AIVehicle.VT_RAIL, arg1);
	}
	return false;
}

/**
 * Test if we can build a rail tunnel.
 * @param arg1 start tile of the tunnel
 * @param arg2 other end of tunnel
 * @return true if success
 */
function cBuilder::CanBuildRailTunnel(arg1, arg2) {
	if (MyAITunnel.CanBuildRailTunnel(arg1, arg2)) {
		if (arg2 == null) arg2 = AITunnel.GetOtherTunnelEnd(arg1);
		if (AIMap.DistanceManhattan(arg1, arg2) < root.routes_active) return true;
	}
	return false;
}

/**
 * Do all tests of a head of passinglane or station.
 * @param tile The tile where head starts.
 * @param vector The vector.
 * @param rvector The rvector.
 * @param otile The original tile (only CheckRawRailHead function).
 * @param loopcount Loop protection (only CheckRawRailHead function).
 * @return True if a head can be build.
 */
function cBuilder::NeedBridgeOrTunnel(tile, vector)		{ return !AITile.IsBuildable(tile + 2 * vector) || (MyAITile.IsDownslopeTile(tile + vector, -vector) && MyAITile.IsDownslopeTile(tile + 2 * vector, -vector)); }
function cBuilder::CheckRailHead(tile, vector, rvector)		{ return CheckRawRailHead(tile, vector, rvector, tile, 0); }
function cBuilder::CheckRawRailHead(tile, vector, rvector, otile, loopcount)
{
	if (loopcount > 12) return false;
	if (AIMap.DistanceManhattan(tile, otile) > 24) return false;
	if (AITile.GetMaxHeight(tile) - AITile.GetMaxHeight(otile) > 1 || AITile.GetMaxHeight(otile) - AITile.GetMaxHeight(tile) > 1) return false;
	if (!AITile.IsBuildable(tile)) return false;
	if (!AITile.IsBuildable(tile + vector)) return false;
	if (!CanBuildDiagonalRailHead(tile, vector, rvector)) {
		if (NeedBridgeOrTunnel(tile, vector)) {
			local count = 3;
			while (count < 14 && (!AITile.IsBuildable(tile + count * vector) || !AITile.IsBuildable(tile + count * vector + vector))) count++;
			if (count > 12) return false;
			if (!cBuilder.CanBuildRailBridge(tile + vector, tile + count * vector) && !cBuilder.CanBuildRailTunnel(tile + vector, tile + count * vector)) return false;
			if (!MyAIRail.CanBuildRail(tile + count * vector, tile + (count + 1) * vector, tile + (count + 1) * vector + rvector) && !MyAIRail.CanBuildRail(tile + count * vector, tile + (count + 1) * vector, tile + (count + 1) * vector - rvector) && !AITile.IsBuildable(tile + (count + 2) * vector)) return false;
			return (CheckRawRailHead(tile + count * vector, vector, rvector, otile, loopcount + 1) || CheckRawRailHead(tile + count * vector, vector, -rvector, otile, loopcount + 1));
		} else {
			if (!MyAIRail.CanBuildRail(tile, tile + vector, tile + 2 * vector)) return false;
			return (CheckRawRailHead(tile + vector, vector, rvector, otile, loopcount + 1) || CheckRawRailHead(tile + vector, vector, -rvector, otile, loopcount + 1));
		}
	}
	return true;
}

/**
 * Build tunnel or bridge at head of passinglane or station.
 * @param tile The tile where head starts.
 * @param vector The vector.
 * @param rvector The rvector.
 * @param isrecursive True if isn't the first invocation (only BuildRawRailHead function).
 * @return length of bridge/tunnel if can be build, null if can't, and zero if it isn't necessary.
 */
function cBuilder::BuildRailHead(tile, vector, rvector) 	{ return BuildRawRailHead(tile, vector, rvector, false); }
function cBuilder::BuildRawRailHead(tile, vector, rvector, isrecursive)
{
	//LogInfo("BHead tile X = " + AIMap.GetTileX(tile) + "   Y = " + AIMap.GetTileY(tile));
	local ret = 0, count = 0;
	if (!CanBuildDiagonalRailHead(tile, vector, rvector) && (!isrecursive || !CanBuildDiagonalRailHead(tile, vector, -rvector))) {
		if (NeedBridgeOrTunnel(tile, vector)) {
			count = 3;
			while (count < 14 && (!AITile.IsBuildable(tile + count * vector) || !AITile.IsBuildable(tile + count * vector + vector))) count++;
			if (count > 12) return null;
			if (!WaitAndBuildRailBridge(tile + vector, tile + count * vector) && !WaitAndBuildRailTunnel(tile + vector, tile + count * vector)) return null;
		} else {
			if (!MyAITile.IsDownslopeTile(tile + vector, -vector) || !cBuilder.CanBuildRailTunnel(tile + vector, null) || AIMap.DistanceManhattan(tile + vector, AITunnel.GetOtherTunnelEnd(tile + vector)) > 12) {
				if (!WaitAndBuildRail(tile, tile + vector, tile + 2 * vector)) return null;
				count++;
			}
		}
		if (count > 0) ret = BuildRawRailHead(tile + count * vector, vector, -rvector, true);
		if (ret == null) return null;
	}
	return count + ret;
}

/**
 * Check if diagonal exit from passing lane or station is possible..
 * @param tile The tile where head starts.
 * @param vector The vector.
 * @param rvector The rvector.
 * @return True if it is possible,
 * and zero if it isn't necessary.
 */
function cBuilder::CanBuildDiagonalRailHead(tile, vector, rvector)
{
	return (AITile.IsBuildable(tile + vector + rvector) && AITile.IsBuildable(tile + 2 * vector + rvector) && MyAIRail.CanBuildRail(tile, tile + vector, tile + vector + rvector) && MyAIRail.CanBuildRail(tile + vector, tile + vector + rvector, tile + 2 * vector + rvector));
}

/**
 * Returns de maximum or minimum length of trains.
 * @param crg Cargo to be considered,
 * @return Number of tiles.
 */
function cBuilder::GetTrainMaxLength(crg)
{
	local limit = MyAIGameSettings.EfectiveMaxTrainLength();
	return (MyAICargo.IsPassengersCargo(crg)) ? MyMath.Min(AISettings.GetPassTrainMaxLength(), limit) : MyMath.Min(AISettings.GetCargoTrainMaxLength(), limit);
}

function cBuilder::GetTrainMinLength(crg)
{
	local limit = MyAIGameSettings.EfectiveMaxTrainLength();
	return (MyAICargo.IsPassengersCargo(crg)) ? MyMath.Min(AISettings.GetPassTrainMinLength(), limit) : MyMath.Min(AISettings.GetCargoTrainMinLength(), limit);
}

