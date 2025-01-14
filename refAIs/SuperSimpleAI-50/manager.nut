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

class cManager
{
	root = null; // Reference to the main SuperSimpleAI instance
	todepotlist = null; // A list of vehicles heading for the depot
	eventqueue = null; // Used for loading the event queue from a savegame
	lastlooprun = 0; // Date when MainLoop() was used
	lastloopruntime = 1; //	Time needed last loop

	constructor(that) {
		root = that;
		todepotlist = AIList();
		eventqueue = [];
		lastlooprun = 0;
		lastloopruntime = 1;
	}

	/**
	 * Main Loop that check events, ToDepotList and routes.
	 */
	static function MainLoop();

	/**
	 * Checks and handles events waiting in the event queue.
	 */
	static function CheckEvents();

	/**
	 * Checks all routes. Empty routes are removed, new vehicles are added if needed, old vehicles are replaced,
	 * vehicles are restarted if sitting in the depot for no reason, rails are electrified, short trains are lengthened.
	 */
	static function CheckRoutes();

	/**
	 * Adds a new vehicle to an existing route. All vehicle types are supported.
	 * @param route The route to which the new vehicle will be added.
	 * @param mainvehicle An already existing vehicle on the route to share orders with.
	 * @param engine The EngineID of the new vehicle. In case of trains it is the EngineID of the locomotive.
	 * @param wagon The EngineID of the train wagons. This parameter is unused in case of road vehicles and aircraft.
	 * @return True if the action succeeded.
	 */
	static function AddVehicle(route, mainvehicle, engine, wagon, extra_wagon);

	/**
	 * Replaces an old vehicle with a newer model if it is already in the depot.
	 * @param vehicle The vehicle to be replaced.
	 */
	static function ReplaceVehicle(vehicle);

	/**
	 * Checks ungrouped vehicles. Under normal conditions all vehicles should be grouped.
	 */
	static function CheckDefaultGroup();

	/**
	 * Check vehicles in the todepotlist if they're actually heading for a depot.
	 */
	static function CheckTodepotlist();

	/**
	 * Send a train to depot.
	 * @param vehicle The vehicle to send to depot.
	 * @return True if train was sended to depot.
	 */
	static function SendTrainToDepot(vehicle);

	/**
	 * Send a road vehicle to depot.
	 * @param vehicle The vehicle to send to depot.
	 * @return True if road vehicle was sended to depot.
	 */
	static function SendRoadVehcToDepot(vehicle);

	/**
	 * Check if we can print to log in AI settings.
	 * @return True if we can write to log (default).
	 */
	static function PrintLog();

	/**
	 * Write to log all info messages from cManager class.
	 * This function is defined in log.nut file.
	 * @param string Text to write to log.
	 */
	static function LogInfo(string);

	/**
	 * Write to log all warning messages from cManager class.
	 * This function is defined in log.nut file.
	 * @param string Text to write to log.
	 */
	static function LogWarning(string);

	/**
	 * Write to log all error messages from cManager class.
	 * This function is defined in log.nut file.
	 * @param string Text to write to log.
	 */
	static function LogError(string);

	/**
	 * Check if we are in Debug mode..
	 * @return True if we are in Debug mode (default is false).
	 */
	static function Debug();

	/**
	 * Write to log all info messages from cManager class.
	 * This function is defined in log.nut file.
	 * @param string Text to write to log.
	 */
	static function LogDebug(string);
}

function cManager::MainLoop()
{
	root.manager.CheckEvents();
	local date = AIDate.GetCurrentDate();
	if (date < lastlooprun || date - lastlooprun > AISettings.DaysBeforeRunManagerMainLoop() * lastloopruntime) {
		LogDebug("Running main Manager loop... (last loop time was " + lastloopruntime + " days)");
		root.manager.CheckTodepotlist();
		root.manager.CheckRoutes();
		root.manager.CheckEvents();
		Banker.PayLoan();
		lastlooprun = date;
		lastloopruntime = MyMath.Max(AIDate.GetCurrentDate() - date, 1);
	}
}

