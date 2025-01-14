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

class cBuilder
{
		DIR_NE = 2;
		DIR_NW = 0;
		DIR_SE = 1;
		DIR_SW = 3;

		root = null; // Reference to the AI instance
		crglist = null;
		crg = null; // The list of possible cargoes; The cargo selected to be transported
		extracrg = null; // Extra cargo for dual cargo trains
		srclist = null;
		src = null; // The list of sources for the given cargo; The source (StationID/TownID) selected
		dstlist = null;
		srctile_tested = null; // Tested tiles where stations can be built.
		passtile_tested = null;
		dsttile_tested = null;
		dst = null; // The list of destinations for the given source; The destination (StationID/TownID) selected
		extra_src = null; // Extra source industry for dual cargo trains
		extra_dst = null; // Extra destination industry for dual cargo trains
		statile = null;
		sta2tile = null;
		stapasstile = null;
		deptile = null;
		deppasstile = null; // The tile of the station; The tile of the depot
		stavector = null;
		starvector = null;
		staoption = null; // Where exit is placed in station
		depoption = null; // Where depot is placed in station
		staoffset1 = null;
		staoffset2 = null; // Offset to place correctly passing lanes
		stafront = null;
		staextracrg = null; // Double cargo station
		sta2front = null;
		depfront = null; // The tile in front of the station; The tile in front of the depot
		passstafront = null;
		passdepfront = null; // The tile in front of the station; The tile in front of the depot
		statop = null;
		stabottom = null;
		frontfront = null; // Some variables needed to build a train station
		passfrontfront = null;
		front1 = null;
		front2 = null;
		passfront1 = null;
		passfront2 = null;
		lane2 = null;
		morefront = null; // Some more variables needed to build a double rail station
		passmorefront = null;
		stationdir = null; // The direction of the station
		railtype = null;
		stasrc = null;	  // Source station
		stadst = null;	  // Destination station
		stapass = null;	  // Passing station (if it is allowed)
		homedepot = null; // The depot at the source station
		slopes = null;    // Slopes (coded) from source to detination
		srcistown = null;
		passistown = null;
		dstistown = null; // Whether the source is a town; Whether the destination is a town
		srcplace = null;
		passplace = null;
		dstplace = null; // The place of the source (town/industry); The place of the destination (town/industry)
		group = null; // The current vehicle group
		vehtype = null; // The vehicle type selected
		double_srcsta = null; // Whether it is a double platform source station.
		double_dststa = null; // Whether it is a double platform destination station.
		trains = null; // Trains on a route
		road_vehs = null;
		holes = null;
		holestart = null;
		holeend = null; // Variables needed to correct roads which weren't built fully
		src_entry = null;
		dst_entry = null;
		pass_entry = null;
		pass_exit = null;
		src_offset = null;
		dst_offset = null;
		pass_offset = null;
		passinglanelist = null; // Passing lane starting/ending/blocking points
		ps1_entry = null; ps1_exit = null;
		ps2_entry = null; ps2_exit = null;
		ps3_entry = null; ps3_exit = null;
		ps4_entry = null; ps4_exit = null;
		ps5_entry = null; ps5_exit = null;
		ps6_entry = null; ps6_exit = null;
		ps7_entry = null; ps7_exit = null;
		ps8_entry = null; ps8_exit = null;
		ps9_entry = null; ps9_exit = null;
		ps10_entry = null; ps10_exit = null;
		ps11_entry = null; ps11_exit = null;
		ps12_entry = null; ps12_exit = null;
		ps13_entry = null; ps13_exit = null;
		ps14_entry = null; ps14_exit = null;
		ps15_entry = null; ps15_exit = null; // Passing lane starting/ending points
		bl1_entry = null ; bl1_exit = null;
		bl2_entry = null ; bl2_exit = null;
		bl3_entry = null ; bl3_exit = null;
		bl4_entry = null ; bl4_exit = null;
		bl5_entry = null ; bl5_exit = null;
		bl6_entry = null ; bl6_exit = null;
		bl7_entry = null ; bl7_exit = null;
		bl8_entry = null ; bl8_exit = null;
		bl9_entry = null ; bl9_exit = null;
		bl10_entry = null ; bl10_exit = null;
		bl11_entry = null ; bl11_exit = null;
		bl12_entry = null ; bl12_exit = null;
		bl13_entry = null ; bl13_exit = null;
		bl14_entry = null ; bl14_exit = null;
		bl15_entry = null ; bl15_exit = null; // Block tiles to aviod 90 grade turns
		segment = 0;
		builddepot1 = null;
		builddepot2 = null;
		recursiondepth = null; // The recursion depth used to catch infinite recursions
		path = null;
		constructor(that) {
			root = that;
			passinglanelist = MyAITileList_Passinglane();;
			src_entry = [null, null]; dst_entry = [null, null];
			pass_entry = [null, null]; pass_exit = [null, null];
			src_offset = [null, null]; dst_offset = [null, null]; pass_offset = [null, null];
			ps1_entry = [null, null]; ps1_exit = [null, null];
			ps2_entry = [null, null]; ps2_exit = [null, null];
			ps3_entry = [null, null]; ps3_exit = [null, null];
			ps4_entry = [null, null]; ps4_exit = [null, null];
			ps5_entry = [null, null]; ps5_exit = [null, null];
			ps6_entry = [null, null]; ps6_exit = [null, null];
			ps7_entry = [null, null]; ps7_exit = [null, null];
			ps8_entry = [null, null]; ps8_exit = [null, null];
			ps9_entry = [null, null]; ps9_exit = [null, null];
			ps10_entry = [null, null]; ps10_exit = [null, null];
			ps11_entry = [null, null]; ps11_exit = [null, null];
			ps12_entry = [null, null]; ps12_exit = [null, null];
			ps13_entry = [null, null]; ps13_exit = [null, null];
			ps14_entry = [null, null]; ps14_exit = [null, null];
			ps15_entry = [null, null]; ps15_exit = [null, null];
			bl1_entry = [null, null]; bl1_exit = [null, null];
			bl2_entry = [null, null]; bl2_exit = [null, null];
			bl3_entry = [null, null]; bl3_exit = [null, null];
			bl4_entry = [null, null]; bl4_exit = [null, null];
			bl5_entry = [null, null]; bl5_exit = [null, null];
			bl6_entry = [null, null]; bl6_exit = [null, null];
			bl7_entry = [null, null]; bl7_exit = [null, null];
			bl8_entry = [null, null]; bl8_exit = [null, null];
			bl9_entry = [null, null]; bl9_exit = [null, null];
			bl10_entry = [null, null]; bl10_exit = [null, null];
			bl11_entry = [null, null]; bl11_exit = [null, null];
			bl12_entry = [null, null]; bl12_exit = [null, null];
			bl13_entry = [null, null]; bl13_exit = [null, null];
			bl14_entry = [null, null]; bl14_exit = [null, null];
			bl15_entry = [null, null]; bl15_exit = [null, null];
		}

}

/**
 * The main function to build a new route.
 * @return True if a new route was built.
 */
