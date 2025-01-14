/**
 * This file is part of SuperSimpleAI: An OpenTTD AI.
 *
 * Based on code from SimpleAI and DictatorAI.
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
 * Define the MyAIEngine class which extends the AIEngine functions.
 */
class MyAIEngine /* extends AIEngine */
{
	/**
	 * Check if a cargo is passengers.
	 * @depot A valid depot where do the test.
	 * @engine_id The engine to get the length of.
	 * @return The length of vehicle.
	 */
	static function GetLength(depot, engine_id);

	/**
	 * Get the maximum range that planes can support.
	 * @return The maximum range that planes can support, 0 if unlimited.
	 */
	static function GetMaximumAircraftRange();

	/**
	 * Determines whether small aircraft are available.
	 * @return True if small aircraft are available.
	 */
	static function IsSmallAircraftAvailable();

	/**
	 * Valuate a road vehicle based on raw capacity/speed ratio.
	 * Taken from DictatorAI.
	 * @param engine The road vehicle to be valuated.
	 * @param cargoID The cargo to be trasported.
	 * @param fast If true, try to get the fastest engine even if the capacity is a bit lower.
	 * @return A numerical value representing the fitness of the engine, the lower the better.
	 */
	static function GetEngineEfficiency(engine, cargoID, fast);
}

function MyAIEngine::GetLength(depot, engine_id)
{
	if (depot == null) return 8;
	if (engine_id == null) return 0;
	local len = 0;
	local engine = AIVehicle.BuildVehicle(depot, engine_id);
	if (AIVehicle.IsValidVehicle(engine)) {
		len = AIVehicle.GetLength(engine);
		AIVehicle.SellVehicle(engine);
	}
	return len;
}

function MyAIEngine::GetMaximumAircraftRange()
{
	local planelist = AIEngineList(AIVehicle.VT_AIR);
	planelist.Valuate(AIEngine.GetPlaneType);
	planelist.RemoveValue(AIAirport.PT_INVALID);
	planelist.RemoveValue(AIAirport.PT_HELICOPTER);
	planelist.Valuate(AIEngine.GetMaximumOrderDistance);
	local max = planelist.GetValue(planelist.Begin());
	planelist.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	if (planelist.GetValue(planelist.Begin()) == 0) return 0;
	else return max;
}

function MyAIEngine::IsSmallAircraftAvailable()
{
	planelist = AIEngineList(AIVehicle.VT_AIR);
	planelist.Valuate(AIEngine.GetPlaneType);
	planelist.RemoveValue(AIAirport.PT_INVALID);
	planelist.RemoveValue(AIAirport.PT_BIG_PLANE);
	planelist.RemoveValue(AIAirport.PT_HELICOPTER); // Maybe don't allow zeppelins?
	return (planelist.Count() > 0);
}

function MyAIEngine::GetEngineEfficiency(engine, cargoID, fast)
{
	local price = AIEngine.GetPrice(engine);
	local capacity = AIEngine.GetCapacity(engine);
	local speed = AIEngine.GetMaxSpeed(engine);
	if (speed > 150) speed = (speed * 0.9).tointeger();
	local lifetime = AIEngine.GetMaxAge(engine);
	local runningcost = AIEngine.GetRunningCost(engine);
	if (capacity <= 0) return 9999999;
	if (price <= 0) return 9999999;
	local eff = 0;
	if (fast) eff = 1000000 / ((capacity*0.9)+speed).tointeger();
	else eff = 1000000-(capacity * speed);
	return eff;
}