function cManager::CheckEvents()
{
	local event = null;
	local loadedevent = [];
	local isloaded = null;
	local eventtype = null;
	while (eventqueue.len() > 0 || AIEventController.IsEventWaiting()) {
		if (eventqueue.len() > 0) {
			// Load an event from a savegame
			loadedevent = eventqueue.pop();
			eventtype = loadedevent[0];
			isloaded = true;
		} else {
			// Load events if there are no more events from the savegame
			event = AIEventController.GetNextEvent();
			eventtype = event.GetEventType();
			isloaded = false;
		}
		switch (eventtype) {
			case AIEvent.ET_SUBSIDY_AWARDED:
				// Just produce some log output if the subsidy is awarded to our company
				event = AIEventSubsidyAwarded.Convert(event);
				local sub = event.GetSubsidyID();
				if (AICompany.IsMine(AISubsidy.GetAwardedTo(sub))) {
					local srcname = null, dstname = null;
					if (AISubsidy.GetSourceType(sub) == AISubsidy.SPT_TOWN) {
						srcname = AITown.GetName(AISubsidy.GetSourceIndex(sub));
					} else {
						srcname = AIIndustry.GetName(AISubsidy.GetSourceIndex(sub));
					}
					if (AISubsidy.GetDestinationType(sub) == AISubsidy.SPT_TOWN) {
						dstname = AITown.GetName(AISubsidy.GetDestinationIndex(sub));
					} else {
						dstname = AIIndustry.GetName(AISubsidy.GetDestinationIndex(sub));
					}

					local crgname = AICargo.GetCargoLabel(AISubsidy.GetCargoType(sub));
					SuperSimpleAI.LogNotice("I got the subsidy: " + crgname + " from " + srcname + " to " + dstname);
				}
				break;

			case AIEvent.ET_ENGINE_PREVIEW:
				// Accept the preview if possible
				event = AIEventEnginePreview.Convert(event);
				if (event.AcceptPreview()) SuperSimpleAI.LogNotice("New engine available for preview: " + event.GetName());
				break;

			case AIEvent.ET_ENGINE_AVAILABLE:
				break;

			case AIEvent.ET_COMPANY_NEW:
				// Welcome the new company
				event = AIEventCompanyNew.Convert(event);
				local company = event.GetCompanyID();
				SuperSimpleAI.LogNotice("Welcome " + AICompany.GetName(company));
				break;

			case AIEvent.ET_COMPANY_IN_TROUBLE:
				// Some more serious action is needed, currently it is only logged
				event = AIEventCompanyInTrouble.Convert(event);
				local company = event.GetCompanyID();
				if (AICompany.IsMine(company)) SuperSimpleAI.LogError("I'm in trouble, I don't know what to do!");
				break;

			case AIEvent.ET_VEHICLE_CRASHED:
				// Clone the crashed vehicle if it still exists
				local vehicle = null;
				if (isloaded) {
					vehicle = loadedevent[1];
				} else {
					event = AIEventVehicleCrashed.Convert(event);
					vehicle = event.GetVehicleID();
				}
				LogError("One of my vehicles has crashed.");
				// Remove it from the todepotlist if it's there. It might be another vehicle, but that's not a big problem
				if (todepotlist.HasItem(vehicle)) todepotlist.RemoveItem(vehicle);
				// Check if it still exists
				if (!AIVehicle.IsValidVehicle(vehicle)) break;
				// Check if it is still the same vehicle
				if (AIVehicle.GetState(vehicle) != AIVehicle.VS_CRASHED) break;
				local group = AIVehicle.GetGroupID(vehicle);
				if (!root.groups.HasItem(group)) break;
				local route = root.groups.GetValue(group);
				local newveh = AIVehicle.CloneVehicle(root.routes[route].homedepot, vehicle, true);
				if (AIVehicle.IsValidVehicle(newveh)) {
					AIVehicle.StartStopVehicle(newveh);
					LogInfo("Cloned the crashed vehicle.");
				}
				break;

			case AIEvent.ET_VEHICLE_LOST:
				// No action taken, only logged
				event = AIEventVehicleLost.Convert(event);
				local vehicle = event.GetVehicleID();
				LogError("" + AIVehicle.GetName(vehicle) + " is lost, I don't know what to do with that!");
				/* TODO: Handle it. */
				break;

			case AIEvent.ET_VEHICLE_UNPROFITABLE:
				break;

			case AIEvent.ET_VEHICLE_WAITING_IN_DEPOT:
				local vehicle = null;
				local vehiclename = null;
				if (isloaded) {
					vehicle = loadedevent[1];
				} else {
					event = AIEventVehicleWaitingInDepot.Convert(event);
					vehicle = event.GetVehicleID();
				}
				vehiclename = AIVehicle.GetName(vehicle);
				if (todepotlist.HasItem(vehicle)) {
					switch (todepotlist.GetValue(vehicle)) {
						case SuperSimpleAI.TD_SELL:
							// Sell a vehicle because it is old or unprofitable
							if (AIVehicle.GetVehicleType(vehicle) == AIVehicle.VT_RAIL) {
								AIVehicle.SellWagonChain(vehicle, 0);
							} else {
								AIVehicle.SellVehicle(vehicle);
							}
							todepotlist.RemoveItem(vehicle);
							LogInfo("Sold " + vehiclename + ".");
							break;
						case SuperSimpleAI.TD_REPLACE:
							// Replace an old vehicle with a newer model
							if (cManager.ReplaceVehicle(vehicle)) LogInfo("Replaced " + vehiclename + ".");
							else LogInfo("Can not replace " + vehiclename + ", restarting it.");
							break;
						case SuperSimpleAI.TD_ATTACH_WAGONS:
							// Attach more wagons to an existing train, if we didn't have enough money to buy all wagons beforehand
							cBuilder.AttachMoreWagons(vehicle);
							AIVehicle.StartStopVehicle(vehicle);
							todepotlist.RemoveItem(vehicle);
							break;
					}
				} else {
					// The vehicle is not in todepotlist
					if (!AIVehicle.IsStoppedInDepot) {
						LogError("I don't know why " + vehiclename + " was sent to the depot, restarting it...");
						AIVehicle.StartStopVehicle(vehicle);
					}
				}
				break;

			case AIEvent.ET_INDUSTRY_OPEN:
				break;

			case AIEvent.ET_INDUSTRY_CLOSE:
				break;

			case AIEvent.ET_TOWN_FOUNDED:
				break;
		}
	}
}