function cBuilder::BuildSomething()
{
	local new_train = false;
	local success = true;
	local prod1_percent = 50;
	// Determine whether we're going for a subsidy
	local is_new_srcstation = true, is_new_dststation = true;
	if (cBuilder.CheckSubsidies()) {
		LogWarning("Trying to get subsidy:");
	} else {
		// Determine whether we're using aircraft
		if (UseAircraft()) vehtype = AIVehicle.VT_AIR;
		else vehtype = null;
		// Find a cargo, a source and a destination
		if (cBuilder.FindService()) {
			LogWarning("Trying to build new service:");
		} else {
			LogWarning("I can't found new service!");
			return false;
		}
	}
	root.buildingstage = root.BS_NOTHING;
	local srcname = null, dstname = null, passname = null;
	if (srcistown) srcname = AITown.GetName(src);
	else srcname = AIIndustry.GetName(src);
	if (dstistown) dstname = AITown.GetName(dst);
	else dstname = AIIndustry.GetName(dst);
	LogInfo(MyAICargo.GetName(crg) + " from " + srcname + " to " + dstname);
	// If not using aircraft, decide whether to use road or rail
	if (vehtype != AIVehicle.VT_AIR) vehtype = cBuilder.RoadOrRail();
	if (vehtype == null) {
		LogWarning("No vehicle type available!");
		return false;
	}
	LogDebug("Using vehtype " + vehtype);
	// Build HQ if not built already
	if (!AIMap.IsValidTile(MyAICompany.GetMyCompanyHQ())) {
		local place_id = src;
		local placeistown = srcistown;
		if (AISettings.BuildHQInTown()) {
			place_id = AITile.GetClosestTown(srcplace);
			placeistown = true;
		}
		root.BuildHQ(place_id, placeistown);
	}
	double_srcsta = false;
	double_dststa = false;
	local platform = null;
	local two_dst_ind = false;
	local extra_wagon = null, extra_station = null; 
	local dist = AIMap.DistanceManhattan(srcplace, dstplace);
	LogDebug("The distance between two places is " + dist);
	switch (vehtype) {

			/* Road building */
		case AIVehicle.VT_ROAD:
			LogDebug("Using road");
			if (dist > AISettings.GetRoadMaxDistance(root.buildcounter)) {
				LogWarning("This route would be too long for a road service: Distance is " + dist + ", Max Distance is " + AISettings.GetRoadMaxDistance(root.buildcounter));
				return false;
			}
			// Check road vehicles
			local veh = MyRoadVehs.ChooseRoadVeh(crg);
			if (veh == null) {
				LogWarning("No suitable road vehicle available!");
				return false;
			}
			// Single or double station?
			if (MyAICargo.IsFreightCargo(crg) && !MyAICargo.IsMailCargo(crg)) {
				if (cBuilder.CheckRoadStation(false, true) && cBuilder.CheckRoadStation(true, true)) {
					double_srcsta = true;
					double_dststa = true;
				}
			}
			// Check if possible to build the destination station
			if (!cBuilder.CheckRoadStation(false, double_dststa)) {
				LogWarning("Could not build destination road station at " + dstname);
				root.buildingstage = root.BS_NOTHING;
				return false;
			}
			// Try to build the source station
			if (cBuilder.BuildRoadStation(true, double_srcsta)) {
				root.buildingstage = root.BS_BUILDING;
				cBuilder.SetStationTmpName(stasrc, "SRC");
				LogInfo("New road station successfully built: " + AIStation.GetName(stasrc));
			} else {
				LogWarning("Cannot build source road station at " + srcname);
				root.buildingstage = root.BS_NOTHING;
				return false;
			}
			// Try to build the destination station
			if (cBuilder.BuildRoadStation(false, double_dststa)) {
				cBuilder.SetStationTmpName(stadst, "DST");
				LogInfo("New road station successfully built: " + AIStation.GetName(stadst));
			} else {
				LogWarning("Cannot build destination road station at " + dstname);
				cBuilder.DeleteRoadStation(stasrc);
				root.buildingstage = root.BS_NOTHING;
				return false;
			}
			road_vehs = cBuilder.NumRoadVehicles(AIMap.DistanceManhattan(AIStation.GetLocation(stasrc), AIStation.GetLocation(stadst)));
			if (double_srcsta && double_dststa) road_vehs = (road_vehs * 1.8).tointeger();

			// Build the road
			//root.buildingstage = root.BS_PATHFINDING;
			holes = [];
			if (cBuilder.BuildRoad(AIRoad.GetRoadStationFrontTile(AIStation.GetLocation(stadst)), AIRoad.GetRoadStationFrontTile(AIStation.GetLocation(stasrc)))) {
				LogInfo("Road built successfully!");
			} else {
				cBuilder.DeleteRoadStation(stasrc);
				cBuilder.DeleteRoadStation(stadst);
				root.buildingstage = root.BS_NOTHING;
				return false;
			}
			// Correct the road if needed
			recursiondepth = 0;
			while (holes.len() > 0) {
				recursiondepth++;
				if (!cBuilder.RepairRoute()) {
					cBuilder.DeleteRoadStation(stasrc);
					cBuilder.DeleteRoadStation(stadst);
					root.buildingstage = root.BS_NOTHING;
					return false;
				}
			}
			// Choose a road vehicle
			local veh = MyRoadVehs.ChooseRoadVeh(crg);
			if (veh == null) {
				LogWarning("No suitable road vehicle available!");
				return false;
			} else LogInfo("Selected road vehicle: " + AIEngine.GetName(veh));
			root.buildingstage = root.BS_NOTHING;
			group = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
			cBuilder.SetGroupName(group, crg, stasrc);
			if (cBuilder.BuildAndStartVehicles(veh, AISettings.GetStartRoadVehicles(), null)) LogInfo("Added " + AISettings.GetStartRoadVehicles() + " road vehicles to route: " + AIStation.GetName(stasrc) + " - " + AIStation.GetName(stadst));
			break;

			/* Railway building */

		case AIVehicle.VT_RAIL:
			// Decide whether to use double rails and number of trains and determine the length of the train station and number of passing lanes
			railtype = AIRail.GetCurrentRailType();
			trains = 2;
			slopes = 0;
			local passinglanes = 0;
			local passcrglabel, build_pass_station = false;
			passplace = null;
			stapass = null;
			extra_dst = null;
			local lane_length = AISettings.OversizePassingLane();
			if (AISettings.IsOldStyleRailLine()) {
                        	// Decide whether to use double rails
                        	if (dist > 90) double_srcsta = true;
                        	if (!double_srcsta) {
					LogDebug("Using single rail (Old TTD AI style)");
					trains = 1;
                        	} else {
					LogDebug("Using double rail (Old TTD AI style)");
					trains = 2;
					passinglanes = 2;
				}
			} else {
				if (MyAICargo.IsFreightCargo(crg)) {
					// Search more cargos
					if (AISettings.AllowDoubleCargoTrains() && !srcistown && !dstistown) {
						passistown = false;
						local crg2list = AICargoList();
						foreach (crg2, dummy in crg2list) {
							if (crg == crg2 || extracrg == crg2) continue;
							if (AIIndustry.GetLastMonthProduction(src, crg2) > 0 && AIIndustry.GetLastMonthTransported(src, crg2) < AISettings.GetMaxTransported()) {
								if (AIIndustry.IsCargoAccepted(dst, crg2)) {
									extracrg = crg2;
									passcrglabel = AICargo.GetCargoLabel(extracrg);
								} else {
									if (AISettings.AllowDoubleDestinationRailRoutes() && AIIndustry.GetDistanceManhattanToTile(src, dstplace) > AISettings.GetDoubleDestinationMinDistance()) {
										// Find another industry...
										local ind2list = AIIndustryList_CargoAccepting(crg2);
										ind2list.Valuate(AIIndustry.GetDistanceManhattanToTile, dstplace);
										ind2list.KeepBelowValue(AISettings.GetMaxDstPasDistance());
										if (ind2list.Count() > 0) {
											ind2list.Sort(AIList.SORT_BY_VALUE, true);
											//LogInfo("Found another industry near " + AIIndustry.GetName(dst));
											foreach (dst2, dummy in ind2list) {
												//LogInfo("Another industry " + AIIndustry.GetName(dst2) + " at "  + AIIndustry.GetDistanceManhattanToTile(dst2, dstplace) + " tiles.");
												if (AIIndustry.GetDistanceManhattanToTile(src, AIIndustry.GetLocation(dst2)) < AISettings.GetDoubleDestinationMinDistance()) continue;
												extracrg = crg2;
												extra_dst = dst2;
												passplace = AIIndustry.GetLocation(extra_dst);
												passname = AIIndustry.GetName(extra_dst);
												passcrglabel = MyAICargo.GetName(extracrg);
											}
											if (extra_dst != null &&  AIIndustry.GetDistanceManhattanToTile(extra_dst, srcplace) > AIIndustry.GetDistanceManhattanToTile(dst, srcplace)) {
												SwapDestinationStationVars();
												dist = AIMap.DistanceManhattan(srcplace, dstplace);
												//LogInfo("Swapping destination industry variables because distance from source");
											}
											dstname = AIIndustry.GetName(dst);
										}
									}
								}
							}
						}
					}
					double_srcsta = true;
					passinglanes = AISettings.GetNumberOfPassingLanes(dist, true);
					trains = passinglanes + 2;
					LogDebug("Using double platform at source station for full loading cargo");
				} else {
					passinglanes = AISettings.GetNumberOfPassingLanes(dist, false);
					if (AISettings.ArePassengerStationsDouble() && dist > 140) {
						double_srcsta = true;
						double_dststa = true;
						trains = passinglanes + 3;
						LogDebug("Using double platform stations for passengers and mail");
					} else {
						trains = passinglanes + 1;
						LogDebug("Using single platform stations for passengers and mail");
					}
				}
			}
			// Some adjustments
			if (passinglanes > 1) {
				local dist_x = MyMath.Abs(AIMap.GetTileX(srcplace) - AIMap.GetTileX(dstplace));
				local dist_y = MyMath.Abs(AIMap.GetTileY(srcplace) - AIMap.GetTileY(dstplace));
				// Is diagonal mostly line?
       				if ((dist_x > dist_y && 2 * dist_y > dist_x) || (dist_y > dist_x && 2 * dist_x > dist_y)) {
					passinglanes--;
					trains--;
					if (passinglanes > 3) {
						if (passinglanes > 6) {
							passinglanes--;
							trains--;
						}
						passinglanes--;
						trains--;
					}
				}
			}

			// Fast PathFinding & new passenger passinglanes model.
			if (dist > 85 && AISettings.FastRailPathFinder()) { 
				passinglanes = passinglanes * 2 + 1;
				if (MyAICargo.IsPassengersCargo(crg)) trains++;
			}

                       	// Determine the length of the train station and passing lanes
			platform = GetPlatformLength(dist, crg);
			local one_cargo_platform = platform;
			if (MyAICargo.IsPassengersCargo(crg)) {
				lane_length += platform;
			} else {
				extra_wagon = MyTrains.ChooseWagon(extracrg, root.engineblacklist);
				if (extracrg != null && extra_wagon != null && GetPlatformLength(dist, extracrg) + platform <= AISettings.GetCargoTrainMaxLength() && MyAIGameSettings.EfectiveMaxTrainLength() >= GetPlatformLength(dist, extracrg) + platform) {
					platform += GetPlatformLength(dist, extracrg);
					LogDebug("Trying to build dual cargo line");
				} else extracrg = null;
				lane_length = platform;
			}

			// Choose wagon and locomotive (preventive)
			local wagon = MyTrains.ChooseWagon(crg, root.engineblacklist);
			if (wagon == null) {
				LogWarning("No suitable wagon available!");
				return false;
			}
			local wagonminspeed = wagon;
			local wagoncrg = crg;
			local extra_wagon;
			if (extracrg != null) {
				extra_wagon = MyTrains.ChooseWagon(extracrg, root.engineblacklist);
				if (extra_wagon == null) {
					platform = one_cargo_platform;
					lane_length = platform;
					extracrg = null;
					extra_dst = null;
					passplace = null;
				} else {
					if (AIEngine.GetMaxSpeed(wagon) > AIEngine.GetMaxSpeed(extra_wagon)) {
						wagonminspeed = extra_wagon;
						wagoncrg = extracrg;
					}
				}
			}
			local engine = MyTrains.ChooseTrainEngine(wagoncrg, dist, wagonminspeed, platform * 2 - 1, root.engineblacklist);
			if (engine == null) {
				LogWarning("No suitable engine available!");
				return false;
			}

			local temp_ps = null;
			root.buildingstage = root.BS_NOTHING;

			// Checks before build anything

			// Check the extra destination industry for dual cargo lines with one destination station.
			if (extra_dst != null && extracrg != null) {
				if (cBuilder.CheckSingleRailDestinationStation(platform, true)) {
					dst_offset = [staoffset1, staoffset2];
					two_dst_ind = true;
					LogInfo("Linking destination station to two industries");
					passinglanes--;
					trains--;
					if (AISettings.FastRailPathFinder()) passinglanes--;
				}
				root.manager.MainLoop();
			}
			// Check the extra destination station for dual cargo lines with two destination stations.
			if (extra_dst != null && extracrg != null && !two_dst_ind) {
				if (cBuilder.CheckDoubleRailPassingStation(platform) != null) pass_offset = [staoffset1, staoffset2];
				else {
					platform = one_cargo_platform;
					lane_length = platform;
					extracrg = null;
					extra_dst = null;
					passplace = null;
				}
				root.manager.MainLoop();
			}
			// Check the destination station for dual cargo lines.
			if (extracrg != null) {
				if (cBuilder.CheckSingleRailDestinationStation(platform, two_dst_ind)) dst_offset = [staoffset1, staoffset2];
				else {
					platform = one_cargo_platform;
					lane_length = platform;
					extracrg = null;
				}
				root.manager.MainLoop();
			}
			// Check the source station for dual cargo lines.
			if (extracrg != null) {
				// Double rail station, for full load cargo
				if (cBuilder.CheckDoubleRailSourceStation(platform, passinglanes)) src_offset = [staoffset1, staoffset2];
				else {
					platform = one_cargo_platform;
					lane_length = platform;
					extracrg = null;
				}
				root.manager.MainLoop();
			}
			// Check height of stations
			if (extracrg != null) {
				local maxZ = AISettings.MaxDiffPassingLaneHeigh();
				local dstZ = AITile.GetMaxHeight(dst_offset[0]);
				local srcZ = AITile.GetMaxHeight(src_offset[0]);
				if (extra_dst != null && !two_dst_ind) {
					local passZ = AITile.GetMaxHeight(pass_offset[0]);
					if ((srcZ > passZ && srcZ - passZ > maxZ * (passinglanes + 1)) || (srcZ < passZ && passZ - srcZ > maxZ * (passinglanes + 1)) || (dstZ > passZ && dstZ - passZ > maxZ) || (dstZ < passZ && passZ - dstZ > maxZ)) {
						platform = one_cargo_platform;
						lane_length = platform;
						extracrg = null;
						extra_dst = null;
						passplace = null;
					}
				} else {
					if ((srcZ > dstZ && srcZ - dstZ > maxZ * (passinglanes + 1)) || (srcZ < dstZ && dstZ - srcZ > maxZ * (passinglanes + 1))) {
						platform = one_cargo_platform;
						lane_length = platform;
						extracrg = null;
					}
				}
			}
			// Check Passing lanes if we need it...
			local counter = 14, last_passinglane = dst_offset;
			local fakelane_length = MyAICargo.IsPassengersCargo(crg) ? AISettings.GetPassTrainMinLength() : AISettings.GetCargoTrainMinLength();
			local last_passinglane_fake = true;
			local passinglane_tilelist = MyAITileList();
			if (extracrg != null) {
				if (extra_dst != null && !two_dst_ind) last_passinglane = pass_offset;
				while (extracrg != null && counter >= 0) {
					if (passinglanes > counter) {
						if (AISettings.FastRailPathFinder()) {
							if (!last_passinglane_fake) last_passinglane_fake = true;
							else last_passinglane_fake = false;
							if (MyAICargo.IsPassengersCargo(crg) && passinglanes == 1) last_passinglane_fake = false;
						}
						temp_ps = cBuilder.CheckPassingLaneSection(last_passinglane, src_offset, counter + 1, last_passinglane_fake ? fakelane_length : lane_length, last_passinglane_fake);
						if (temp_ps == null) {
							platform = one_cargo_platform;
							lane_length = platform;
							extracrg = null;
							extra_dst = null;
							passplace = null;
							passinglane_tilelist.Clear();
							LogDebug("Could not build " + (passinglanes - counter) + " of " + passinglanes + " passing lane section");
						} else {
							LogDebug("Testing if we can build a two cargo passing lane " + (passinglanes - counter) + " of " + passinglanes + ": Yes, it is possible");
							slopes = MyMath.Max(slopes, cBuilder.GetSlopes(temp_ps[0][0], last_passinglane[0]));
							if (MyAICargo.IsPassengersCargo(crg)) slopes = MyMath.Max(slopes, cBuilder.GetSlopes(last_passinglane[0], temp_ps[0][0]));
							if (counter == 0) slopes = MyMath.Max(slopes, cBuilder.GetSlopes(src_offset[0], temp_ps[0][0]));
							if (MyAICargo.IsPassengersCargo(crg) && counter == 0) slopes = MyMath.Max(slopes, cBuilder.GetSlopes(temp_ps[0][0], src_offset[0]));
							last_passinglane = [temp_ps[0][0], temp_ps[0][1]];
							passinglane_tilelist.AddItem(temp_ps[0][0], counter);
						}
						root.manager.MainLoop();
					}
					counter--;
				}
			}

			// Check the source and destination stations for one-cargo trains.
			if (extracrg == null) {
				// Check the destination station
				if (!double_srcsta || (!AISettings.IsOldStyleRailLine() && !double_dststa)) {
					if (cBuilder.CheckSingleRailDestinationStation(platform)) dst_offset = [staoffset1, staoffset2];
					else {
						LogWarning("Could not build single and " + platform + " tiles long destination rail station at " + dstname);
						return false;
					}
				} else {
					if (cBuilder.CheckDoubleRailDestinationStation(platform, passinglanes)) dst_offset = [staoffset1, staoffset2];
					else {
						LogWarning("Could not build destination double and " + platform + " tiles long rail station at " + dstname);
						return false;
					}
					root.manager.MainLoop();
				}

				// Check the source station
				if (!double_srcsta) {
					// Single rail station, passengers and mail
					if (cBuilder.CheckSingleRailSourceStation(platform)) src_offset = [staoffset1, staoffset2];
					else {
						LogWarning("Could not build source single and " + platform + " tiles long rail station at " + srcname);
						return false;
					}
				} else {
					// Double rail station, for full load cargo
					if (cBuilder.CheckDoubleRailSourceStation(platform, passinglanes)) src_offset = [staoffset1, staoffset2];
					else {
						LogWarning("Could not build source double and " + platform + " tiles long rail station at " + srcname);
						return false;
					}
					root.manager.MainLoop();
				}

				// Check height of stations
				local maxZ = AISettings.MaxDiffPassingLaneHeigh();
				local dstZ = AITile.GetMaxHeight(dst_offset[0]);
				local srcZ = AITile.GetMaxHeight(src_offset[0]);
				if ((srcZ > dstZ && srcZ - dstZ > maxZ * (passinglanes + 1)) || (srcZ < dstZ && dstZ - srcZ > maxZ * (passinglanes + 1))) {
					LogWarning("The diference of height of two rail stations is too high");
					return false;
				}

				// Check Passing lanes if we need it...
				counter = 14;
				last_passinglane_fake = MyAICargo.IsPassengersCargo(crg);
				last_passinglane = dst_offset;
				while (counter >= 0) {
					if (passinglanes > counter) {
						if (AISettings.FastRailPathFinder()) {
							if (!last_passinglane_fake) last_passinglane_fake = true;
							else last_passinglane_fake = false;
							if (MyAICargo.IsPassengersCargo(crg) && passinglanes == 1) last_passinglane_fake = false;
						}
						temp_ps = cBuilder.CheckPassingLaneSection(last_passinglane, src_offset, counter + 1, last_passinglane_fake ? fakelane_length : lane_length, last_passinglane_fake);
						if (temp_ps == null) {
							LogWarning("Could not build " + (passinglanes - counter) + " of " + passinglanes + " passing lane section");
							return false;
						} else {
							LogDebug("Testing if we can build passing lane " + (passinglanes - counter) + " of " + passinglanes + ": Yes, it is possible");
							slopes = MyMath.Max(slopes, cBuilder.GetSlopes(temp_ps[0][0], last_passinglane[0]));
							if (MyAICargo.IsPassengersCargo(crg)) slopes = MyMath.Max(slopes, cBuilder.GetSlopes(last_passinglane[0], temp_ps[0][0]));
							if (counter == 0) slopes = MyMath.Max(slopes, cBuilder.GetSlopes(src_offset[0], temp_ps[0][0]));
							if (MyAICargo.IsPassengersCargo(crg) && counter == 0) slopes = MyMath.Max(slopes, cBuilder.GetSlopes(temp_ps[0][0], src_offset[0]));
							last_passinglane = [temp_ps[0][0], temp_ps[0][1]];
							passinglane_tilelist.AddItem(temp_ps[0][0], counter);
						}
						root.manager.MainLoop();
					}
					counter--;
				}
			} else {
				if (extra_dst == null || two_dst_ind) LogInfo(MyAICargo.GetName(extracrg) + " from " + srcname + " to " + dstname);
				else LogInfo(passcrglabel + " from " + srcname + " to " + passname);
			}

			if (!AreIndustriesAlive()) return false;

			// Well, all tests passed ok, we can build all stations and passing lanes.
			
			// Build the destination station
			passinglanelist.Clear();
			local dst_height;
			if (!double_srcsta || (!AISettings.IsOldStyleRailLine() && !double_dststa)) {
				if (cBuilder.BuildSingleRailDestinationStation(platform, two_dst_ind)) {
					dst_entry = [frontfront, stafront];
					cBuilder.SetStationTmpName(stadst, "DST");
					LogInfo("New single and " + platform + " tiles long destination rail station successfully built: " + AIStation.GetName(stadst));
				} else {
					LogWarning("I can't build single and " + platform + " tiles long destination rail station at " + dstname);
					root.buildingstage = root.BS_NOTHING;
					return false;
				}
			} else {
				if (cBuilder.BuildDoubleRailDestinationStation(platform, passinglanes)) {
					dst_entry = [morefront, frontfront];
					cBuilder.SetStationTmpName(stadst, "DST");
					LogInfo("New double and " + platform + " tiles long destination rail station successfully built: " + AIStation.GetName(stadst));
				} else {
					LogWarning("I can't build destination double and " + platform + " tiles long station at " + dstname);
					root.buildingstage = root.BS_NOTHING;
					return false;
				}
			}
			dst_offset = [staoffset1, staoffset2];
			dst_height = AITile.GetMaxHeight(staoffset1);
			last_passinglane = dst_offset;
			root.manager.MainLoop();
			success = success && AreIndustriesAlive();

			// Build the passing destination station
			if (success && extra_dst != null && extracrg != null && !two_dst_ind) {
				temp_ps = cBuilder.BuildDoubleRailPassingStation(platform);
				if (temp_ps != null) {
					pass_entry = [morefront, frontfront];
					pass_offset = [staoffset1, staoffset2];
					last_passinglane = pass_offset;
					cBuilder.SetStationTmpName(stapass, "PAS");
					LogInfo("New double and " + platform + " tiles long passing rail station successfully built: " + AIStation.GetName(stapass));
					build_pass_station = true;
					if (passinglanes < 15) {
						passinglanes++;
						trains++;
					}
				} else {
					LogWarning("Could not build single and " + platform + " tiles long passing rail station at " + dstname);
					root.buildingstage = root.BS_NOTHING;
					extra_dst = null;
					success = false;
				}
				if (dst_height > AITile.GetMaxHeight(staoffset1)) slopes = MyMath.Max(slopes, 2);
				if (dst_height + 2 * (passinglanes + 1) > AITile.GetMaxHeight(staoffset1)) slopes = MyMath.Max(slopes, 3);
				if (dst_height == AITile.GetMaxHeight(staoffset1)) slopes = MyMath.Max(slopes, 1);
				root.manager.MainLoop();
			}
			success = success && AreIndustriesAlive();

			// Build the source station
			if (success) {
				if (!double_srcsta) {
					// Single rail station, passengers and mail
					if (cBuilder.BuildSingleRailSourceStation(platform)) {
						src_entry = [frontfront, stafront];
						src_offset = [staoffset1, staoffset2];
						root.buildingstage = root.BS_BUILDING;
						cBuilder.SetStationTmpName(stasrc, "SRC");
						LogInfo("New single and " + platform + " tiles long source rail station successfully built: " + AIStation.GetName(stasrc));
					} else {
						LogWarning("Could not build source single and " + platform + " tiles long rail station at " + srcname);
						root.buildingstage = root.BS_NOTHING;
						success = false;
					}
				} else {
					// Double rail station, for full load cargo
					if (cBuilder.BuildDoubleRailSourceStation(platform, passinglanes)) {
						src_entry = [morefront, frontfront];
						src_offset = [staoffset1, staoffset2];
						root.buildingstage = root.BS_BUILDING;
						cBuilder.SetStationTmpName(stasrc, "SRC");
						LogInfo("New double and " + platform + " tiles long source rail station successfully built: " + AIStation.GetName(stasrc));
					} else {
						LogWarning("Could not build source double and " + platform + " tiles long rail station at " + srcname);
						root.buildingstage = root.BS_NOTHING;
						success = false;
					}
				}
			}
			if (dst_height > AITile.GetMaxHeight(staoffset1)) slopes = MyMath.Max(slopes, 2);
			if (dst_height + 2 * (passinglanes + 1) > AITile.GetMaxHeight(staoffset1)) slopes = MyMath.Max(slopes, 3);
			if (dst_height == AITile.GetMaxHeight(staoffset1)) slopes = MyMath.Max(slopes, 1);
			success = success && AreIndustriesAlive();
			root.manager.MainLoop();
			local last_passinglane_fake = build_pass_station ? true : MyAICargo.IsPassengersCargo(crg);

			// Passing lanes if we need it...
			counter = 14
			while (counter >= 0) {
				if (success && passinglanes > counter) {
					local tested_tile = MyAITileList.GetTileByValue(counter, passinglane_tilelist);
					if (AISettings.FastRailPathFinder()) {
						if (!last_passinglane_fake) last_passinglane_fake = true;
						else last_passinglane_fake = false;
						if (MyAICargo.IsPassengersCargo(crg) && passinglanes == 1) last_passinglane_fake = false;
					}
					if (!build_pass_station)
						temp_ps = cBuilder.BuildPassingLaneSection(last_passinglane, src_offset, counter + 1, last_passinglane_fake ? fakelane_length : lane_length, last_passinglane_fake, tested_tile);
					if (temp_ps == null) {
						LogWarning("Could not build " + (passinglanes - counter) + " of " + passinglanes + " passing lane section");
						success = false;
					} else {
						if (build_pass_station) build_pass_station = false;
						else LogInfo("Passing lane " + (passinglanes - counter) + " of " + passinglanes + " built successfully!");
						if (AIMap.DistanceManhattan(src_entry[0], temp_ps[0][0]) < AIMap.DistanceManhattan(src_entry[0], temp_ps[1][0])) {
							passinglanelist.AddPassinglane(counter, temp_ps[0][0], temp_ps[0][1], temp_ps[2][0], temp_ps[2][1], temp_ps[1][0], temp_ps[1][1], temp_ps[3][0], temp_ps[3][1]);
						} else {
							passinglanelist.AddPassinglane(counter, temp_ps[1][0], temp_ps[1][1], temp_ps[3][0], temp_ps[3][1], temp_ps[0][0], temp_ps[0][1], temp_ps[2][0], temp_ps[2][1]);
						}
						last_passinglane = [temp_ps[4][0], temp_ps[4][1]];
						root.manager.MainLoop();
					}
					// Register the passing lanes
					if (counter == 14) {
						ps15_entry = passinglanelist.GetEntryPair(14);
						ps15_exit = passinglanelist.GetExitPair(14);
						bl15_entry = passinglanelist.GetBlockEntryPair(14);
						bl15_exit = passinglanelist.GetBlockExitPair(14);
					}
					if (counter == 13) {
						ps14_entry = passinglanelist.GetEntryPair(13);
						ps14_exit = passinglanelist.GetExitPair(13);
						bl14_entry = passinglanelist.GetBlockEntryPair(13);
						bl14_exit = passinglanelist.GetBlockExitPair(13);
					}
					if (counter == 12) {
						ps13_entry = passinglanelist.GetEntryPair(12);
						ps13_exit = passinglanelist.GetExitPair(12);
						bl13_entry = passinglanelist.GetBlockEntryPair(12);
						bl13_exit = passinglanelist.GetBlockExitPair(12);
					}
					if (counter == 11) {
						ps12_entry = passinglanelist.GetEntryPair(11);
						ps12_exit = passinglanelist.GetExitPair(11);
						bl12_entry = passinglanelist.GetBlockEntryPair(11);
						bl12_exit = passinglanelist.GetBlockExitPair(11);
					}
					if (counter == 10) {
						ps11_entry = passinglanelist.GetEntryPair(10);
						ps11_exit = passinglanelist.GetExitPair(10);
						bl11_entry = passinglanelist.GetBlockEntryPair(10);
						bl11_exit = passinglanelist.GetBlockExitPair(10);
					}
					if (counter == 9) {
						ps10_entry = passinglanelist.GetEntryPair(9);
						ps10_exit = passinglanelist.GetExitPair(9);
						bl10_entry = passinglanelist.GetBlockEntryPair(9);
						bl10_exit = passinglanelist.GetBlockExitPair(9);
					}
					if (counter == 8) {
						ps9_entry = passinglanelist.GetEntryPair(8);
						ps9_exit = passinglanelist.GetExitPair(8);
						bl9_entry = passinglanelist.GetBlockEntryPair(8);
						bl9_exit = passinglanelist.GetBlockExitPair(8);
					}
					if (counter == 7) {
						ps8_entry = passinglanelist.GetEntryPair(7);
						ps8_exit = passinglanelist.GetExitPair(7);
						bl8_entry = passinglanelist.GetBlockEntryPair(7);
						bl8_exit = passinglanelist.GetBlockExitPair(7);
					}
					if (counter == 6) {
						ps7_entry = passinglanelist.GetEntryPair(6);
						ps7_exit = passinglanelist.GetExitPair(6);
						bl7_entry = passinglanelist.GetBlockEntryPair(6);
						bl7_exit = passinglanelist.GetBlockExitPair(6);
					}
					if (counter == 5) {
						ps6_entry = passinglanelist.GetEntryPair(5);
						ps6_exit = passinglanelist.GetExitPair(5);
						bl6_entry = passinglanelist.GetBlockEntryPair(5);
						bl6_exit = passinglanelist.GetBlockExitPair(5);
					}
					if (counter == 4) {
						ps5_entry = passinglanelist.GetEntryPair(4);
						ps5_exit = passinglanelist.GetExitPair(4);
						bl5_entry = passinglanelist.GetBlockEntryPair(4);
						bl5_exit = passinglanelist.GetBlockExitPair(4);
					}
					if (counter == 3) {
						ps4_entry = passinglanelist.GetEntryPair(3);
						ps4_exit = passinglanelist.GetExitPair(3);
						bl4_entry = passinglanelist.GetBlockEntryPair(3);
						bl4_exit = passinglanelist.GetBlockExitPair(3);
					}
					if (counter == 2) {
						ps3_entry = passinglanelist.GetEntryPair(2);
						ps3_exit = passinglanelist.GetExitPair(2);
						bl3_entry = passinglanelist.GetBlockEntryPair(2);
						bl3_exit = passinglanelist.GetBlockExitPair(2);
					}
					if (counter == 1) {
						ps2_entry = passinglanelist.GetEntryPair(1);
						ps2_exit = passinglanelist.GetExitPair(1);
						bl2_entry = passinglanelist.GetBlockEntryPair(1);
						bl2_exit = passinglanelist.GetBlockExitPair(1);
					}
					if (counter == 0) {
						ps1_entry = passinglanelist.GetEntryPair(0);
						ps1_exit = passinglanelist.GetExitPair(0);
						bl1_entry = passinglanelist.GetBlockEntryPair(0);
						bl1_exit = passinglanelist.GetBlockExitPair(0);
					}
					success = success && AreIndustriesAlive();
				}
				counter--;
			}

			local src_block = [null, null];
			local dst_block = [null, null];
			if (success && passinglanes > 0) {
				// Build the rail between the last passing lane section and the destination station
				recursiondepth = 0;
				local ps_id = passinglanes - 1;
				if (cBuilder.BuildRail(passinglanelist.GetExitPair(ps_id), dst_entry, passinglanelist.GetBlockExitPair(ps_id), dst_block)) LogInfo("Rail 1 of " + (passinglanes + 1) + " built successfully!");
				else success = false;
				segment++;
				success = success && AreIndustriesAlive();
				// Build the rail between the source station and the (first) passing lane section
				recursiondepth = 0;
				if (success && cBuilder.BuildRail(passinglanelist.GetEntryPair(0), src_entry, passinglanelist.GetBlockEntryPair(0), src_block)) LogInfo("Rail 2 of " + (passinglanes + 1) + " built successfully!");
				else success = false;
				segment++;
				success = success && AreIndustriesAlive();
				// Build the rail between the two passing lane sections
				if (passinglanes > 1) {
					for (local count = 1; success && count < passinglanes; count++) {
						recursiondepth = 0;
						if (cBuilder.BuildRail(passinglanelist.GetExitPair(count - 1), passinglanelist.GetEntryPair(count), passinglanelist.GetBlockExitPair(count - 1), passinglanelist.GetBlockEntryPair(count)))
							LogInfo("Rail " + (count + 2) + " of " + (passinglanes + 1) + " built successfully!");
						else success = false;
						segment++;
						success = success && AreIndustriesAlive();
					}
				}
			} else {
				// Build the rail between stations
				recursiondepth = 0;
				if (success && cBuilder.BuildRail(dst_entry, src_entry, src_block, dst_block)) LogInfo("Rail 1 of 1 built successfully!");
				else success = false;
				segment++;
				success = success && AreIndustriesAlive();
			}
			if (!success) {
				cBuilder.DeleteRailStation(stasrc);
				cBuilder.DeleteRailStation(stadst);
				if (extracrg != null) cBuilder.DeleteRailStation(stapass);
				if (temp_ps != null) {
					cBuilder.RemoveRailLine(temp_ps[0][1]);
					cBuilder.RemoveRailLine(temp_ps[1][1]);
				}
				for (local count = 0; count < passinglanes; count++) {
					cBuilder.RemoveRailLine(passinglanelist.GetFrontEntry(count));
					cBuilder.RemoveRailLine(passinglanelist.GetFrontExit(count));
				}
				return false;
			}

			// Choose (again) wagon(s) and locomotive
			wagon = MyTrains.ChooseWagon(crg, root.engineblacklist);
			if (wagon == null) {
				LogWarning("No suitable wagon available!");
				return false;
			} else LogInfo("Chosen wagon: " + AIEngine.GetName(wagon));
			if (extracrg != null) {
				extra_wagon = MyTrains.ChooseWagon(extracrg, root.engineblacklist);
				if (extra_wagon == null) {
					LogWarning("No suitable wagon available!");
					return false;
				} else {
					LogInfo("Chosen wagon: " + AIEngine.GetName(extra_wagon));
					if (AIEngine.GetMaxSpeed(wagon) > AIEngine.GetMaxSpeed(extra_wagon)) {
						wagonminspeed = extra_wagon;
						wagoncrg = extracrg;
					}
					prod1_percent = MyAIIndustry.GetProductionPercentage(src, crg, extracrg);
				}
			} else extra_wagon = null;
			engine = MyTrains.ChooseTrainEngine(wagoncrg, dist, wagonminspeed, platform * 2 - 1, root.engineblacklist);
			if (engine == null) {
				LogWarning("No suitable engine available!");
				return false;
			} else LogInfo("Chosen engine: " + AIEngine.GetName(engine));
			group = AIGroup.CreateGroup(AIVehicle.VT_RAIL);
			// This is necesary for loaded games, if are waiting for money after build a route.
			root.buildingstage = root.BS_PATHFINDING;
			if (cBuilder.BuildAndStartTrains(trains, 2 * platform - 2, engine, wagon, extra_wagon, null, true, prod1_percent)) new_train = true;
			break;

			/* Aircraft building */

		case AIVehicle.VT_AIR:
			LogDebug("Using air");
			// Exit if no planes are available
			local planelist = AIEngineList(AIVehicle.VT_AIR);
			if (planelist.Count() == 0) {
				LogWarning("No aircraft available!");
				return false;
			}
			// Depending on the type of the airports, choose a plane
			local planetype = MyPlanes.ChoosePlane(crg, false, AIOrder.GetOrderDistance(AIVehicle.VT_AIR, srcplace, dstplace), false);
			if (planetype == null) {
				LogWarning("No suitable plane available!");
				root.buildingstage = root.BS_NOTHING;
				return false;
			}
			// Build the source airport if it doesn't exist yet
			if (!root.airports.HasItem(src)) {
				if (cBuilder.BuildAirport(true)) {
					root.buildingstage = root.BS_BUILDING;
					cBuilder.SetAirportName(stasrc);
					LogInfo("New airport successfully built: " + AIStation.GetName(stasrc));
				} else {
					LogWarning("Could not build source airport at " + srcname);
					root.buildingstage = root.BS_NOTHING;
					return false;
				}
			} else {
				stasrc = root.airports.GetValue(src);
				homedepot = AIAirport.GetHangarOfAirport(AIStation.GetLocation(stasrc));
				LogInfo("Using existing airport at " + AITown.GetName(src) + ": " + AIStation.GetName(stasrc));
				is_new_srcstation = false;
			}
			// Build the destination airport if it doesn't exist yet
			if (!root.airports.HasItem(dst)) {
				if (cBuilder.BuildAirport(false)) {
					cBuilder.SetAirportName(stadst);
					LogInfo("New airport successfully built: " + AIStation.GetName(stadst));
				} else {
					LogWarning("Could not build destination airport at " + dstname);
					// Try to build a route with source airport
					if (root.airports.Count() > 2 && GetExistingAirport(src)) {
						stadst = root.airports.GetValue(dst);
						LogInfo("Using alternative airport at " + AITown.GetName(dst) + ": " + AIStation.GetName(stadst));
						is_new_dststation = false;
					} else {
						cBuilder.DeleteAirport(stasrc);
						root.buildingstage = root.BS_NOTHING;
						return false;
					}
				}
			} else {
				stadst = root.airports.GetValue(dst);
				LogInfo("Using existing airport at " + AITown.GetName(dst) + ": " + AIStation.GetName(stadst));
				is_new_dststation = false;
			}
			// Depending on the type of the airports, choose a plane
			local is_small = MyAIAirport.IsSmallAirport(AIAirport.GetAirportType(AIStation.GetLocation(stasrc))) || MyAIAirport.IsSmallAirport(AIAirport.GetAirportType(AIStation.GetLocation(stadst)));
			local planetype = MyPlanes.ChoosePlane(crg, is_small, AIOrder.GetOrderDistance(AIVehicle.VT_AIR, srcplace, dstplace), false);
			if (planetype == null) {
				LogWarning("No suitable plane available!");
				cBuilder.DeleteAirport(stasrc);
				cBuilder.DeleteAirport(stadst);
				root.buildingstage = root.BS_NOTHING;
				return false;
			}
			LogInfo("Selected aircraft: " + AIEngine.GetName(planetype));
			LogDebug("Distance: " + AIOrder.GetOrderDistance(AIVehicle.VT_AIR, srcplace, dstplace) + "   Range: " + AIEngine.GetMaximumOrderDistance(planetype));
			root.buildingstage = root.BS_NOTHING;
			group = AIGroup.CreateGroup(AIVehicle.VT_AIR);
			cBuilder.SetGroupName(group, crg, stasrc);
			if (cBuilder.BuildAndStartVehicles(planetype, 1, null)) LogInfo("Added plane 1 to route: " + AIStation.GetName(stasrc) + " - " + AIStation.GetName(stadst));
			break;
	}

	// Retry if route was abandoned due to blacklisting
	local vehicles = AIVehicleList_Group(group);
	local maxloop = AISettings.EngineBlackListLoop();
	local maxroutespeed = 500;
	while (maxloop > 0 && vehicles.Count() == 0 && vehtype == AIVehicle.VT_RAIL) {
		LogInfo("The new route may be empty because of blacklisting, retrying...");
		// Choose wagon and locomotive
		local wagon = MyTrains.ChooseWagon(crg, root.engineblacklist);
		if (wagon == null) {
			LogWarning("No suitable wagon available!");
			maxloop = 1;
		} else {
			LogInfo("Chosen wagon: " + AIEngine.GetName(wagon));
			maxroutespeed = MyMath.Min(maxroutespeed, AIEngine.GetMaxSpeed(wagon));
			if (extracrg != null) {
				local extra_wagon = MyTrains.ChooseWagon(extracrg, root.engineblacklist);
				if (extra_wagon == null) {
					LogWarning("No suitable wagon available!");
					maxloop = 1;
				} else {
					LogInfo("Chosen wagon: " + AIEngine.GetName(extra_wagon));
					maxroutespeed = MyMath.Min(maxroutespeed, AIEngine.GetMaxSpeed(extra_wagon));
				}
				prod1_percent = MyAIIndustry.GetProductionPercentage(src, crg, extracrg);
			} else extra_wagon = null;
			local engine = MyTrains.ChooseTrainEngine(crg, AIMap.DistanceManhattan(srcplace, dstplace), wagon, platform * 2 - 1, root.engineblacklist);
			if (engine == null) {
				LogWarning("No suitable engine available!");
				maxloop = 1;
			} else {
				maxroutespeed = MyMath.Min(maxroutespeed, AIEngine.GetMaxSpeed(engine));
				LogInfo("Chosen engine: " + AIEngine.GetName(engine));
				if (cBuilder.BuildAndStartTrains(trains, 2 * platform - 2, engine, wagon, extra_wagon, null, true, prod1_percent)) new_train = true;
			}
		}
		vehicles = AIVehicleList_Group(group);
		maxloop--;
	}
	// Register if fail because it will be removed.
	cBuilder.RegisterRoute(maxroutespeed);
	if (vehtype != AIVehicle.VT_AIR) {
		if (is_new_srcstation) cBuilder.SetStationName(stasrc, "SRC", root.routes.len());
		if (is_new_dststation) cBuilder.SetStationName(stadst, "DST", root.routes.len());
		if (stapass != null) cBuilder.SetStationName(stapass, "PAS", root.routes.len());
		cBuilder.SetGroupName(group, crg, stasrc);
		if (new_train) LogInfo("Added train 1 to route: " + AIGroup.GetName(group));
	}
	root.buildingstage = root.BS_NOTHING;
	root.routes_active++;
	LogWarning("New route " + root.routes.len() + " done!");

	// Add more air routes if we are agressive, or little agressive (medium) in some cases.
	if (vehtype == AIVehicle.VT_AIR && ((AISettings.IsModerateStyleAircraft() && root.airports.Count() > 9 && is_new_srcstation && is_new_dststation) || (AISettings.IsMediumStyleAircraft() && root.airports.Count() > 5 && (is_new_srcstation || is_new_dststation)) || (AISettings.IsAgressiveStyleAircraft() && root.airports.Count() > 2))) {
		local aircounter = 1;
		if (AISettings.IsAgressiveStyleAircraft() && root.airports.Count() > 8 && (is_new_srcstation || is_new_dststation)) aircounter++;
		if (!AISettings.IsModerateStyleAircraft() && root.airports.Count() > 16 && is_new_srcstation && is_new_dststation) aircounter++;
		if (AISettings.IsAgressiveStyleAircraft() && root.airports.Count() > 24 && (is_new_srcstation || is_new_dststation)) aircounter++;
		if (!AISettings.IsModerateStyleAircraft() && root.airports.Count() > 32 && (is_new_srcstation || is_new_dststation)) aircounter++;
		while (aircounter > 0) {
			root.buildcounter++;
			if (!cBuilder.BuildAirRouteWithExistingAirports()) root.buildcounter--;
			aircounter--;
		}
	}
	return true;
}

