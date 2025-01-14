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
 * Build and start trains for the current route.
 * @param number The number of trains to be built.
 * @param length The number of wagons to be attached to the train.
 * @param engine The EngineID of the locomotive.
 * @param wagon The EngineID of the wagons.
 * @param ordervehicle The vehicle to share orders with. Null, if there is no such vehicle.
 * @param wait_for_money True wait for money, false exit without build any train.
 * @param prod1_percent Percentage of production of crg respect crg + extra_crg.
 * @return True if at least one train was built.
 */
function cBuilder::BuildAndStartTrains(number, length, engine, wagon, extra_wagon, ordervehicle, wait_for_money, prod1_percent = 50)
{
	if (number == null || length == null || engine == null || wagon == null) return false;
	local srcplace = AIStation.GetLocation(stasrc);
	local dstplace = AIStation.GetLocation(stadst);
	if (dstplace == null) dstplace = AIStation.GetLocation(stapass);

	local trainengines = [];
	local cur_trainengines = 0;

	// Build more power, if is needed
	local engine_count = GetNumEnginesNeeded(engine, homedepot, length, slopes, wagon, crg, extra_wagon, extracrg);

	// Check if we can afford building a train
	local short_train = (root.routes_active < 40) ? 4 + MyMath.Min(root.routes_active, length * 3) : 45;
	if (wait_for_money) {
		if (!cBuilder.WaitForMoney(AIEngine.GetPrice(engine) * engine_count + AIEngine.GetPrice(wagon) * short_train)) {
			LogWarning("I don't have enough money to build the train.");
			return false;
		}
	} else {
		if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(engine) * engine_count + AIEngine.GetPrice(wagon) * short_train && !Banker.GetMoney(AIEngine.GetPrice(engine) * engine_count + AIEngine.GetPrice(wagon) * short_train - MyAICompany.GetMyBankBalance())) return false;
	}

	// Try whether the engine is compatibile with the wagon
	if (!cBuilder.IsEngineCompatibleWithWagon(homedepot, engine, wagon, root.engineblacklist)) return false;
	if (extra_wagon != null && !cBuilder.IsEngineCompatibleWithWagon(homedepot, engine, extra_wagon, root.engineblacklist)) return false;

	// Build and refit the train engines if needed
	while (engine_count > cur_trainengines) {
		trainengines.push(AIVehicle.BuildVehicle(homedepot, engine));
		//trainengines[cur_trainengines] = AIVehicle.BuildVehicle(homedepot, engine);
		if (!AIVehicle.IsValidVehicle(trainengines[cur_trainengines])) {
			// safety, suggestion by krinn
			LogError("The train engine #" + (cur_trainengines + 1) + " did not get built: " + AIError.GetLastErrorString());
			if (cur_trainengines == 0) return false;
		} else {
			AIVehicle.RefitVehicle(trainengines[cur_trainengines], crg);
		}
		cur_trainengines++;
	}

	local firstwagon = AIVehicle.BuildVehicle(homedepot, wagon);
	local wagon_length = AIVehicle.GetLength(firstwagon);
	local wagon_capacity = AIVehicle.GetCapacity(firstwagon, AIEngine.GetCargoType(wagon));

	// Build a mail wagon
	local mailwagontype = null, mailwagon = null;
	local mailwagon_length = 0;
	local nummailwagons = (length > 3) ? ((length > 5) ? 2 : 1) : 0;
	if (wagon_length < 7 && length > 5) nummailwagons++;
	if (wagon_length < 6) nummailwagons++;
	local mailcargo = MyAICargo.GetMailCargo();
	if (mailcargo == null) nummailwagons = 0;
	if (nummailwagons > 0 && MyAICargo.IsPassengersCargo(crg)) {
		// Choose a wagon for mail
		mailwagontype = MyTrains.ChooseWagon(mailcargo, root.engineblacklist);
		if (mailwagontype == null) mailwagontype = wagon;
		if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(mailwagontype)) Banker.SetMinimumBankBalance(AIEngine.GetPrice(mailwagontype));
		mailwagon = AIVehicle.BuildVehicle(homedepot, mailwagontype);
		if (mailwagon != null) {
			// Try to refit the mail wagon if needed
			local mailwagoncargo = AIEngine.GetCargoType(AIVehicle.GetEngineType(mailwagon));
			if (!MyAICargo.IsMailCargo(mailwagoncargo)) {
				if (mailwagontype == wagon) {
					// Some workaround if the mail wagon type is the same as the wagon type
					MyAIVehicle.MailWagonWorkaround(mailwagon, firstwagon, trainengines[0], mailcargo);
				} else {
					if (!AIVehicle.RefitVehicle(mailwagon, mailcargo)) {
						// If no mail wagon was found, and the other wagons needed to be refitted, refit the "mail wagon" as well
						if (mailwagoncargo != crg) AIVehicle.RefitVehicle(mailwagon, crg);
					}
				}
			}
		}
	}
	local cur_mailwagons = nummailwagons;
	while (cur_mailwagons > 1 && MyAICargo.IsPassengersCargo(crg)) {
		// Choose a wagon for mail
		if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(mailwagontype)) Banker.SetMinimumBankBalance(AIEngine.GetPrice(mailwagontype));
		WaitForMoney(AIEngine.GetPrice(mailwagon));
		local moremailwagon = AIVehicle.BuildVehicle(homedepot, mailwagontype);
		if (moremailwagon != null) {
			// Try to refit the mail wagon if needed
			local mailwagoncargo = AIEngine.GetCargoType(AIVehicle.GetEngineType(moremailwagon));
			if (!MyAICargo.IsMailCargo(mailwagoncargo)) {
				if (mailwagontype == wagon) {
					// Some workaround if the mail wagon type is the same as the wagon type
					MyAIVehicle.MailWagonWorkaround(moremailwagon, firstwagon, trainengines[0], mailcargo);
				} else {
					if (!AIVehicle.RefitVehicle(moremailwagon, mailcargo)) {
						// If no mail wagon was found, and the other wagons needed to be refitted, refit the "mail wagon" as well
						if (mailwagoncargo != crg) AIVehicle.RefitVehicle(moremailwagon, crg);
					}
				}
			}
		}
		cur_mailwagons--;
	}
	// Add extra wagons for dual cargo trains.
	local secondwagon = null;
	if (extra_wagon != null) {
		if (wagon != extra_wagon) {
			secondwagon = AIVehicle.BuildVehicle(homedepot, extra_wagon);
			// Blacklist the wagon if it is too long
			if (AIVehicle.GetLength(secondwagon) > 8) {
				root.engineblacklist.AddItem(extra_wagon, 0);
				SuperSimpleAI.LogNotice(AIEngine.GetName(extra_wagon) + " was blacklisted for being too long.");
				while (engine_count > 0) {
					engine_count--;
					AIVehicle.SellVehicle(trainengines[engine_count]);
				}
				AIVehicle.SellVehicle(firstwagon);
				AIVehicle.SellVehicle(secondwagon);
				return false;
			}
			// Try whether the engine is compatibile with the wagon
			{
				local testmode = AITestMode();
				if (!AIVehicle.MoveWagonChain(secondwagon, 0, trainengines[0], 0)) {
					root.engineblacklist.AddItem(engine, 0);
					SuperSimpleAI.LogNotice(AIEngine.GetName(engine) + " was blacklisted for not being compatibile with " + AIEngine.GetName(extra_wagon) + ".");
					local execmode = AIExecMode();
					while (engine_count > 0) {
						engine_count--;
						AIVehicle.SellVehicle(trainengines[engine_count]);
					}
					AIVehicle.SellVehicle(firstwagon);
					AIVehicle.SellVehicle(secondwagon);
					return false;
				}
			}
		} else secondwagon = firstwagon;
	}
	local extra_wagon_length = (extra_wagon != null) ? AIVehicle.GetLength(secondwagon) : 0;
	local extra_wagon_capacity = (extra_wagon != null) ? AIVehicle.GetCapacity(secondwagon, AIEngine.GetCargoType(extra_wagon)) : 0;
	local engine_length = AIVehicle.GetLength(trainengines[0]);
	if (mailwagon != null) {
		if (mailwagontype == wagon) {
			wagon_length /= nummailwagons + 1;
			mailwagon_length = wagon_length * nummailwagons;
		} else {
			mailwagon_length = AIVehicle.GetLength(mailwagon);
		}
	}
	local cur_wagons = 1;
	local cur_extra_wagons = (extra_wagon != null && extra_wagon != wagon) ? 1 : 0;
	local platform_length = length / 2 + 1;
	while (engine_length * engine_count + cur_wagons * wagon_length + mailwagon_length + cur_extra_wagons * extra_wagon_length + ((wagon_length > extra_wagon_length) ? wagon_length : extra_wagon_length) <= platform_length * 16) {
		//LogDebug("Current length: " + (AIVehicle.GetLength(trainengines[0]) * engine_count + (cur_wagons + 1) * wagon_length + mailwagon_length + cur_extra_wagons * extra_wagon_length));
		if (extra_wagon != null && cur_extra_wagons * extra_wagon_capacity * prod1_percent < cur_wagons * wagon_capacity * (100 - prod1_percent)) cur_extra_wagons++;
		else {
			if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(wagon)) Banker.SetMinimumBankBalance(AIEngine.GetPrice(wagon));
			if (cur_wagons < 3) WaitForMoney(AIEngine.GetPrice(wagon));
			if (MyAICompany.GetMyBankBalance() < 10000) if (!Banker.GetMoney(10000)) break;
			if (!AIVehicle.BuildVehicle(homedepot, wagon)) break;
			cur_wagons++;
		}
	}
	// Refit the wagons if needed
	if (AIEngine.GetCargoType(wagon) != crg) AIVehicle.RefitVehicle(firstwagon, crg);
	// Attach the wagons to the engine
	if (mailwagon != null) {
		if (wagon != mailwagontype && !AIVehicle.MoveWagonChain(mailwagon, 0, trainengines[0], 0) || wagon == mailwagontype && !AIVehicle.MoveWagon(firstwagon, 1, trainengines[0], 0)) {
			LogError("Could not attach the wagons.");
			root.engineblacklist.AddItem(engine, 0);
			LogWarning(AIEngine.GetName(engine) + " was blacklisted for not being compatibile with " + AIEngine.GetName(mailwagontype) + ".");
			while (engine_count > 0) {
				engine_count--;
				AIVehicle.SellVehicle(trainengines[engine_count]);
			}
			AIVehicle.SellWagonChain(firstwagon, 0);
			AIVehicle.SellVehicle(mailwagon);
			if (secondwagon != null) AIVehicle.SellVehicle(secondwagon);
			return false;
		}
	}
	if (!AIVehicle.MoveWagonChain(firstwagon, 0, trainengines[0], 0)) {
		LogError("Could not attach the wagons.");
		while (engine_count > 0) {
			engine_count--;
			AIVehicle.SellVehicle(trainengines[engine_count]);
		}
		AIVehicle.SellWagonChain(firstwagon, 0);
		if (secondwagon != null) AIVehicle.SellVehicle(secondwagon);
	}
	if (extra_wagon != null) {
		if (extra_wagon == wagon) secondwagon = AIVehicle.BuildVehicle(homedepot, extra_wagon);
		cur_extra_wagons = 1;
		while (engine_length * engine_count + cur_wagons * wagon_length + (cur_extra_wagons + 1) * extra_wagon_length <= platform_length * 16) {
			if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(wagon)) Banker.SetMinimumBankBalance(AIEngine.GetPrice(extra_wagon));
			if (cur_extra_wagons < 3) WaitForMoney(AIEngine.GetPrice(extra_wagon));
			if (MyAICompany.GetMyBankBalance() < 10000) if (!Banker.GetMoney(10000)) break;
			if (!AIVehicle.BuildVehicle(homedepot, extra_wagon)) break;
			cur_extra_wagons++;
		}
		if (AIEngine.GetCargoType(extra_wagon) != extracrg) AIVehicle.RefitVehicle(secondwagon, extracrg);
		if (!AIVehicle.MoveWagonChain(secondwagon, 0, trainengines[0], 0)) {
			LogError("Could not attach the wagons.");
			while (engine_count > 0) {
				engine_count--;
				AIVehicle.SellVehicle(trainengines[engine_count]);
			}
			AIVehicle.SellWagonChain(firstwagon, 0);
			AIVehicle.SellWagonChain(secondwagon, 0);
		}
	}

	while (engine_count > 1) {
		engine_count--;
		AIVehicle.MoveWagon(trainengines[engine_count], 0, trainengines[0], 0);
	}
	if (ordervehicle == null) {
		// Set the train's orders
		local firstorderflag = null;
		local passorderflag = null;
		local secondorderflag = null;
		if (MyAICargo.IsPassengersCargo(crg) || MyAICargo.IsMailCargo(crg)) {
			// Do not full load a passenger train
			firstorderflag = AIOrder.OF_NON_STOP_INTERMEDIATE;
			passorderflag = AIOrder.OF_NON_STOP_INTERMEDIATE;
			secondorderflag = AIOrder.OF_NON_STOP_INTERMEDIATE;
		} else {
			firstorderflag = AIOrder.OF_FULL_LOAD_ANY + AIOrder.OF_NO_UNLOAD + AIOrder.OF_NON_STOP_INTERMEDIATE;
			passorderflag = AIOrder.OF_NO_LOAD + AIOrder.OF_NON_STOP_INTERMEDIATE;
			secondorderflag = AIOrder.OF_NO_LOAD + AIOrder.OF_UNLOAD + AIOrder.OF_NON_STOP_INTERMEDIATE;
		}
		AIOrder.AppendOrder(trainengines[0], srcplace, firstorderflag);
		if (extra_dst != null && stapass != null) AIOrder.AppendOrder(trainengines[0], AIStation.GetLocation(stapass), passorderflag);
		AIOrder.AppendOrder(trainengines[0], dstplace, secondorderflag);
		AIOrder.SetStopLocation(trainengines[0], 0, AIOrder.STOPLOCATION_NEAR);
		if (extra_dst == null || stapass == null) AIOrder.SetStopLocation(trainengines[0], 1, AIOrder.STOPLOCATION_NEAR);
		else AIOrder.SetStopLocation(trainengines[0], 2, AIOrder.STOPLOCATION_NEAR);
	} else {
		AIOrder.ShareOrders(trainengines[0], ordervehicle);
	}
	AIVehicle.StartStopVehicle(trainengines[0]);
	AIGroup.MoveVehicle(group, trainengines[0]);
	return true;
}