function cManager::CheckRoutes()
{
	local save_routes = false;
	local reserved_cash = 0;
	local routesactive = root.routes.len();
	local railtype = AIRail.GetCurrentRailType();
	foreach (idx, route in root.routes) {
		local NearestTown = AIStation.GetNearestTown(route.stasrc);
		switch (route.vehtype) {
			case AIVehicle.VT_ROAD:
				local vehicles = AIVehicleList_Group(route.group);
				local vehiclescount = vehicles.Count();

				/* Industry Closes */
				if (MyAICargo.IsFreightCargo(route.crg)) {
					if ((AICargo.GetTownEffect(route.crg) == AICargo.TE_NONE || AICargo.GetTownEffect(route.crg) == AICargo.TE_WATER) && !cBuilder.IsIndustryConnectedToDestinationStation(route.dst, route.stadst)) {
						if (route.maxvehicles > 0) {
							LogWarning("Destination industry near " + AIStation.GetName(route.stadst) + " was closed!");
							route.maxvehicles = 0;
							save_routes = true;
						}
						foreach (vehicle, dummy in vehicles) {
							if (todepotlist.HasItem(vehicle)) continue;
							if (!SendRoadVehcToDepot(vehicle)) break;
							LogInfo(AIVehicle.GetName(vehicle) + " is sending it to the depot because the route was closed");
							todepotlist.AddItem(vehicle, SuperSimpleAI.TD_SELL);
						}
					}
					if (!MyAICargo.IsMailCargo(route.crg) && (route.maxvehicles == 0 || !cBuilder.IsIndustryConnectedToSourceStation(route.src, route.stasrc))) {
						if (route.maxvehicles > 0) {
							LogWarning("Source industry near " + AIStation.GetName(route.stasrc) + " was closed!");
							route.maxvehicles = 0;
							save_routes = true;
						}
						foreach (vehicle, dummy in vehicles) {
							if (todepotlist.HasItem(vehicle)) continue;
							if (AIVehicle.GetCargoLoad(vehicle,route.crg) > 0) {
								if (AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION) {
									AIController.Sleep(150);
									if (AIOrder.SkipToOrder(vehicle, 1)) LogInfo(AIVehicle.GetName(vehicle) + " is sending to destination because isn't empty");
								}
								continue;
							}
							if (!SendRoadVehcToDepot(vehicle)) break;
							LogInfo(AIVehicle.GetName(vehicle) + " is sending it to the depot because the route was closed");
							todepotlist.AddItem(vehicle, SuperSimpleAI.TD_SELL);
						}
					}
				}

				/* Close non-profitable routes */
				if (root.routes_active > 15 && AISettings.CloseUnprofitableRoutes() && AIDate.GetMonth(AIDate.GetCurrentDate()) > 11 && AIDate.GetDayOfMonth(AIDate.GetCurrentDate()) < 25) {
					local vehicles_age = AIVehicleList_Group(route.group);
					vehicles_age.Valuate(AIVehicle.GetAge);
					vehicles_age.RemoveBelowValue(1200);
					if (vehicles.Count() > (route.maxvehicles / 10).tointeger() && vehicles_age.Count() > 2) {
						if (MyAIGroup.GetProfitThisYear(route.group) + MyAIGroup.GetProfitLastYear(route.group) < 1200) {
							if (route.maxvehicles > 0 ) LogWarning("Group " + AIGroup.GetName(route.group) + " has not profit! Clossing this route!");
							route.maxvehicles = 0;
							save_routes = true;
							local vehicles_sell = AIVehicleList_Group(route.group);
							foreach (vehicle, dummy in vehicles_sell) {
								if (todepotlist.HasItem(vehicle)) continue;
								if (!MyAICargo.IsMailCargo(route.crg) && AIVehicle.GetCargoLoad(vehicle,route.crg) > 0) {
									if (AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION) {
										AIController.Sleep(150);
										if (AIOrder.SkipToOrder(vehicle, 1)) LogInfo(AIVehicle.GetName(vehicle) + " is sending to destination because isn't empty");
									}
									continue;
								}
								if (!SendRoadVehcToDepot(vehicle)) break;
								LogInfo(AIVehicle.GetName(vehicle) + " is sending it to the depot because the route was closed");
								todepotlist.AddItem(vehicle, SuperSimpleAI.TD_SELL);
							}
						}
					}
				}

				/* Empty route */
				if (root.buildingstage != root.BS_REMOVING && vehicles.Count() == 0) {
					LogInfo("Removing empty route: " + AIGroup.GetName(route.group));
					route.vehtype = null;
					save_routes = true;
					root.groups.RemoveItem(route.group);
					AIGroup.DeleteGroup(route.group);
					root.serviced.RemoveItem(route.src * 256 + route.crg);
					if (MyAICargo.IsPassengersCargo(route.crg)) root.serviced.RemoveItem(route.dst * 256 + route.crg);
					cBuilder.DeleteRoadStation(route.stasrc);
					cBuilder.DeleteRoadStation(route.stadst);
					root.routes_active--;
					break;
				}

				// Choose a new model
				local engine = null;
				if (route.last_date < AIDate.GetCurrentDate() - 90) {
					engine = MyRoadVehs.ChooseRoadVeh(route.crg);
					route.last_engine = engine;
					route.last_date = AIDate.GetCurrentDate();
				} else {
					engine = route.last_engine;
				}

				/* Adding vehicles */
				if ((vehicles.Count() < route.maxvehicles) && (
							   (AIStation.GetCargoWaiting(route.stasrc, route.crg) > 100)
							|| ((MyAICargo.IsPassengersCargo(route.crg) || MyAICargo.IsMailCargo(route.crg)) && AIStation.GetCargoWaiting(route.stadst, route.crg) > 100)
				)) {
					// Only add new vehicles if the newest one is at least 20 days old
					vehicles.Valuate(AIVehicle.GetAge);
					vehicles.Sort(AIList.SORT_BY_VALUE, false);
					local new_route_age = vehicles.GetValue(vehicles.Begin());
					vehicles.Sort(AIList.SORT_BY_VALUE, true);
					if (vehicles.GetValue(vehicles.Begin()) > (new_route_age < 360 ? 10 : 20)) {
						if (engine == null) break;
						if (Banker.GetMaxBankBalance() > (reserved_cash + Banker.GetMinimumCashNeeded() + AIEngine.GetPrice(engine))) {
							if (cManager.AddVehicle(route, vehicles.Begin(), engine, null, null)) {
								LogInfo("Added road vehicle " + (vehicles.Count() + 1) + " to route: " + AIGroup.GetName(route.group));
							}
						}
					}
				}

				/* Replacing old vehicles */
				vehicles.Valuate(AIVehicle.GetAgeLeft);
				vehicles.KeepBelowValue(0);
				foreach (vehicle, dummy in vehicles) {
					if (todepotlist.HasItem(vehicle)) continue;
					if (engine == null) continue;
					if (AIVehicle.GetAge(vehicle) < 14600 && MyAICargo.IsFreightCargo(route.crg) && !MyAICargo.IsMailCargo(route.crg) && AIVehicle.GetCargoLoad(vehicle,route.crg) > 0) continue;
					// Replace it only if we can afford it
					local vehicle_cost = Banker.GetMinimumCashNeeded() + AIEngine.GetPrice(engine);
					if (Banker.GetMaxBankBalance() > (reserved_cash + vehicle_cost)) {
						if (!SendRoadVehcToDepot(vehicle)) break;
						LogInfo(AIVehicle.GetName(vehicle) + " is getting old, sending it to the depot...");
						reserved_cash = reserved_cash + vehicle_cost;
						todepotlist.AddItem(vehicle, SuperSimpleAI.TD_REPLACE);
					}
				}

				/* Checking vehicles in depot */
				vehicles = AIVehicleList_Group(route.group);
				vehicles.Valuate(AIVehicle.IsStoppedInDepot);
				vehicles.KeepValue(1);
				foreach (vehicle, dummy in vehicles) {
					// A vehicle has probably been sitting there for ages if its current year/last year profits are both 0, and it's at least 12 months old
					if (AIVehicle.GetProfitThisYear(vehicle) != 0 || AIVehicle.GetProfitLastYear(vehicle) != 0 || AIVehicle.GetAge(vehicle) < 360) continue;
					if (todepotlist.HasItem(vehicle)) {
						todepotlist.RemoveItem(vehicle);
						AIVehicle.StartStopVehicle(vehicle);
					} else {
						// Sell it if we have no idea how it got there
						LogWarning("Sold " + AIVehicle.GetName(vehicle) + ", as it has been sitting in the depot for ages.");
						AIVehicle.SellVehicle(vehicle);
					}
				}

				break;
			case AIVehicle.VT_RAIL:
				local vehicles = AIVehicleList_Group(route.group);
				local vehiclescount = vehicles.Count();
				local platform = MyMath.Min(cBuilder.GetRailRoutePlatformLength(route.stasrc, route.stadst), MyAIGameSettings.EfectiveMaxTrainLength());

				/* Industry Closes */
				if (MyAICargo.IsFreightCargo(route.crg)) {
					if ((AICargo.GetTownEffect(route.crg) == AICargo.TE_NONE || AICargo.GetTownEffect(route.crg) == AICargo.TE_WATER) && !cBuilder.IsIndustryConnectedToDestinationStation(route.dst, route.stadst)) {
						if (route.maxvehicles > 0) {
							LogWarning("Destination industry near " + AIStation.GetName(route.stadst) + " was closed!");
							route.maxvehicles = 0;
							save_routes = true;
						}
						foreach (vehicle, dummy in vehicles) {
							if (todepotlist.HasItem(vehicle)) continue;
							if (!SendTrainToDepot(vehicle)) break;
							LogInfo(AIVehicle.GetName(vehicle) + " is sending it to the depot because the route was closed");
							todepotlist.AddItem(vehicle, SuperSimpleAI.TD_SELL);
						}
					}
					if (route.maxvehicles == 0 || !cBuilder.IsIndustryConnectedToSourceStation(route.src, route.stasrc)) {
						if (route.maxvehicles > 0) {
							LogWarning("Source industry near " + AIStation.GetName(route.stasrc) + " was closed!");
							route.maxvehicles = 0;
							save_routes = true;
						}
						foreach (vehicle, dummy in vehicles) {
							if (todepotlist.HasItem(vehicle)) continue;
							if (!MyAICargo.IsMailCargo(route.crg) && AIVehicle.GetCargoLoad(vehicle,route.crg) > 0) {
								if (AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION) {
									AIController.Sleep(150);
									if (AIOrder.SkipToOrder(vehicle, 1)) LogInfo(AIVehicle.GetName(vehicle) + " is sending to destination because isn't empty");
								}
								continue;
							}
							if (!SendTrainToDepot(vehicle)) break;
							LogInfo(AIVehicle.GetName(vehicle) + " is sending it to the depot because the route was closed");
							todepotlist.AddItem(vehicle, SuperSimpleAI.TD_SELL);
						}
					}
				}

				/* Close non-profitable routes */
				if (root.routes_active > 15 && AISettings.CloseUnprofitableRoutes() && AIDate.GetMonth(AIDate.GetCurrentDate()) > 11 && AIDate.GetDayOfMonth(AIDate.GetCurrentDate()) < 25) {
					local vehicles_age = AIVehicleList_Group(route.group);
					vehicles_age.Valuate(AIVehicle.GetAge);
					vehicles_age.RemoveBelowValue(2400);
					if (vehicles.Count() > (route.maxvehicles / 3).tointeger() && vehicles_age.Count() > 1) {
						if (MyAIGroup.GetProfitThisYear(route.group) + MyAIGroup.GetProfitLastYear(route.group) < 1200) {
							if (route.maxvehicles > 0 ) LogWarning("Group " + AIGroup.GetName(route.group) + " has not profit! Clossing this route!");
							route.maxvehicles = 0;
							save_routes = true;
							local vehicles_sell = AIVehicleList_Group(route.group);
							foreach (vehicle, dummy in vehicles_sell) {
								if (todepotlist.HasItem(vehicle)) continue;
								if (!MyAICargo.IsMailCargo(route.crg) && AIVehicle.GetCargoLoad(vehicle,route.crg) > 0) {
									if (AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION) {
										AIController.Sleep(150);
										if (AIOrder.SkipToOrder(vehicle, 1)) LogInfo(AIVehicle.GetName(vehicle) + " is sending to destination because isn't empty");
									}
									continue;
								}
								if (!SendTrainToDepot(vehicle)) break;
								LogInfo(AIVehicle.GetName(vehicle) + " is sending it to the depot because the route was closed");
								todepotlist.AddItem(vehicle, SuperSimpleAI.TD_SELL);
							}
						}
					}
				}

				/* Empty route */
				if (root.buildingstage != root.BS_REMOVING && vehicles.Count() == 0) {
					LogInfo("Removing empty route: " + AIGroup.GetName(route.group));
					route.vehtype = null;
					save_routes = true;
					root.groups.RemoveItem(route.group);
					AIGroup.DeleteGroup(route.group);
					root.serviced.RemoveItem(route.src * 256 + route.crg);
					if (AICargo.HasCargoClass(route.crg, AICargo.CC_PASSENGERS)) root.serviced.RemoveItem(route.dst * 256 + route.crg);
					// A builder instance is needed to call DeleteRailStation
					local builder = cBuilder(root);
					// Connected rails will automatically be removed
					builder.DeleteRailStation(route.stasrc);
					builder.DeleteRailStation(route.stadst);
					builder = null;
					root.routes_active--;
					break;
				}

				/* Electrifying rails */
				if (Banker.GetMaxBankBalance() > reserved_cash + AISettings.MinMoneyToElectrify() + AICompany.GetMaxLoanAmount() && root.routes_active > AISettings.MinRoutesToBuildElectrifiedRail()) {
					if (!root.el_rails) {
						root.el_rails = true;
						SuperSimpleAI.LogNotice("Enabling electrified rails");
					}
					if (root.buildingstage != root.BS_REMOVING && root.buildingstage != root.BS_PATHFINDING && root.buildingstage != root.BS_BUILDING && routesactive > 20 && (AISettings.ElectrifyOldRailLines() == 3 || (AISettings.ElectrifyOldRailLines() == 2 && vehicles.Count() == route.maxvehicles) || (AISettings.ElectrifyOldRailLines() == 1 && AICargo.HasCargoClass(route.crg, AICargo.CC_PASSENGERS))) && AIRail.TrainHasPowerOnRail(route.railtype, AIRail.GetCurrentRailType()) && route.railtype != AIRail.GetCurrentRailType()) {
						vehicles.Valuate(AIVehicle.GetAgeLeft);
						vehicles.Sort(AIList.SORT_BY_VALUE, true);
						if (vehicles.GetValue(vehicles.Begin()) < 1460) {
						// Check if we can afford it
							if (MyAICompany.GetMyBankBalance() < reserved_cash + AISettings.MinMoneyToElectrify()) {
								Banker.SetMinimumBankBalance(AISettings.MinMoneyToElectrify());
							}
							LogInfo("Electrifying rail line: " + AIGroup.GetName(route.group));
							// A builder instance is needed to call ElectrifyRail
							local builder = cBuilder(root);
							if (builder.ElectrifyRail(AIStation.GetLocation(route.stasrc))) {
								LogDebug("Rail line successfully electrifyed: " + AIGroup.GetName(route.group));
								route.railtype = AIRail.GetCurrentRailType();
								save_routes = true;
							}
							builder = null;
						}
					}
				}

				// Choose a new model
				AIRail.SetCurrentRailType(route.railtype);
				local wagon = null;
				local extra_wagon = null;
				local engine = null;
				if (route.last_date < AIDate.GetCurrentDate() - 90) {
					wagon = MyTrains.ChooseWagon(route.crg, root.engineblacklist);
					extra_wagon = (route.extracrg == null) ? null : MyTrains.ChooseWagon(route.extracrg, root.engineblacklist);
					local wagonminspeed = wagon;
					local wagoncrg = route.crg;
					if (extra_wagon!= null) {
						if (AIEngine.GetMaxSpeed(wagon) > AIEngine.GetMaxSpeed(extra_wagon)) {
							wagonminspeed = extra_wagon;
							wagoncrg = route.extracrg;
						}
					}
					engine = MyTrains.ChooseTrainEngine(wagoncrg, AIMap.DistanceManhattan(AIStation.GetLocation(route.stasrc), AIStation.GetLocation(route.stadst)), wagonminspeed, platform * 2 - 1, root.engineblacklist);
					route.last_wagon = wagon;
					route.last_extra_wagon = extra_wagon;
					route.last_engine = engine;
					route.last_date = AIDate.GetCurrentDate();
				} else {
					wagon = route.last_wagon;
					extra_wagon = route.last_extra_wagon;
					engine = route.last_engine;
				}
				if (wagon != null && engine != null) {
					local engine_count = cBuilder.GetNumEnginesNeeded(engine, route.homedepot, platform * 2 - 1, route.slopes, wagon, route.crg, extra_wagon, route.extracrg);
					local vehicle_cost = Banker.GetMinimumCashNeeded() + AIEngine.GetPrice(engine) * engine_count + (platform * 2 - 1) * AIEngine.GetPrice(wagon);
					if (Banker.GetMaxBankBalance() > vehicle_cost) {
						if (cBuilder.IsEngineCompatibleWithWagon(route.homedepot, engine, wagon, root.engineblacklist) && (extra_wagon == null || cBuilder.IsEngineCompatibleWithWagon(route.homedepot, engine, extra_wagon, root.engineblacklist))) {

							/* Adding trains */
							if (vehicles.Count() < route.maxvehicles && root.routes_active > 3 && (root.buildcounter > 15 || Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(500000)) && (
							   (Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(300000) && (AIStation.GetCargoRating(route.stasrc, route.crg) < 60) || (AITown.HasStatue(NearestTown) && AIStation.GetCargoRating(route.stasrc, route.crg) < 70))
								|| (vehicles.Count() == 1 && (route.maxvehicles > 3 || MyAICargo.IsPassengersCargo(route.crg)))
							 	|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(320000) || root.buildcounter > 20) && vehicles.Count() == 2 && route.maxvehicles > 6)
							 	|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(330000) || root.buildcounter > 25) && vehicles.Count() == 2 && route.maxvehicles > 5)
							 	|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(340000) || root.buildcounter > 30) && vehicles.Count() == 2 && route.maxvehicles > 4)
							 	|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(350000) || root.buildcounter > 35) && vehicles.Count() == 3 && route.maxvehicles > 11)
							 	|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(360000) || root.buildcounter > 40) && vehicles.Count() == 3 && route.maxvehicles > 10)
					 			|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(370000) || root.buildcounter > 45) && vehicles.Count() == 3 && route.maxvehicles > 9)
							 	|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(380000) || root.buildcounter > 50) && vehicles.Count() == 3 && route.maxvehicles > 8)
							 	|| ((Banker.GetMaxBankBalance() > reserved_cash + Banker.InflatedValue(390000) || root.buildcounter > 55) && vehicles.Count() == 1 && route.maxvehicles == 2)
							)) {
       		               		                 // Only add new vehicles if the newest one is at least 30 days old and latest vehicle added is half-loaded
								vehicles.Valuate(AIVehicle.GetAge);
								vehicles.Sort(AIList.SORT_BY_VALUE, true);
								if (vehicles.GetValue(vehicles.Begin()) > 30 && ( AIVehicle.GetCargoLoad(vehicles.Begin(),route.crg) > AIVehicle.GetCapacity(vehicles.Begin(),route.crg)/2 || ( AIVehicle.GetState(vehicles.Begin()) != AIVehicle.VS_AT_STATION && AIVehicle.GetState(vehicles.Begin()) != AIVehicle.VS_IN_DEPOT))) {
									// Check if we can afford it
									if (Banker.GetMaxBankBalance() > (reserved_cash + vehicle_cost)) {
										if (MyAICompany.GetMyBankBalance() < reserved_cash + vehicle_cost) {
											Banker.SetMinimumBankBalance(vehicle_cost);
										}
										if (cManager.AddVehicle(route, vehicles.Begin(), engine, wagon, extra_wagon)) {
											LogInfo("Added train " + (vehicles.Count() + 1) + " to route: " + AIGroup.GetName(route.group));
										}
									}
								}
							}

							/* Replacing old vehicles */
							vehicles = AIVehicleList_Group(route.group);
							vehicles.Valuate(AIVehicle.GetAgeLeft);
							vehicles.KeepBelowValue(360);
							foreach (vehicle, dummy in vehicles) {
								if (todepotlist.HasItem(vehicle)) continue;
								local vehicle_is_old = AIVehicle.GetAge(vehicle) < 29200;
								if (vehicle_is_old && !MyAICargo.IsPassengersCargo(route.crg) && !MyAICargo.IsMailCargo(route.crg) && AIVehicle.GetCargoLoad(vehicle,route.crg) > 0) continue;
								if (vehicle_is_old && route.extracrg != null && AIVehicle.GetCargoLoad(vehicle,route.extracrg) > 0) continue;
								// Replace it only if we can afford it
								if (Banker.GetMaxBankBalance() > (reserved_cash + vehicle_cost)) {
									if (!SendTrainToDepot(vehicle)) break;
									LogInfo(AIVehicle.GetName(vehicle) + " is getting old, sending it to the depot...");
									reserved_cash = reserved_cash + vehicle_cost;
									todepotlist.AddItem(vehicle, SuperSimpleAI.TD_REPLACE);
								}
							}
		
							/* Lengthening short trains */
							vehicles = AIVehicleList_Group(route.group);
							foreach (train, dummy in vehicles) {
								if (todepotlist.HasItem(train)) continue;
								if (MyAICargo.IsFreightCargo(route.crg) && !MyAICargo.IsMailCargo(route.crg) && AIVehicle.GetCargoLoad(train,route.crg) > 0) continue;
								if (route.extracrg != null && AIVehicle.GetCargoLoad(train,route.extracrg) > 0) continue;
								// The train should fill its platform
								if (AIVehicle.GetLength(train) < platform * 16 - 7) {
									if (wagon == null) break;
									// Check if we can afford it
									vehicle_cost = Banker.GetMinimumCashNeeded() + 2 * cBuilder.GetTrainMaxLength(route.crg) * AIEngine.GetPrice(wagon);
									if (Banker.GetMaxBankBalance() > (reserved_cash + vehicle_cost)) {
										AIController.Sleep(75);
										if (!SendTrainToDepot(train)) break;
										LogInfo(AIVehicle.GetName(train) + " is short, sending it to the depot to attach more wagons...");
										reserved_cash = reserved_cash + vehicle_cost;
										todepotlist.AddItem(train, SuperSimpleAI.TD_ATTACH_WAGONS);
									}
								}
							}
						}
					}
				}
		
				/* Checking vehicles in depot */
				vehicles = AIVehicleList_Group(route.group);
				vehicles.Valuate(AIVehicle.IsStoppedInDepot);
				vehicles.KeepValue(1);
				foreach (vehicle, dummy in vehicles) {
					// A vehicle has probably been sitting there for ages if its current year/last year profits are both 0, and it's at least 12 months old
					if (AIVehicle.GetProfitThisYear(vehicle) != 0 || AIVehicle.GetProfitLastYear(vehicle) != 0 || AIVehicle.GetAge(vehicle) < 360) continue;
					if (todepotlist.HasItem(vehicle)) {
						todepotlist.RemoveItem(vehicle);
						AIVehicle.StartStopVehicle(vehicle);
					} else {
						// Sell it if we have no idea how it got there
						LogWarning("Sold " + AIVehicle.GetName(vehicle) + ", as it has been sitting in the depot for ages.");
						AIVehicle.SellWagonChain(vehicle, 0);
					}
				}

				break;

			case AIVehicle.VT_AIR:
				local vehicles = AIVehicleList_Group(route.group);
				local vehiclescount = vehicles.Count();
				local srctype = AIAirport.GetAirportType(AIStation.GetLocation(route.stasrc));
				local dsttype = AIAirport.GetAirportType(AIStation.GetLocation(route.stadst));
				local is_small = MyAIAirport.IsSmallAirport(srctype) || MyAIAirport.IsSmallAirport(dsttype);

				/* Empty route */
				if (root.buildingstage != root.BS_REMOVING && vehicles.Count() == 0) {
					LogInfo("Removing empty route: " + AIStation.GetName(route.stasrc) + " - " + AIStation.GetName(route.stadst));
					route.vehtype = null;
					save_routes = true;
					root.groups.RemoveItem(route.group);
					AIGroup.DeleteGroup(route.group);
					root.serviced.RemoveItem(route.src * 256 + route.crg);
					if (AICargo.HasCargoClass(route.crg, AICargo.CC_PASSENGERS)) root.serviced.RemoveItem(route.dst * 256 + route.crg);
					// DeleteAirport will only delete the airports if they are unused
					cBuilder.DeleteAirport(route.stasrc);
					cBuilder.DeleteAirport(route.stadst);
					root.routes_active--;
					break;
				}

				// Choose a new model
				local engine = null;
				if (route.last_date < AIDate.GetCurrentDate() - 90) {
					engine = MyPlanes.ChoosePlane(route.crg, is_small, AIOrder.GetOrderDistance(AIVehicle.VT_AIR, AIStation.GetLocation(route.stasrc), AIStation.GetLocation(route.stadst)), false);
					route.last_engine = engine;
					route.last_date = AIDate.GetCurrentDate();
				} else {
					engine = route.last_engine;
				}

				/* Adding vehicles */
				local canaddplane = true;
				local dist = AIMap.DistanceManhattan(AIStation.GetLocation(route.stasrc), AIStation.GetLocation(route.stadst));
				local max_airplanes = cBuilder.GetMaxAirplanes(dist);
				if (2 * AISettings.GetAirportTypeCapacity(srctype) < max_airplanes + AIVehicleList_Station(route.stasrc).Count()) canaddplane = false;
				if (2 * AISettings.GetAirportTypeCapacity(dsttype) < max_airplanes + AIVehicleList_Station(route.stadst).Count()) canaddplane = false;
				// Only add planes if there is some free capacity at both airports
				if (canaddplane && vehicles.Count() < max_airplanes && (AIStation.GetCargoWaiting(route.stasrc, route.crg) > 300 || AIStation.GetCargoWaiting(route.stadst, route.crg) > 300)) {
					// Do not add new planes if there are unprofitable ones
					vehicles.Valuate(AIVehicle.GetProfitThisYear);
					if (vehicles.GetValue(vehicles.Begin()) <= 0) break;
					// Only add new planes if the newest one is at least 4 months old
					vehicles.Valuate(AIVehicle.GetAge);
					vehicles.Sort(AIList.SORT_BY_VALUE, true);
					if (vehicles.GetValue(vehicles.Begin()) > 120) {
						if (engine == null) break;
						// Check if we can afford it
						if (Banker.GetMaxBankBalance() > (reserved_cash + Banker.GetMinimumCashNeeded() + AIEngine.GetPrice(engine))) {
							if (cManager.AddVehicle(route, vehicles.Begin(), engine, null, null)) {
								LogInfo("Added plane " + (vehicles.Count() + 1) + " to route: " + AIStation.GetName(route.stasrc) + " - " + AIStation.GetName(route.stadst));
							}
						}
					}
				}

				/* Replacing old vehicles */
				vehicles.Valuate(AIVehicle.GetAgeLeft);
				vehicles.KeepBelowValue(0);
				foreach (vehicle, dummy in vehicles) {
					if (todepotlist.HasItem(vehicle)) continue;
					// Choose a new model
					if (engine == null) continue;
					// Check if we can afford it
					local vehicle_cost = Banker.GetMinimumCashNeeded() + AIEngine.GetPrice(engine);
					if (Banker.GetMaxBankBalance() > (reserved_cash + vehicle_cost)) {
						if (!AIVehicle.SendVehicleToDepot(vehicle)) break;
						LogInfo(AIVehicle.GetName(vehicle) + " is getting old, sending it to the hangar...");
						reserved_cash = reserved_cash + vehicle_cost;
						todepotlist.AddItem(vehicle, SuperSimpleAI.TD_REPLACE);
					}
				}

				/* Checking vehicles in depot */
				vehicles = AIVehicleList_Group(route.group);
				vehicles.Valuate(AIVehicle.IsStoppedInDepot);
				vehicles.KeepValue(1);
				foreach (vehicle, dummy in vehicles) {
					// A vehicle has probably been sitting there for ages if its current year/last year profits are both 0, and it's at least 2 months old
					if (AIVehicle.GetProfitThisYear(vehicle) != 0 || AIVehicle.GetProfitLastYear(vehicle) != 0 || AIVehicle.GetAge(vehicle) < 60) continue;
					if (todepotlist.HasItem(vehicle)) {
						todepotlist.RemoveItem(vehicle);
						AIVehicle.StartStopVehicle(vehicle);
					} else {
						// Sell it if we have no idea how it got there
						LogWarning("Sold " + AIVehicle.GetName(vehicle) + ", as it has been sitting in the depot for ages.");
						AIVehicle.SellVehicle(vehicle);
					}
				}
				break;
		}
		if (save_routes) {
			root.routes_loaded = MyRoutes.RouteTableToSaveData(root.routes);
			save_routes = false;
		}

		/* Building statue */
		if (root.routes_active > 12 && AISettings.CanBuildStatue() && !AITown.HasStatue(NearestTown) && Banker.GetMaxBankBalance() > reserved_cash + AISettings.MiniumMoneyToBuildStatue()) {
			if (AITown.PerformTownAction(NearestTown,AITown.TOWN_ACTION_BUILD_STATUE))
				SuperSimpleAI.LogNotice("Building a statue at " + AITown.GetName(NearestTown));
		}
	}

	// Check ugrouped vehicles as well. There should be none after all...
	cManager.CheckDefaultGroup();
	AIRail.SetCurrentRailType(railtype);
}

