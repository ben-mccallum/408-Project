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
 * Define the MyAICompany class which extends the AICompany functions.
 */
class MyAICompany /* extends AICompany */
{
	/**
	 * Gets my bank balance.
	 * @return bank balance.
	 */
	static function GetMyBankBalance();

	/**
	* Calculates how much cash will be on hand if the maximum loan is taken.
	* This function was written by Brumi for SimpleAI.
	* @param The company Id.
	* @return The maximum amount of money.
	*/
	static function GetMaxBankBalance(company);

	/**
	 * Gets my maximum bank balance.
	 * @return bank balance.
	 */
	static function GetMyMaxBankBalance();

	/**
	 * Gets my company's name.
	 * @return bank balance..
	 */
	static function GetMyName();

	/**
	 * Gets my president name.
	 * @return bank balance..
	 */
	static function GetMyPresidentName();

	/**
	 * Gets my company's name.
	 * @return bank balance..
	 */
	static function GetMyCompanyHQ();
}

function MyAICompany::GetMyBankBalance()
{
	return AICompany.GetBankBalance(AICompany.COMPANY_SELF);
}

function MyAICompany::GetMaxBankBalance(company)
{
	local balance = AICompany.GetBankBalance(company);
	local maxbalance = balance + AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount();
	// overflow protection by krinn
	return MyMath.Max(maxbalance, balance);
}

function MyAICompany::GetMyMaxBankBalance()
{
	return MyAICompany.GetMaxBankBalance(AICompany.COMPANY_SELF);
}

function MyAICompany::GetMyName()
{
	return AICompany.GetName(AICompany.COMPANY_SELF);
}

function MyAICompany::GetMyPresidentName()
{
	return AICompany.GetPresidentName(AICompany.COMPANY_SELF);
}

function MyAICompany::GetMyCompanyHQ()
{
	return AICompany.GetCompanyHQ(AICompany.COMPANY_SELF);
}