/**
 * Attach more wagons to a train after it has been sent to the depot.
 * @param vehicle The VehicleID of the train.
 */
function cBuilder::AttachMoreWagons(vehicle)
{
	// Get information about the train's group
	local group = AIVehicle.GetGroupID(vehicle);
	local route = root.routes[root.groups.GetValue(group)];
	local railtype = AIRail.GetCurrentRailType();
	AIRail.SetCurrentRailType(route.railtype);
	local depot = AIVehicle.GetLocation(vehicle);
	local prod1_percent = MyAIIndustry.GetProductionPercentage(route.src, route.crg, route.extracrg);
	// Choose a wagon
	local wagon = MyTrains.ChooseWagon(route.crg, root.engineblacklist);
	local extra_wagon = (route.extracrg != null) ? MyTrains.ChooseWagon(route.extracrg, root.engineblacklist) : null;
	if (wagon == null || (route.extracrg != null && extra_wagon == null)) {
		AIRail.SetCurrentRailType(railtype);
		return;
	}
	// Build the first wagon
	if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(wagon)) {
		if (!Banker.SetMinimumBankBalance(AIEngine.GetPrice(wagon))) {
			LogInfo("I don't have enough money to attach more wagons to " + AIVehicle.GetName(vehicle) + ".");
			AIRail.SetCurrentRailType(railtype);
			return;
		}
	}
	local firstwagon = AIVehicle.BuildVehicle(depot, wagon);
	// Blacklist the wagon if it is too long
	if (AIVehicle.GetLength(firstwagon) > 8) {
		root.engineblacklist.AddItem(wagon, 0);
		SuperSimpleAI.LogInfo(AIEngine.GetName(wagon) + " was blacklisted for being too long.");
		AIVehicle.SellVehicle(firstwagon);
		AIRail.SetCurrentRailType(railtype);
		return;
	}
	// Build the second wagon if it's dual cargo train.
	local secondwagon = null;
	if (extra_wagon != null) {
		if (wagon != extra_wagon) {
			if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(extra_wagon)) {
				if (!Banker.SetMinimumBankBalance(AIEngine.GetPrice(extra_wagon))) {
					LogInfo("I don't have enough money to attach more wagons to " + AIVehicle.GetName(vehicle) + ".");
					AIVehicle.SellVehicle(firstwagon);
					AIRail.SetCurrentRailType(railtype);
					return;
				}
			}
			secondwagon = AIVehicle.BuildVehicle(depot, extra_wagon);
			// Blacklist the wagon if it is too long
			if (AIVehicle.GetLength(secondwagon) > 8) {
				root.engineblacklist.AddItem(extra_wagon, 0);
				SuperSimpleAI.LogInfo(AIEngine.GetName(extra_wagon) + " was blacklisted for being too long.");
				AIVehicle.SellVehicle(firstwagon);
				AIVehicle.SellVehicle(secondwagon);
				AIRail.SetCurrentRailType(railtype);
				return;
			}
		} else secondwagon = firstwagon;
	}
	// Attach additional wagons
	local wagon_length = AIVehicle.GetLength(firstwagon);
	local extra_wagon_length = (extra_wagon != null) ? AIVehicle.GetLength(secondwagon) : 0;
	local wagon_capacity = AIVehicle.GetCapacity(firstwagon, AIEngine.GetCargoType(wagon));
	local extra_wagon_capacity = (extra_wagon != null) ? AIVehicle.GetCapacity(secondwagon, AIEngine.GetCargoType(extra_wagon)) : 0;
	local vehicle_capacity = AIVehicle.GetCapacity(vehicle, route.crg);
	local vehicle_extra_capacity = (extra_wagon != null) ? AIVehicle.GetCapacity(vehicle, route.extracrg) : 0;
	local cur_wagons = 1;
	local cur_extra_wagons = (extra_wagon != null /* && extra_wagon != wagon*/) ? 1 : 0;
	local platform_length = MyMath.Min(cBuilder.GetRailRoutePlatformLength(route.stasrc, route.stadst), MyAIGameSettings.EfectiveMaxTrainLength());
	if (extra_wagon != null) {
		while (vehicle_extra_capacity + extra_wagon_capacity * cur_extra_wagons < vehicle_capacity && AIVehicle.GetLength(vehicle) + (cur_extra_wagons + 1) * extra_wagon_length <= platform_length * 16) {
			if (!cBuilder.BuildVehicle(depot, extra_wagon)) break;
			cur_extra_wagons++;
		}
		if (AIEngine.GetCargoType(extra_wagon) != route.extracrg) AIVehicle.RefitVehicle(secondwagon, route.extracrg);
		AIVehicle.MoveWagonChain(secondwagon, 0, vehicle, AIVehicle.GetNumWagons(vehicle) - 1);
		if (extra_wagon == wagon) firstwagon = AIVehicle.BuildVehicle(depot, wagon);
	}
	if (AIVehicle.GetLength(vehicle) + wagon_length <= platform_length * 16) {
		cur_extra_wagons = 0;
		while (AIVehicle.GetLength(vehicle) + cur_wagons * wagon_length + cur_extra_wagons * extra_wagon_length + ((wagon_length > extra_wagon_length) ? wagon_length : extra_wagon_length) <= platform_length * 16) {
			if (extra_wagon != null && vehicle_extra_capacity + cur_extra_wagons * extra_wagon_capacity * prod1_percent < vehicle_capacity + cur_wagons * wagon_capacity * (100 - prod1_percent)) cur_extra_wagons++;
			else {
				if (!cBuilder.BuildVehicle(depot, wagon)) break;
				cur_wagons++;
			}
		}
		// Refit the wagons if needed
		if (AIEngine.GetCargoType(wagon) != route.crg) AIVehicle.RefitVehicle(firstwagon, route.crg);
		// Attach the wagons to the engine
		AIVehicle.MoveWagonChain(firstwagon, 0, vehicle, AIVehicle.GetNumWagons(vehicle) - 1);
		if (cur_extra_wagons > 0) {
			secondwagon = AIVehicle.BuildVehicle(depot, extra_wagon);
			while (cur_extra_wagons > 1) {
				if (!cBuilder.BuildVehicle(depot, extra_wagon)) break;
				cur_extra_wagons--;
			}
			if (AIEngine.GetCargoType(extra_wagon) != route.extracrg) AIVehicle.RefitVehicle(secondwagon, route.extracrg);
			AIVehicle.MoveWagonChain(secondwagon, 0, vehicle, AIVehicle.GetNumWagons(vehicle) - 1);
		}
	} else AIVehicle.SellVehicle(firstwagon);
	cManager.LogInfo("Added more wagons to " + AIVehicle.GetName(vehicle) + ".");
	AIRail.SetCurrentRailType(railtype);
}

