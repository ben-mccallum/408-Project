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
 * Define the MyAICargo class which extends the AICargo functions.
 */
class MyAICargo /* extends AICargo */
{
	/**
	 * Gets the CargoID associated with mail.
	 * @return The CargoID of mail.
	 */
	static function GetMailCargo();

	/**
	 * Gets the CargoAI associated with passengers.
	 * @return The CargoID of passengers.
	 */
	static function GetPassengersCargo();

	/**
	 * Check if a cargo is passengers.
	 * @crg The cargo to transport.
	 * @return True if is.
	 */
	static function IsPassengersCargo(crg);

	/**
	 * Check if a cargo is mail.
	 * @crg The cargo to transport.
	 * @return True if is.
	 */
	static function IsMailCargo(crg);

	/**
	 * Check if a cargo is not passengers.
	 * @crg The cargo to transport.
	 * @return True if is.
	 */
	static function IsFreightCargo(crg);

	/**
	 * Get the name of the cargo type.
	 * @param cargo_type The cargo type to get the name of.
	 * @return The name of the cargo type.
	 */
	static function GetName(cargo_type);
}

function MyAICargo::GetMailCargo()
{
	local cargolist = AICargoList();
	foreach (cargo, dummy in cargolist) {
		if (MyAICargo.IsMailCargo(cargo)) return cargo;
	}
	return null;
}

function MyAICargo::GetPassengersCargo()
{
	local cargolist = AICargoList();
	foreach (cargo, dummy in cargolist) {
		if (MyAICargo.IsPassengersCargo(cargo)) return cargo;
	}
	return null;
}

function MyAICargo::IsPassengersCargo(crg)
{
	return (AICargo.GetTownEffect(crg) == AICargo.TE_PASSENGERS);
}

function MyAICargo::IsMailCargo(crg)
{
	return (AICargo.GetTownEffect(crg) == AICargo.TE_MAIL);
}

function MyAICargo::IsFreightCargo(crg)
{
	return !MyAICargo.IsPassengersCargo(crg);
}

if ("GetName" in AICargo) {
	function MyAICargo::GetName(cargo_type)
	{
		return AICargo.GetName(cargo_type);
	}
} else {
	// Some versions of OpenTTD doesn't have this function.
	function MyAICargo::GetName(cargo_type)
	{
		return AICargo.GetCargoLabel(cargo_type);
	}
}

