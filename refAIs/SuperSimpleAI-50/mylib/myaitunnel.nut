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
 * Define the MyAITunnel class which extends the AITunnel functions.
 */
class MyAITunnel /* extends AITunnel */
{
	/**
	 * Return the tunnel's cost.
	 * @param start start tile of the tunnel.
	 * @return Cost of tunnel, -1 if we can't build it.
	 */
	static function GetRoadTunnelCost(start);

	/**
	 * Return the tunnel's cost.
	 * @param start start tile of the tunnel.
	 * @return Cost of tunnel, -1 if we can't build it.
	 */
	static function GetRailTunnelCost(start);

	/**
	 * Return the tunnel cost.
	 * @param vehicle_type The vehicle-type of tunnel to build. 
	 * @param start Where to start the tunnel.
	 * @return Cost of tunnel, -1 if we can't build it.
	 */
	static function GetTunnelCost(vehicle_type, start);

	/**
	 * Test if we can build a road tunnel.
	 * @param start start tile of the tunnel.
	 * @param end other end of tunnel.
	 * @return true if success
	 */
	static function CanBuildRoadTunnel(start, end);

	/**
	 * Test if we can build a rail tunnel.
	 * @param start start tile of the tunnel.
	 * @param end other end of tunnel.
	 * @return true if success
	 */
	static function CanBuildRailTunnel(start, end);

	/**
	 * Test if we can build a tunnel.
	 * @param vehicle_type The vehicle-type of tunnel to build. 
	 * @param start start tile of the tunnel.
	 * @param end other end of tunnel.
	 * @return true if success
	 */
	static function CanBuildTunnel(vehicle_type, start, end);
}

function MyAITunnel::GetRoadTunnelCost(start)
{
	return MyAITunnel.GetTunnelCost(AIVehicle.VT_ROAD, start);
}

function MyAITunnel::GetRailTunnelCost(start)
{
	return MyAITunnel.GetTunnelCost(AIVehicle.VT_RAIL, start);
}

function MyAITunnel::GetTunnelCost(vehicle_type, start)
{
	if (start == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AITunnel.BuildTunnel(vehicle_type, start)) return -1;
	test = null;
	return cost.GetCosts();
}

function MyAITunnel::CanBuildRoadTunnel(start, end)
{
	return MyAITunnel.CanBuildTunnel(AIVehicle.VT_ROAD, start, end);
}

function MyAITunnel::CanBuildRailTunnel(start, end)
{
	return MyAITunnel.CanBuildTunnel(AIVehicle.VT_RAIL, start, end);
}

function MyAITunnel::CanBuildTunnel(vehicle_type, start, end)
{
	if (start == null) return false;
	if (AITunnel.GetOtherTunnelEnd(start) == AIMap.TILE_INVALID) return false;
	if (end == null) end = AITunnel.GetOtherTunnelEnd(start);
	if (AIMap.DistanceManhattan(start, end) + 1 > AIGameSettings.GetValue("construction.max_tunnel_length")) return false;
	if (AITunnel.GetOtherTunnelEnd(end) == AIMap.TILE_INVALID) return false;
	if (AIMap.DistanceManhattan(start, (AITunnel.GetOtherTunnelEnd(end))) != 0) return false;
	local test = AITestMode();
	if (!AITunnel.BuildTunnel(vehicle_type, start)) return false;
	test = null;
	return true;
}