/**
 * Builds a vehicle with the given engine at the given depot.
 * @param depot The depot where the vehicle will be build.
 * @param engine_id The engine to use for this vehicle.
 */
function cBuilder::BuildVehicle(depot, engine_id)
{
	if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(engine_id)) Banker.SetMinimumBankBalance(AIEngine.GetPrice(engine_id));
	return AIVehicle.BuildVehicle(depot, engine_id);
}

/**
 * Build and start road vehicles or planes for the current route.
 * Builder class variables used: stasrc, stadst, homedepot
 * @param veh The EngineID of the desired vehicle.
 * @param number How many vehicles are needed.
 * @param ordervehicle The vehicle to share orders with. Null if there's no such vehicle.
 * @return True if at least one vehicle was built.
 */
function cBuilder::BuildAndStartVehicles(veh, number, ordervehicle)
{
	// These local variables are needed because this function may be called from the manager
	local srcplace = AIStation.GetLocation(stasrc);
	local dstplace = AIStation.GetLocation(stadst);
	local price = AIEngine.GetPrice(veh);
	// Check if we have enough money
	if (MyAICompany.GetMyBankBalance() < price) {
		if (!Banker.SetMinimumBankBalance(price)) {
			LogWarning("I don't have enough money to build the road vehicles.");
			return false;
		}
	}
	// Build and refit the first vehicle
	local firstveh = AIVehicle.BuildVehicle(homedepot, veh);
	if (AIEngine.GetCargoType(veh) != crg) AIVehicle.RefitVehicle(firstveh, crg);
	if (ordervehicle == null) {
		// If there is no other vehicle to share orders with
		local firstorderflag = null;
		local secondorderflag = AIOrder.OF_NON_STOP_INTERMEDIATE;
		// Non-stop is not needed for planes
		if (AIEngine.GetVehicleType(veh) == AIVehicle.VT_AIR) firstorderflag = secondorderflag = AIOrder.OF_NONE;
		else {
			if (MyAICargo.IsPassengersCargo(crg) || MyAICargo.IsMailCargo(crg)) {
				firstorderflag = AIOrder.OF_NON_STOP_INTERMEDIATE;
			} else {
				firstorderflag = AIOrder.OF_FULL_LOAD_ANY + AIOrder.OF_NON_STOP_INTERMEDIATE;
			}
		}
		AIOrder.AppendOrder(firstveh, srcplace, firstorderflag);
		AIOrder.AppendOrder(firstveh, dstplace, secondorderflag);
	} else {
		AIOrder.ShareOrders(firstveh, ordervehicle);
	}
	AIVehicle.StartStopVehicle(firstveh);
	AIGroup.MoveVehicle(group, firstveh);
	for (local idx = 2; idx <= number; idx++) {
		// Clone the first vehicle if we need more than one vehicle
		if (MyAICompany.GetMyBankBalance() < price) {
			Banker.SetMinimumBankBalance(price);
		}
		local nextveh = AIVehicle.CloneVehicle(homedepot, firstveh, true);
		AIVehicle.StartStopVehicle(nextveh);
	}
	return true;
}