function cManager::AddVehicle(route, mainvehicle, engine, wagon, extra_wagon)
{
	// A builder instance is needed to add a new vehicle
	local builder = cBuilder(root);
	local success = true;
	builder.crg = route.crg;
	builder.extracrg = route.extracrg;
	builder.stasrc = route.stasrc;
	builder.stadst = route.stadst;
	builder.group = route.group;
	builder.slopes = route.slopes;
	builder.homedepot = route.homedepot;
	switch (route.vehtype) {
		case AIVehicle.VT_RAIL:
			local prod1_percent = MyAIIndustry.GetProductionPercentage(route.src, route.crg, route.extracrg);
			local trains = AIVehicleList();
			trains.Valuate(AIVehicle.GetVehicleType);
			trains.KeepValue(AIVehicle.VT_RAIL);
			// Do not try to add one if we have already reached the train limit
			if (trains.Count() + 1 > AIGameSettings.GetValue("vehicle.max_trains")) {
				cManager.LogError("We have already reached the train limit!");
				success = false;
			}
			local length = cBuilder.GetRailRoutePlatformLength(builder.stasrc, builder.stadst) * 2 - 2;
			success = success && builder.BuildAndStartTrains(1, length, engine, wagon, extra_wagon, mainvehicle, false, prod1_percent);
			break;

		case AIVehicle.VT_ROAD:
			local roadvehicles = AIVehicleList();
			roadvehicles.Valuate(AIVehicle.GetVehicleType);
			roadvehicles.KeepValue(AIVehicle.VT_ROAD);
			// Do not try to add one if we have already reached the road vehicle limit
			if (roadvehicles.Count() + 1 > AIGameSettings.GetValue("vehicle.max_roadveh")) {
				cManager.LogError("We have already reached the road vehicle limit!");
				success = false;
			}
			success = success && builder.BuildAndStartVehicles(engine, 1, mainvehicle);
			break;

		case AIVehicle.VT_AIR:
			local planes = AIVehicleList();
			planes.Valuate(AIVehicle.GetVehicleType);
			planes.KeepValue(AIVehicle.VT_AIR);
			// Do not try to add one if we have already reached the aircraft limit
			if (planes.Count() + 1 > AIGameSettings.GetValue("vehicle.max_aircraft")) {
				cManager.LogError("We have already reached the aircraft limit!");
				success = false;
			}
			success = success && builder.BuildAndStartVehicles(engine, 1, mainvehicle);
			break;
	}
	builder = null;
	return success;
}