/**
 * Find a cargo, a source and a destination to build a new service.
 * Builder class variables set: crglist, crg, srclist, src, dstlist, dst,
 *   srcistown, dstistown, srcplace, dstplace
 * @return True if a potential connection was found.
 */
function cBuilder::FindService()
{
	local min_prod = 50;
	local max_distance = 100;
	crglist = AICargoList();
	crglist.Valuate(AIBase.RandItem);
	// Choose a source
	foreach (icrg, dummy in crglist) {
		// Passengers only if we're using air
		if (vehtype == AIVehicle.VT_AIR && MyAICargo.IsFreightCargo(icrg)) continue;
		// Skip cargo routes if trucks and trains aren't allowed
		if (!AISettings.UseTrucks() && !AISettings.UseRail() && MyAICargo.IsFreightCargo(icrg)) continue;
		if (MyAICargo.IsFreightCargo(icrg) && !MyAICargo.IsMailCargo(icrg)) {
			// If the source is an industry
			srclist = AIIndustryList_CargoProducing(icrg);
			// Should not be built on water
			srclist.Valuate(AIIndustry.IsBuiltOnWater);
			srclist.KeepValue(0);
			// There should be some production
			srclist.Valuate(AIIndustry.GetLastMonthProduction, icrg)
			if (root.buildcounter < 9) min_prod = 100; 
			if (root.buildcounter < 4) min_prod = 150;
			srclist.KeepAboveValue(min_prod);
			// Try to avoid excessive competition
			srclist.Valuate(MyAIIndustry.GetLastMonthTransportedPercentage, icrg);
			srclist.KeepBelowValue(AISettings.GetMaxTransported());
			srcistown = false;
		} else {
			// If the source is a town
			srclist = AITownList();
			srclist.Valuate(AITown.GetLastMonthProduction, icrg);
			if (vehtype == AIVehicle.VT_AIR) srclist.KeepAboveValue(AISettings.GetAirMinProduction());
			else {
				if (!AISettings.UsePassTrains() && !AISettings.UseRegionalBuses()) continue;
				srclist.KeepAboveValue(40);
			}
			srcistown = true;
		}
		srclist.Valuate(AIBase.RandItem);
		foreach (isrc, dummy2 in srclist) {
			// Jump source if already serviced
			if (MyAICargo.IsFreightCargo(icrg) && root.serviced.HasItem(isrc * 256 + icrg)) continue;
			// Jump if an airport exists there and it has no free capacity
			if (!cBuilder.CheckExistingAirportCapacity(isrc, icrg, vehtype, true)) continue;
			if (srcistown) srcplace = AITown.GetLocation(isrc);
			else srcplace = AIIndustry.GetLocation(isrc);
			if (AICargo.GetTownEffect(icrg) == AICargo.TE_NONE || AICargo.GetTownEffect(icrg) == AICargo.TE_WATER) {
				// If the destination is an industry
				dstlist = AIIndustryList_CargoAccepting(icrg);
				dstistown = false;
				dstlist.Valuate(AIIndustry.GetDistanceManhattanToTile, srcplace);
			} else {
				// If the destination is a town
				dstlist = AITownList();
				// Some minimum population values for towns
				switch (AICargo.GetTownEffect(icrg)) {
					case AICargo.TE_FOOD:
						dstlist.Valuate(AITown.GetPopulation);
						dstlist.KeepAboveValue(100);
						break;
					case AICargo.TE_GOODS:
						dstlist.Valuate(AITown.GetPopulation);
						dstlist.KeepAboveValue(1500);
						break;
					default:
						dstlist.Valuate(AITown.GetLastMonthProduction, icrg);
						if (vehtype == AIVehicle.VT_AIR) dstlist.KeepAboveValue(AISettings.GetAirMinProduction());
						else dstlist.KeepAboveValue(40);
						break;
				}
				dstistown = true;
				dstlist.Valuate(AITown.GetDistanceManhattanToTile, srcplace);
			}
			local iveh = MyRoadVehs.ChooseRoadVeh(icrg);
			if (MyAICargo.IsFreightCargo(icrg) || !AISettings.UseLocalBuses() || iveh == null) dstlist.KeepAboveValue(AISettings.GetRoadOrRailMinDistance());
			else dstlist.KeepAboveValue(AISettings.MinLocalBusDistance());
			// Check the distance of the source and the destination
			if (vehtype == AIVehicle.VT_AIR) {
				dstlist.KeepAboveValue(AISettings.GetAirMinDistance());
				max_distance = AISettings.GetAirMaxDistance();
				// Get the maximum range of airplanes
				local max_range = MyAIEngine.GetMaximumAircraftRange();
				if (max_range > 0) {
					// maximum range is 0 if range is not supported by the plane set
					dstlist.Valuate(cBuilder.GetTownAircraftOrderDistanceToTile, srcplace);
					if (max_distance > (max_range * 0.82).tointeger()) max_distance = (max_range * 0.82).tointeger();
				}
				dstlist.KeepBelowValue(max_distance);
			} else {
				max_distance = cBuilder.RoadOrRailMaxDistance(icrg);
				if (MyAICargo.IsMailCargo(icrg)) dstlist.KeepBelowValue(AISettings.GetRoadMaxDistance(root.buildcounter));
				else dstlist.KeepBelowValue(max_distance);
			}
			dstlist.Valuate(AIBase.RandItem);
			foreach (idst, dummy3 in dstlist) {
				if (MyAICargo.IsPassengersCargo(icrg) && cBuilder.AreTownsServiced(isrc, idst)) continue;
				// Chech if the destination capacity for more planes
				if (!cBuilder.CheckExistingAirportCapacity(idst, icrg, vehtype, false)) continue;
				if (dstistown) dstplace = AITown.GetLocation(idst);
				else dstplace = AIIndustry.GetLocation(idst);
				crg = icrg;
				src = isrc;
				dst = idst;
				extracrg = null;
				return true;
			}
		}
	}
	return false;
}