/**
 * Get de number of vehicles that a route can has, depending de distance.
 * @param dist
 * @return Number of vehicles.
 */
function cBuilder::NumRoadVehicles(dist)
{
	return MyMath.Clamp(AISettings.GetRoadDensity(dist), AISettings.GetMinRoadVehicles(), AISettings.GetMaxRoadVehicles());
}

/**
 * Get the number of engines that train needs.
 * @param engine EngineId of train to build.
 * @param depot Local depot where build the train.
 * @param length Length of train.
 * @param myslopes Coded type of line: 0 = descending route, 1 = flat route, 2 & 3 = ascending route.
 * @param wagon1 WagonId of train to build.
 * @param crg1 CargoId to be transported.
 * @param wagon2 Secondary WagonId of train to build (optional).
 * @param crg2 Secondary CargoId to be transported (optional).
 * @return Number of engines to build.
 */
function cBuilder::GetNumEnginesNeeded(engine, depot, length, myslopes, wagon1, crg1, wagon2 = null, crg2 = null)
{
	if (engine == null || depot == null || wagon1 == null || AISettings.IsOldStyleRailLine()) return 1;
	local wagon_length = (wagon2 == null) ? cBuilder.GetWagonLength(depot, wagon1) : MyMath.Average(cBuilder.GetWagonLength(depot, wagon1), cBuilder.GetWagonLength(depot, wagon2));
	local engine_power = AIEngine.GetPower(engine) * 16 * wagon_length;
	local engine_maxtractiveeffort = AIEngine.GetMaxTractiveEffort(engine);
	if (engine_maxtractiveeffort == 0 || engine_maxtractiveeffort == null) engine_maxtractiveeffort = 10000;
	else engine_maxtractiveeffort *= 125 * wagon_length;
	local engine_max_speed = (wagon2 == null) ? AIEngine.GetMaxSpeed(wagon1) : MyMath.Min(AIEngine.GetMaxSpeed(wagon1), AIEngine.GetMaxSpeed(wagon2));
	local engine_capacity = (wagon2 == null) ? AIEngine.GetCapacity(wagon1) : MyMath.Average(AIEngine.GetCapacity(wagon1), AIEngine.GetCapacity(wagon2));
	if (engine_max_speed == 0) engine_max_speed = AIEngine.GetMaxSpeed(engine);
	if (myslopes == null) myslopes = (slopes == mull) ? 3 : slopes;
	local engine_count = 1;
	local freight_trains = MyAICargo.IsFreightCargo(crg1) ? (AIGameSettings.GetValue("freight_trains") + 1 + myslopes) / 2 : 2;
	local train_engines = MyAICargo.IsFreightCargo(crg1) ? AISettings.GetMaxNumEngines() : MyMath.Min(AISettings.GetMaxNumEngines(), 3);
	while (train_engines >= engine_count && length > 1 + 2 * engine_count && MyMath.Min(engine_power, engine_maxtractiveeffort) * engine_count < (length + 1 - engine_count) * engine_max_speed * engine_capacity * freight_trains) engine_count++;
	return engine_count;
}