function cManager::ReplaceVehicle(vehicle)
{
	local replaced = false;
	local group = AIVehicle.GetGroupID(vehicle);
	local route = root.routes[root.groups.GetValue(group)];
	local engine = null;
	local wagon = null;
	local wagoncrg = route.crg;
	local wagonminspeed = null;
	local extra_wagon = null;
	local railtype = AIRail.GetCurrentRailType();
	local vehtype = AIVehicle.GetVehicleType(vehicle);
	local platform;
	local engine_count = 1;
	// Choose a new engine
	switch (vehtype) {
		case AIVehicle.VT_RAIL:
			AIRail.SetCurrentRailType(route.railtype);
			platform = cBuilder.GetRailRoutePlatformLength(route.stasrc, route.stadst);
			if (route.last_date < AIDate.GetCurrentDate() - 60) {
				wagon = MyTrains.ChooseWagon(route.crg, root.engineblacklist);
				extra_wagon = MyTrains.ChooseWagon(route.extracrg, root.engineblacklist);
				if (wagon != null && (route.extracrg == null || extra_wagon != null)) {
					wagonminspeed = wagon;
					if (extra_wagon!= null) {
						if (AIEngine.GetMaxSpeed(wagon) > AIEngine.GetMaxSpeed(extra_wagon)) {
							wagonminspeed = extra_wagon;
							wagoncrg = route.extracrg;
						}
					}
					engine = MyTrains.ChooseTrainEngine(wagoncrg, AIMap.DistanceManhattan(AIStation.GetLocation(route.stasrc), AIStation.GetLocation(route.stadst)), wagonminspeed, platform * 2 - 1, root.engineblacklist);
					engine_count = cBuilder.GetNumEnginesNeeded(engine, route.homedepot, platform * 2 - 1, route.slopes, wagon, route.crg, extra_wagon, route.extracrg);
					route.last_wagon = wagon;
					route.last_extra_wagon = extra_wagon;
					route.last_engine = engine;
					route.last_date = AIDate.GetCurrentDate();
				}
			} else {
				wagon = route.last_wagon;
				extra_wagon = route.last_extra_wagon;
				engine = route.last_engine;
				engine_count = cBuilder.GetNumEnginesNeeded(engine, route.homedepot, platform * 2 - 1, route.slopes, wagon, route.crg, extra_wagon, route.extracrg);
			}
			break;
		case AIVehicle.VT_ROAD:
			engine = MyRoadVehs.ChooseRoadVeh(route.crg);
			break;
		case AIVehicle.VT_AIR:
			local srctype = AIAirport.GetAirportType(AIStation.GetLocation(route.stasrc));
			local dsttype = AIAirport.GetAirportType(AIStation.GetLocation(route.stadst));
			local is_small = MyAIAirport.IsSmallAirport(srctype) || MyAIAirport.IsSmallAirport(dsttype);
			engine = MyPlanes.ChoosePlane(route.crg, is_small, AIOrder.GetOrderDistance(AIVehicle.VT_AIR, AIStation.GetLocation(route.stasrc), AIStation.GetLocation(route.stadst)), false);
			break;
	}
	local vehicles = AIVehicleList_Group(group);
	local ordervehicle = null;
	// Choose a vehicle to share orders with
	foreach (nextveh, dummy in vehicles) {
		ordervehicle = nextveh;
		// Don't share orders with the vehicle which will be sold
		if (nextveh != vehicle)	break;
	}
	if (ordervehicle == vehicle) ordervehicle = null;
	if (AIVehicle.GetVehicleType(vehicle) == AIVehicle.VT_RAIL) {
		if (engine != null && wagon != null && (Banker.GetMaxBankBalance() > AIEngine.GetPrice(engine) * engine_count + 2 * platform * AIEngine.GetPrice(wagon) + Banker.GetMinimumCashNeeded())) {
			// Sell the train
			if (!cManager.AddVehicle(route, ordervehicle, engine, wagon, extra_wagon)) {
				cManager.LogError("Error found when adding new vehicle!");
				AIVehicle.StartStopVehicle(vehicle);
			} else {
				AIVehicle.SellWagonChain(vehicle, 0);
				replaced = true;
			}
		} else {
			// Restart the train if we cannot afford to replace it
			AIVehicle.StartStopVehicle(vehicle);
		}
		// Restore the previous railtype
		AIRail.SetCurrentRailType(railtype);
	} else {
		if (engine != null && (Banker.GetMaxBankBalance() > AIEngine.GetPrice(engine))) {
			if (!cManager.AddVehicle(route, ordervehicle, engine, null, null)) {
				cManager.LogError("Error found when adding new vehicle!");
				AIVehicle.StartStopVehicle(vehicle);
			} else {
				AIVehicle.SellVehicle(vehicle);
				replaced = true;
			}
		} else {
			AIVehicle.StartStopVehicle(vehicle);
		}
	}
	todepotlist.RemoveItem(vehicle);
	return replaced;
}