/**
 * Wait if we don't have money
 * @param min_money Money (plus MiniumCashNeeded) needed.
 * @ return True if success.
 */
function cBuilder::WaitForMoney(min_money)
{
	if (min_money < 0) return false;
	min_money += Banker.GetMinimumCashNeeded();
	local balance = MyAICompany.GetMyBankBalance();
	if (balance > min_money) return true;
	local count = 2500;
	while (count > 0) {
		if (Banker.GetMaxBankBalance() < min_money) {
			if (count == 2500) SuperSimpleAI.LogDebug("All Builder activities are suspended to avoid bankrupt");
			root.manager.MainLoop();
			AIController.Sleep(90);
			count--;
		} else count = -1;
	}
	if (count == 0) return false;
	return Banker.GetMoney(MyMath.Min(min_money - balance, AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount()));
}

/**
 * Choose a subsidy if there are some available.
 * Builder class variables set: crg, src, dst, srcistown, dstistown, srcplace, dstplace
 * @return True if a subsidy was chosen.
 */
function cBuilder::CheckSubsidies()
{
	local subs = AISubsidyList();
	// Exclude subsidies which have already been awarded to someone
	subs.Valuate(AISubsidy.IsAwarded);
	subs.KeepValue(0);
	if (subs.Count() == 0) return false;
	subs.Valuate(AIBase.RandItem);
	foreach (sub, dummy in subs) {
		crg = AISubsidy.GetCargoType(sub);
		srcistown = (AISubsidy.GetSourceType(sub) == AISubsidy.SPT_TOWN);
		src = AISubsidy.GetSourceIndex(sub);
		if (root.serviced.HasItem(src * 256 + crg)) continue;
		// Some random chance not to choose this subsidy
		if (!AIBase.Chance(AISettings.GetSubsidyChange(), 11) || (!root.use_roadvehs && !root.use_trains)) continue;
		if (srcistown) {
			srcplace = AITown.GetLocation(src);
		} else {
			srcplace = AIIndustry.GetLocation(src);
			// Jump this if there is already some heavy competition there
			if (AIIndustry.GetLastMonthTransported(src, crg) > AISettings.GetMaxTransported()) continue;
		}
		dstistown = (AISubsidy.GetDestinationType(sub) == AISubsidy.SPT_TOWN);
		dst = AISubsidy.GetDestinationIndex(sub);
		if (dstistown) {
			dstplace = AITown.GetLocation(dst);
		} else {
			dstplace = AIIndustry.GetLocation(dst);
		}
		if (!AISettings.UsePassTrains() && !AISettings.UseRegionalBuses()) continue;
		if (srcistown && dstistown && MyAICargo.IsPassengersCargo(crg) && cBuilder.AreTownsServiced(src, dst)) continue;
		// Check the distance
		if (AIMap.DistanceManhattan(srcplace, dstplace) > cBuilder.RoadOrRailMaxDistance(crg)) continue;
		if (AIMap.DistanceManhattan(srcplace, dstplace) < AISettings.GetRoadOrRailMinDistance()) continue;
		return true;
	}
	return false;
}

