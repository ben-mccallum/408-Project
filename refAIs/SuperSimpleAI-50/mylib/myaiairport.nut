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
 * Define the MyAIAirport class which extends the AIAirport functions.
 */
class MyAIAirport /* extends AIAirport */
{
	/**
	 * Determines whether an airport type is only fit for small planes.
	 * @param airport_type The airport type to be examined.
	 * @return True if it is a small airport type.
	 */
	static function IsSmallAirport(airport_type);

	/**
	 * Determines whether an airport at a given tile is allowed by the town authorities
	 * because of the noise level
	 * @param tile The tile where the aiport would be built.
	 * @param airport_type The type of the airport.
	 * @return True if the construction would be allowed. If the noise setting is off, it defaults to true.
	 */
	static function IsWithinNoiseLimit(tile, airport_type);
}

function MyAIAirport::IsSmallAirport(airport_type)
{
	return (airport_type == AIAirport.AT_SMALL || airport_type == AIAirport.AT_COMMUTER);
}

function MyAIAirport::IsWithinNoiseLimit(tile, airport_type)
{
	if (!AIGameSettings.GetValue("economy.station_noise_level")) return true;
	return (AIAirport.GetNoiseLevelIncrease(tile, airport_type) <= AITown.GetAllowedNoise(AIAirport.GetNearestTown(tile, airport_type)));
}