function cManager::CheckDefaultGroup()
{
	local vehtypes = [AIVehicle.VT_ROAD, AIVehicle.VT_RAIL, AIVehicle.VT_AIR];
	for (local x = 0; x < 3; x++) {
		// The same algorithm is used for all three vehicle types
		local vehicles = AIVehicleList_DefaultGroup(vehtypes[x]);
		vehicles.Valuate(AIVehicle.IsStoppedInDepot);
		vehicles.KeepValue(1);
		foreach (vehicle, dummy in vehicles) {
			// Check for vehicles sitting in the depot.
			if (AIVehicle.GetProfitThisYear(vehicle) != 0 || AIVehicle.GetProfitLastYear(vehicle) != 0 || AIVehicle.GetAge(vehicle) < 60) continue;
			if (todepotlist.HasItem(vehicle)) {
				todepotlist.RemoveItem(vehicle);
				AIVehicle.StartStopVehicle(vehicle);
			} else {
				LogWarning("Sold " + AIVehicle.GetName(vehicle) + ", as it has been sitting in the depot for ages.");
				if (vehtypes[x] == AIVehicle.VT_RAIL) {
					AIVehicle.SellWagonChain(vehicle, 0);
				} else {
					AIVehicle.SellVehicle(vehicle);
				}
			}
		}
	}
}