/**
 * Register the new route into the database.
 * @return The new route registered.
 */
function cBuilder::RegisterRoute(maxspeed = 0)
{
	local route = {
		src = null
		dst = null
		stasrc = null
		stadst = null
		homedepot = null
		group = null
		crg = null
		extracrg = null
		vehtype = null
		railtype = null
		maxvehicles = null
		slopes = null
		cur_max_speed = null
		last_wagon = null
		last_extra_wagon = null
		last_engine = null
		last_date = null
	}
	route.src = src;
	route.dst = dst;
	route.stasrc = stasrc;
	route.stadst = stadst;
	route.homedepot = homedepot;
	route.group = group;
	route.crg = crg;
	route.extracrg = extracrg;
	route.vehtype = vehtype;
	route.railtype = AIRail.GetCurrentRailType();
	switch (vehtype) {
		case AIVehicle.VT_ROAD:
			route.maxvehicles = road_vehs;
			break;
		case AIVehicle.VT_RAIL:
			route.maxvehicles = trains;
			break;
		case AIVehicle.VT_AIR:
			route.maxvehicles = 0;
			break;
	}
	route.slopes = slopes;
	local vehlist = AIVehicleList_Group(group);
	if (vehlist.Count() == 0) route.cur_max_speed = 0;
	else route.cur_max_speed = maxspeed;
	route.last_date = AIDate.GetCurrentDate();
	root.routes.push(route);
	root.routes_loaded = MyRoutes.RouteTableToSaveData(root.routes);
	if (!AICargo.HasCargoClass(crg, AICargo.CC_PASSENGERS)) root.serviced.AddItem(src * 256 + crg, 0);
	if (extracrg != null) root.serviced.AddItem(src * 256 + extracrg, 0);
	root.groups.AddItem(group, root.routes.len() - 1);
	root.lastroute = AIDate.GetCurrentDate();
	return route;
}

