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
 * Define the Banker class.
 */
class Banker
{
	/**
	 * Loans the given amount of money from the bank.
	 * This function was written by Brumi for SimpleAI.
	 * @param money The amount to loan.
	 * @return True if the loaning succeeded.
	 */
	static function GetMoney(money);

	/**
	 * Calculates how much cash will be on hand if the maximum loan is taken.
	 * @return The maximum amount of money.
	 */
	static function GetMaxBankBalance();

	/**
	 * Adjusts the loan so that the company will have at least the given amount of money.
	 * This function was written by Brumi for SimpleAI.
	 * @param money The minimum amount of money to have.
	 * @return True if the action succeeded.
	 */
	static function SetMinimumBankBalance(money);

	/**
	 * Pays back loan if possible, but tries to have at least the loan interval (10,000 pounds)
	 * This function was written by Brumi for SimpleAI.
	 * @return True if the action succeeded.
	 */
	static function PayLoan();

	/**
	 * Calculates how much money is needed to build plane routes.
	 * This function depends of cBuilder class.
	 * @return The minimum amount of money.
	 */
	static function MinimumMoneyToUseAircraft();

	/**
	 * Returns how much money we need in settings.nut file.
	 * @return The minimum amount of money.
	 */
	static function GetMinimumMoneyToUseAirRoute();

	/**
	 * Calculates the minimum amount of cash needed to be at hand. This is used to
	 * avoid going bankrupt because of station maintenance costs.
	 * @return 10000 pounds plus the expected station maintenance costs.
	 */
	static function GetMinimumCashNeeded();

	/**
	 * Multiplies a given amount by the inflation rate and returns the new value.
	 * This function was written by Brumi for SimpleAI.
	 * @param amount The amount of money to multiply.
	 * @return The inflated value of the given amount.
	 */
	static function InflatedValue(amount);

	/**
	 * Determines how much money the company needs to build a new route,
	 * @return The minimum amount of money to build a new route.
	 */
	static function MinimumMoneyToBuild();
}

function Banker::GetMoney(money)
{
	return AICompany.SetMinimumLoanAmount(AICompany.GetLoanAmount() + money);
}

function Banker::GetMaxBankBalance()
{
	return MyAICompany.GetMyMaxBankBalance();
}

function Banker::SetMinimumBankBalance(money)
{
	local needed = money - MyAICompany.GetMyBankBalance();
	if (needed < 0) return true;
	else return Banker.GetMoney(needed);
}

function Banker::PayLoan()
{
	local balance = MyAICompany.GetMyBankBalance();
	// overflow protection by krinn
	if (balance + 1 < balance) return AICompany.SetMinimumLoanAmount(0);
	local money = 0 - (balance - AICompany.GetLoanAmount()) + Banker.GetMinimumCashNeeded();
	if (money > 0) return AICompany.SetMinimumLoanAmount(money);
	else return AICompany.SetMinimumLoanAmount(0);
}

function Banker::MinimumMoneyToUseAircraft()
{
	local cheapest = MyPlanes.ChoosePlane(MyAICargo.GetPassengersCargo(), false, 16384, true);
	if (cheapest == null) return -1;
	return Banker.InflatedValue(Banker.GetMinimumMoneyToUseAirRoute()) + AIEngine.GetPrice(cheapest);
}

function Banker::GetMinimumMoneyToUseAirRoute()
{
	if (AISettings.IsOldStyleAircraft())		return AISettings.MinimumMoneyToBuildOldStyleAirRoute();
	if (AISettings.IsModerateStyleAircraft())	return AISettings.MinimumMoneyToBuildModerateStyleAirRoute();
	if (AISettings.IsMediumStyleAircraft())		return AISettings.MinimumMoneyToBuildMediumStyleAirRoute();
	if (AISettings.IsAgressiveStyleAircraft())	return AISettings.MinimumMoneyToBuildAgressiveStyleAirRoute();
}

function Banker::GetMinimumCashNeeded()
{
	local stationlist = AIStationList(AIStation.STATION_ANY);
	return Banker.InflatedValue(stationlist.Count() * 400) + AICompany.GetLoanInterval();
}

function Banker::InflatedValue(amount)
{
	return (amount * MyAIGameSettings.GetInflationRate()).tointeger();
}

function Banker::MinimumMoneyToBuild()          {
	local stationlist = AIStationList(AIStation.STATION_ANY);
	local vehiclelist = AIVehicleList();
	local penalty = 0;
	if (stationlist.Count() > vehiclelist.Count()) penalty = (stationlist.Count() - vehiclelist.Count()) * 6000;
	return Banker.InflatedValue(40000 + penalty + 12500 * MyMath.Squared(AIGameSettings.GetValue("construction_cost")));
}

