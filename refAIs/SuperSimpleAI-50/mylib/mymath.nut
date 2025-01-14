/**
 * Math functions used in SuperSimpleAI.
 *
 * Based on code from SuperLib, write by Leif Linse.
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

class MyMath
{
	/**
	 * Return the minium of two values.
	 * @param x1 first value.
	 * @param x2 second value.
	 * @return minium value.
	 */
	static function Min(x1, x2);

	/**
	 * Return the maximum of two values.
	 * @param x1 first value.
	 * @param x2 second value.
	 * @return maximum value.
	 */
	static function Max(x1, x2);

	/**
	 * Return a value between maximum and minimum values.
	 * @param x value.
	 * @param min minium value.
	 * @param max maximum value.
	 * @return value between maximum and minimum values.
	 */
	static function Clamp(x, min, max);

	/**
	 * Return the absolute value.
	 * @param a value.
	 * @return absolute value of a.
	 */
	static function Abs(a);

	/**
	 * Return the average of two values.
	 * @param a value.
	 * @param b value.
	 * @return average of a and b.
	 */
	static function Average(a, b);

	/**
	 * Return the squared value.
	 * @param n value.
	 * @return n * n.
	 */
	static function Squared(n);

	/**
	 * Return percent portion of a total value.
	 * @param p Portion value.
	 * @param t Total value.
	 * @return percentage of p to t.
	 */
	static function Percent(p, t);
}

function MyMath::Min(x1, x2)
{
	return x1 < x2 ? x1 : x2;
}

function MyMath::Max(x1, x2)
{
	return x1 > x2 ? x1 : x2;
}

function MyMath::Clamp(x, min, max)
{
	return MyMath.Min(MyMath.Max(x, min), max);
}

function MyMath::Abs(a)
{
	return a >= 0 ? a : -a;
}

function MyMath::Average(a, b)
{
	return ((a + b) / 2).tointeger();
}

function MyMath::Squared(n)
{
	return n * n;
}

function MyMath::Percent(p, t)
{
	return ((p * 100) / t).tointeger();
}