/**
 * Decide whether to use road or rail.
 * @return The vehicle type to use, null if there are none available.
 */
function cBuilder::RoadOrRail()
{
	local vehicles = root.use_roadvehs + root.use_trains * 2;
	switch (vehicles) {
		case 0: // neither road or rail
			return null;
			break;
		case 1: // road
			return AIVehicle.VT_ROAD;
			break;
		case 2: // rail
			if (MyAICargo.IsMailCargo(crg)) return null;
			return AIVehicle.VT_RAIL;
			break;
		case 3: // both road and rail
			local dist = AIMap.DistanceManhattan(srcplace, dstplace);
			local veh = MyRoadVehs.ChooseRoadVeh(crg);
			local wagon = MyTrains.ChooseWagon(crg, root.engineblacklist);
			if (veh == null || (MyAICargo.IsPassengersCargo(crg) && !AISettings.UseRegionalBuses() && !AISettings.UseLocalBuses()) || (MyAICargo.IsFreightCargo(crg) && !AISettings.UseTrucks())) {
				if (MyAICargo.IsMailCargo(crg) || wagon == null || (MyAICargo.IsPassengersCargo(crg) && (!AISettings.UsePassTrains() || AISettings.GetPassRailMaxDistance(root.buildcounter) == 0))) return null;
				return AIVehicle.VT_RAIL;
			}
			if (wagon == null) return AIVehicle.VT_ROAD;
			local num_wagons = cBuilder.GetTrainMaxLength(crg) * 2 - 1;
			local trainengine = MyTrains.ChooseTrainEngine(crg, dist, wagon, num_wagons, root.engineblacklist);
			if (veh == null && trainengine == null) return null;
			if (trainengine == null) return AIVehicle.VT_ROAD;
			if (MyAICargo.IsMailCargo(crg)) return AIVehicle.VT_ROAD;
			if (MyAICargo.IsPassengersCargo(crg) && dist > AISettings.GetPassRailMaxDistance(root.buildcounter)) return AIVehicle.VT_ROAD;
			if (dist > AISettings.GetRoadMaxDistance(root.buildcounter)) return AIVehicle.VT_RAIL;
			if (AISettings.IsOldStyleRailLine()) {
				if (dist < 30) return AIVehicle.VT_ROAD;
			} else {
				if (dist < 60) return AIVehicle.VT_ROAD;
			}
			if (AIBase.Chance(2, 3)) return AIVehicle.VT_ROAD;
			else return AIVehicle.VT_RAIL;
			break;
	}
}