/**
 * This is a cache of MyAIEngine.GetLength() function.
 * @depot A valid depot where do the test.
 * @wagon The wagon to get the length of.
 * @return The length of vehicle.
 */
function cBuilder::GetWagonLength(depot, wagon)
{
	local len;
	if (root.wagonlenlist.HasItem(wagon)) len = root.wagonlenlist.GetValue(wagon);
	else {
		len = MyAIEngine.GetLength(depot, wagon);
		root.wagonlenlist.AddItem(wagon, len);
	}
	return len;
}

function cBuilder::IsEngineCompatibleWithWagon(depot, engine, wagon, blacklist)
{
	local key = engine * 65536 + wagon;
	if (blacklist.HasItem(key)) {
		if (blacklist.GetValue(key) == 1) return true;
		else return false;
	}
	if (!cBuilder.WaitForMoney(AIEngine.GetPrice(engine) + AIEngine.GetPrice(wagon))) return false;
	if (MyAICompany.GetMyBankBalance() < AIEngine.GetPrice(engine) + AIEngine.GetPrice(wagon) && !Banker.GetMoney(AIEngine.GetPrice(engine) + AIEngine.GetPrice(wagon) - MyAICompany.GetMyBankBalance())) return false;
	local testengine = AIVehicle.BuildVehicle(depot, engine);
	if (!AIVehicle.IsValidVehicle(testengine)) {
		// safety, suggestion by krinn
		LogError("The train engine " + AIEngine.GetName(engine) + " did not get built: " + AIError.GetLastErrorString());
		return false;
	}
	local ret = true;
	local testwagon = AIVehicle.BuildVehicle(depot, wagon);
	// Blacklist the wagon if it is too long
	if (AIVehicle.GetLength(testwagon) > 8) {
		blacklist.AddItem(wagon, 0);
		SuperSimpleAI.LogNotice(AIEngine.GetName(wagon) + " was blacklisted for being too long.");
		ret = false;
	}
	if (ret) {
		// Try whether the engine is compatibile with the wagon
		local testmode = AITestMode();
		if (!AIVehicle.MoveWagonChain(testwagon, 0, testengine, 0)) {
			blacklist.AddItem(key, 0);
			SuperSimpleAI.LogNotice(AIEngine.GetName(engine) + " was blacklisted for not being compatibile with " + AIEngine.GetName(wagon) + ".");
			ret = false;
		} else {
			blacklist.AddItem(key, 1);
			SuperSimpleAI.LogNotice(AIEngine.GetName(engine) + " is compatibile with " + AIEngine.GetName(wagon) + ".");
		}
		testmode = null;
	}
	AIVehicle.SellVehicle(testengine);
	AIVehicle.SellVehicle(testwagon);
	return ret;
}