function cManager::CheckTodepotlist()
{
	// This is needed so as not to modify the todepotlist while iterating through it
	local itemstoremove = [];
	foreach (vehicle, dummy in todepotlist) {
		// Obviously shouldn't be there if it's not even valid
		if (!AIVehicle.IsValidVehicle(vehicle)) {
			LogWarning("There was an invalid vehicle in the todpeotlist.");
			itemstoremove.push(vehicle);
			continue;
		}
		// Everything is OK if it has already reached the depot
		if (AIVehicle.IsStoppedInDepot(vehicle)) continue;
		// Check its destination
		local vehicle_destination = AIOrder.GetOrderDestination(vehicle, AIOrder.ORDER_CURRENT);
		switch (AIVehicle.GetVehicleType(vehicle)) {
			case AIVehicle.VT_ROAD:
				if (!AIRoad.IsRoadDepotTile(vehicle_destination)) {
					itemstoremove.push(vehicle);
					LogWarning("" + AIVehicle.GetName(vehicle) + " is not heading for a depot although it is listed in the todepotlist.");
				}
				break;

			case AIVehicle.VT_RAIL:
				if (!AIRail.IsRailDepotTile(vehicle_destination)) {
					itemstoremove.push(vehicle);
					LogWarning("" + AIVehicle.GetName(vehicle) + " is not heading for a depot although it is listed in the todepotlist.");
				}
				break;

			case AIVehicle.VT_AIR:
				if (!AIAirport.IsHangarTile(vehicle_destination)) {
					itemstoremove.push(vehicle);
					LogWarning("" + AIVehicle.GetName(vehicle) + " is not heading for a hangar although it is listed in the todepotlist.");
				}
				break;
		}
	}
	foreach (item in itemstoremove) {
		todepotlist.RemoveItem(item);
	}
}

function cManager::SendTrainToDepot(vehicle)
{
	if (!AIVehicle.SendVehicleToDepot(vehicle)) {
		// Don't reverse if we are using PBS because reversed trains can block entire route.
		if (AISettings.IsSignalTypePBS()) return false;
		else {
			// Maybe the train only needs to be reversed to find a depot
			AIVehicle.ReverseVehicle(vehicle);
			AIController.Sleep(75);
			if (!AIVehicle.SendVehicleToDepot(vehicle)) {
				AIVehicle.ReverseVehicle(vehicle);
				return false;
			}
		}
	}
	return true;
}

function cManager::SendRoadVehcToDepot(vehicle)
{
	if (!AIVehicle.SendVehicleToDepot(vehicle)) {
		// Maybe the vehicle only needs to be reversed to find a depot
		AIVehicle.ReverseVehicle(vehicle);
		AIController.Sleep(75);
		if (!AIVehicle.SendVehicleToDepot(vehicle)) return false;
	}
	return true;
}

function cManager::PrintLog()
{
	return AISettings.GetAISetting("cManager_log", true);
}

function cManager::Debug()
{
	return (cManager.PrintLog()) ? AISettings.GetAISetting("cManager_log_debug", false) : false;
}