/**
 * Set the name of a vehicle group.
 * @param group The GroupID of the group.
 * @param crg The cargo transported.
 * @param stasrc The source station.
 * @return True if success.
 */
function cBuilder::SetGroupName(group, crg, stasrc)
{
	local groupname = AICargo.GetCargoLabel(crg) + " - " + AIStation.GetName(stasrc);
	if (groupname.len() > 30) groupname = groupname.slice(0, 30);
	if (!AIGroup.SetName(group, groupname)) {
		// Shorten the name if it is too long (Unicode character problems)
		while (AIError.GetLastError() == AIError.ERR_PRECONDITION_STRING_TOO_LONG) {
			groupname = groupname.slice(0, groupname.len() - 1);
			AIGroup.SetName(group, groupname);
		}
	}
	return true;
}

/**
 * The new name of the station.
 * @param station_id The basestation to set the name of.
 * @param prefix Should be short, like "SRC", "DST" and "PAS".
 * @param routes Number of routes.
 * @return True if success.
 */
function cBuilder::SetStationName(station_id, prefix, routes)
{
	if (!AISettings.RenameStations()) return false;
	return MyStation.SetName(station_id, prefix, routes);
}

/**
 * The temporal name of the station under construction.
 * @param station_id The basestation to set the name of.
 * @param prefix Should be short, like "SRC", "DST" and "PAS".
 * @return True if success.
 */
