/**
 * This file is part of SuperSimpleAI: An OpenTTD AI.
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
 * Define the MyAIBridge class which extends the AIBridge functions.
 */
class MyAIBridge /* extends AIBridge */
{
	/**
	 * Test if we can build a rail bridge.
	 * @param start Where to start the bridge.
	 * @param end Where to end the bridge.
	 * @param is_cheap Bolean to build cheapest bridge.
	 * @return true if success.
	 */
	static function CanBuildRailBridge(start, end);
}

function MyAIBridge::CanBuildRailBridge(start, end)
{
	if (start == null || end == null) return false;
	if (AIMap.DistanceManhattan(start, end) >= AIGameSettings.GetValue("construction.max_bridge_length")) return false;
	local test = AITestMode();
	local bridgelist = AIBridgeList_Length(AIMap.DistanceManhattan(start, end) + 1);
	if (!AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridgelist.Begin(), start, end)) return false;
	test = null;
	return true;
}

