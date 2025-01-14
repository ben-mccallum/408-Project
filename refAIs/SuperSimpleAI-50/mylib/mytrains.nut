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
 * Define the MyTrains class.
 * @depends: This class uses some mylib classes.
 */

class MyTrains
{
	/**
	 * Choose a rail wagon for the given cargo.
	 * @param cargo The cargo which will be transported by te wagon.
	 * @param blacklist A list of wagons that cannot be used.
	 * @return The EngineID of the chosen wagon, null if no suitable wagon was found.
	 */
	static function ChooseWagon(cargo, blacklist);

	/**
	 * Choose a train locomotive.
	 * @param crg The cargo to carry.
	 * @param distance The distance to be traveled.
	 * @param wagon The EngineID of the wagons to be pulled.
	 * @param num_wagons The number of wagons to be pulled.
	 * @param blacklist A list of engines that cannot be used.
	 * @return The EngineID of the chosen locomotive, null if no suitable locomotive was found.
	 */
	static function ChooseTrainEngine(crg, distance, wagon, num_wagons, blacklist);

	/**
	 * A valuator function for scoring train locomotives.
	 * @param engine The engine to be scored.
	 * @param weight The weight to be pulled.
	 * @param max_speed The maximum speed allowed.
	 * @param money The amount of money the company has.
	 * @return The score of the engine.
	 */
	static function TrainEngineValuator(engine, weight, max_speed, money);
}

function MyTrains::ChooseWagon(cargo, blacklist)
{
	if (cargo == null) return null;
	local wagonlist = AIEngineList(AIVehicle.VT_RAIL);
	wagonlist.Valuate(AIEngine.CanRunOnRail, AIRail.GetCurrentRailType());
	wagonlist.KeepValue(1);
	wagonlist.Valuate(AIEngine.IsWagon);
	wagonlist.KeepValue(1);
	wagonlist.Valuate(AIEngine.CanRefitCargo, cargo);
	wagonlist.KeepValue(1);
	wagonlist.Valuate(AIEngine.IsArticulated);
	// Only remove articulated wagons if there are non-articulated ones left
	local only_articulated = true;
	foreach (wagon, articulated in wagonlist) {
		if (articulated == 0) {
			only_articulated = false;
			break;
		}
	}
	if (!only_articulated) {
		wagonlist.KeepValue(0);
	}
	if (blacklist != null) {
		wagonlist.Valuate(MyAIList.ListContainsValuatorWithZeroValue, blacklist);
		wagonlist.KeepValue(0);
	}
	if (MyAICargo.IsPassengersCargo(cargo) || MyAICargo.IsMailCargo(cargo)) wagonlist.Valuate(AIEngine.GetMaxSpeed);
	else wagonlist.Valuate(AIEngine.GetCapacity);
	if (wagonlist.Count() == 0) return null;
	return wagonlist.Begin();
}

function MyTrains::ChooseTrainEngine(crg, distance, wagon, num_wagons, blacklist)
{
	if (crg == null || distance == null || wagon == null || num_wagons == null) return null;
	local max_speed = AIEngine.GetMaxSpeed(wagon);
	if (max_speed == 0) max_speed = 500;
	local enginelist = AIEngineList(AIVehicle.VT_RAIL);
	enginelist.Valuate(AIEngine.IsWagon);
	enginelist.KeepValue(0);
	enginelist.Valuate(AIEngine.HasPowerOnRail, AIRail.GetCurrentRailType());
	enginelist.KeepValue(1);
	if (enginelist.IsEmpty()) return null;
	if (blacklist != null) foreach (localengine, dummy in enginelist) if (MyAIList.ListContainsValuatorWithZeroValue(localengine * 65536 + wagon, blacklist)) enginelist.RemoveItem(localengine);
	enginelist.Valuate(AIEngine.GetMaxSpeed);
	enginelist.KeepAboveValue(max_speed - 1);
	if (enginelist.IsEmpty()) {
		enginelist = AIEngineList(AIVehicle.VT_RAIL);
		enginelist.Valuate(AIEngine.IsWagon);
		enginelist.KeepValue(0);
		enginelist.Valuate(AIEngine.HasPowerOnRail, AIRail.GetCurrentRailType());
		enginelist.KeepValue(1);
		if (blacklist != null) foreach (localengine, dummy in enginelist) if (MyAIList.ListContainsValuatorWithZeroValue(localengine * 65536 + wagon, blacklist)) enginelist.RemoveItem(localengine);
	}
	if (enginelist.IsEmpty()) return null;
	local money = MyAICompany.GetMyMaxBankBalance();
	local cargo_weight_factor = 0.5;
	if (AICargo.HasCargoClass(crg, AICargo.CC_PASSENGERS)) cargo_weight_factor = 0.05;
	if (AICargo.HasCargoClass(crg, AICargo.CC_BULK) || AICargo.HasCargoClass(crg, AICargo.CC_LIQUID)) cargo_weight_factor = 1;
	local weight = num_wagons * (AIEngine.GetWeight(wagon) + AIEngine.GetCapacity(wagon) * cargo_weight_factor);
	enginelist.Valuate(MyTrains.TrainEngineValuator, weight, max_speed, money);
	return enginelist.Begin();
}

function MyTrains::TrainEngineValuator(engine, weight, max_speed, money)
{
	local value = 0;
	local weight_with_engine = weight + AIEngine.GetWeight(engine);
	local hp_per_tonne = AIEngine.GetPower(engine).tofloat() / weight_with_engine.tofloat();
	local power_points = (hp_per_tonne > 4.0) ? ((hp_per_tonne > 16.0) ? (620 + 10 * hp_per_tonne / 4.0) : (420 + 60 * hp_per_tonne / 4.0)) : (-480 + 960 * hp_per_tonne / 4.0);
	value += power_points;
	local speed = AIEngine.GetMaxSpeed(engine);
	local speed_points = (speed > max_speed) ? (360 * max_speed / 112.0) : (360 * speed / 112.0);
	value += speed_points;
	local runningcost_limit = (6000 / MyAIGameSettings.GetInflationRate()).tointeger();
	local runningcost = (AIEngine.GetRunningCost(engine).tofloat() / MyAIGameSettings.GetInflationRate()).tointeger(); // dividing by inflation, so this value can be compared to a constant
	local runningcost_penalty = (runningcost > runningcost_limit) ? ((runningcost > 3 * runningcost_limit) ? (runningcost / 20.0 - 550.0) : (runningcost / 40.0 - 100.0)) : (runningcost / 120.0);
	value -= runningcost_penalty;
	return value.tointeger();
}