function cBuilder::SetStationTmpName(station_id, prefix)
{
	if (!AISettings.RenameStations()) return false;
	return MyStation.SetName(station_id, prefix, root.buildcounter, ".tmp");
}

/**
 * Check if source and destination industries still open.
 * @return True if both are open or are towns.
 */
function cBuilder::AreIndustriesAlive()
{
	if (!srcistown && (!AIIndustry.IsValidIndustry(src) || AIMap.DistanceManhattan(srcplace, AIIndustry.GetLocation(src)) > 1)) {
		LogWarning("Source industry was closed!");
		return false;
	}
	if (!dstistown && (!AIIndustry.IsValidIndustry(dst) || AIMap.DistanceManhattan(dstplace, AIIndustry.GetLocation(dst)) > 1)) {
		LogWarning("Destination industry was closed!");
		return false;
	}
	if (extra_dst != null && passplace != null && (!AIIndustry.IsValidIndustry(extra_dst) || AIMap.DistanceManhattan(passplace, AIIndustry.GetLocation(extra_dst)) > 1)) {
		LogWarning("Destination industry was closed!");
		return false;
	}
	return true;
}

/**
 * Return de maximum distance than rail or road can do.
 * @crg Cargo that want to travel with train or road.
 * @return The maximum distance.
 */
function cBuilder::RoadOrRailMaxDistance(crg)
{
        if (MyAICargo.IsPassengersCargo(crg)) return (MyMath.Max(AISettings.GetPassRailMaxDistance(root.buildcounter), AISettings.GetRoadMaxDistance(root.buildcounter)) * (AIBase.RandRange(7) + 3) / 10).tointeger();
        else return (MyMath.Max(AISettings.GetCargoRailMaxDistance(root.buildcounter), AISettings.GetRoadMaxDistance(root.buildcounter)) * (AIBase.RandRange(8) + 2) / 10).tointeger();
}

/*
 * Demolish a tile, if we have money.
 * @param tile The tile to demolish.
 * @return true if success.
 */
function cBuilder::WaitAndDemolish(tile)
{
	cBuilder.WaitForMoney(MyAITile.GetDemolishCost(tile));
	return AITile.DemolishTile(tile);
}

/*
 * Build a rail or road bridge, if we have money.
 * @param arg1 Start tile of the bridge.
 * @param arg2 End tile of the bridge.
 * @param type AIVehicle.VT_RAIL or AIVehicle.VT_ROAD.
 * @return true if success.
 */
function cBuilder::WaitAndBuildBridge(arg1, arg2, type)
{
	if (arg1 == null || arg2 == null || type == null) return false;
	local bridgelist = AIBridgeList_Length(AIMap.DistanceManhattan(arg1, arg2) + 1);
	if (Banker.SetMinimumBankBalance(AISettings.MiniumMoneyToUseFastBridges())) bridgelist.Valuate(AIBridge.GetMaxSpeed);
	else {
		bridgelist.Valuate(AIBridge.GetPrice,AIMap.DistanceManhattan(arg1, arg2) + 1);
		bridgelist.Sort(AIList.SORT_BY_VALUE, true);
	}
	cBuilder.WaitForMoney(AIBridge.GetPrice(bridgelist.Begin(), AIMap.DistanceManhattan(arg1, arg2) + 1) + 2 * AISettings.GetBridgeHeadCost());
	return AIBridge.BuildBridge(type, bridgelist.Begin(), arg1, arg2);
}

/**
 * Check if two towns are conected by passenger service.
 * @param towna One of the towns.
 * @param townb The other town.
 * @return True if they are serviced.
 */
function cBuilder::AreTownsServiced(towna, townb) {
	foreach (idx, route in root.routes) if (MyAICargo.IsPassengersCargo(route.crg)) {
		if ((towna == route.src && townb == route.dst) || (townb == route.src && towna == route.dst)) return true;
	}
	return false;
}

/**
 * Get the GroupId from a RouteID.
 * @param myroute Route ID .
 * @return group Group ID.
 */
function cBuilder::GetGroupFromRoute(myroute)
{
	foreach (group, route in root.groups) {
		if (myroute == route) return group;
	}
	return -1;
}

/**
 * Get the slope magic key between source and destination.
 * @param src Source tile.
 * @param dst Destination tile.
 * @return 0 if it's a descending route, 1 if it's flat, 2 and 3 if it's ascending/climbing route.
 */
function cBuilder::GetSlopes(src, dst)
{
	local src_z = AITile.GetMaxHeight(src);
	local dst_z = AITile.GetMaxHeight(dst);
	if (dst_z == src_z)  return 1;
	if (dst_z - 2 > src_z) return 3;
	if (dst_z > src_z) return 2;
	return 0;
}

/**
 * And some simple functions to control loggin messages.
 */
function cBuilder::PrintLog()	{ return AISettings.GetAISetting("cBuilder_log", true); }
function cBuilder::Debug()	{ return (cBuilder.PrintLog()) ? AISettings.GetAISetting("cBuilder_log_debug", false) : false; }

