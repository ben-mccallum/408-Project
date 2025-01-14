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
 * Define the MyAITileList_Passinglane class which extends the AITileList functions.
 */

class MyAITileList_Passinglane extends AITileList
{
	/**
	 * List of items into the tile list.
	 */
	PS_Entry = 0;
	PS_FrontEntry = 1;
	PS_BlockEntry = 2;
	PS_FrontBlockEntry = 3;
	PS_Exit = 4;
	PS_FrontExit = 5;
	PS_BlockExit = 6;
	PS_FrontBlockExit = 7;
	PS_Items = 8;

	/**
	 * The two lists
	 */
	_myidlist = null;
	_mytilelist = null;

	/**
	 * Removes all items of the lists..
	 */
	static function Clear();

	/**
	 * Returns The number of passing lanes.
	 * @return A Integer value.
	 */
	static function Count();

	/**
	 * Returns a tile that have this value.
	 * @param value The value to search from it.
	 * @return The tile that have a value.
	 */
	static function GetTileByValue(value);

	/**
	 * Returns a value to search into tile list.
	 * @param ps_id ID of passinglane to search.
	 * @param ps_item ID of item to search.
	 * @return an integer.
	 */
	static function GetItem(ps_id, ps_item);

	/**
	 * Get the entry tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetEntry(ps_id);

	/**
	 * Get the tile in front of the entry tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetFrontEntry(ps_id);

	/**
	 * Get the pair of entry and exit tiles from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The pair of tiles that have a value.
	 */
	static function GetEntryPair(ps_id);

	/**
	 * Get the blocked entry tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetBlockEntry(ps_id);

	/**
	 * Get the tile in front of the blocked entry tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetFrontBlockEntry(ps_id);

	/**
	 * Get the blocked entry pair of tiles from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The pair of tiles that have a value.
	 */
	static function GetBlockEntryPair(ps_id);

	/**
	 * Get the exit tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetExit(ps_id);

	/**
	 * Get the tile in front of the exit tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetFrontExit(ps_id);

	/**
	 * Get the pair of exit tiles from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The pair of tiles that have a value.
	 */
	static function GetExitPair(ps_id);

	/**
	 * Get the blocked exit tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetBlockExit(ps_id);

	/**
	 * Get the tile in front of the blocked exit tile from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetFrontBlockExit(ps_id);

	/**
	 * Get the pair of blocked tiles from a passing lane.
	 * @param ps_id ID of passinglane to search.
	 * @return The tile that have a value.
	 */
	static function GetBlockExitPair(ps_id);

	/**
	 * Add a new passing lane to list.
	 * @param ps_id ID of passing lane.
	 * @param ps_entry Entry tile of passing lane.
	 * @param ps_frontentry Tile in front of entry tile of passing lane.
	 * @param ps_blockentry Blocked entry tile of passing lane.
	 * @param ps_frontblockentry Tile in front of blocked entry tile of passing lane.
	 * @param ps_exit Exit tile of passing lane.
	 * @param ps_frontexit Tile in front of exit tile of passing lane.
	 * @param ps_blockexit Blocked exit tile of passing lane.
	 * @param ps_frontblockexit Tile in front of blocked exit tile of passing lane.
	 * @return The ID of this new passing lane.
	 */
	static function AddPassinglane(ps_id, ps_entry, ps_frontentry, ps_blockentry, ps_frontblockentry, ps_exit, ps_frontexit, ps_blockexit, ps_frontblockexit);

	/**
	 * Constructor: two lists are created.
	 */
	constructor()
	{
		this._myidlist = AIList();;
		this._mytilelist = AITileList();;
		::AITileList.constructor();
	}
}

function MyAITileList_Passinglane::Clear()
{
	this._myidlist.Clear();
	this._mytilelist.Clear();
}

function MyAITileList_Passinglane::Count()
{
	return this._myidlist.Count();
}

function MyAITileList_Passinglane::GetTileByValue(value)
{
	local templist = AITileList();
	templist.AddList(this._mytilelist);
	templist.KeepValue(value);
	if (templist.IsEmpty()) return null;
	return templist.Begin();
}

function MyAITileList_Passinglane::GetItem(ps_id, ps_item)
{
	return ps_id * MyAITileList_Passinglane.PS_Items + ps_item;
}

function MyAITileList_Passinglane::GetEntry(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_Entry));
}

function MyAITileList_Passinglane::GetFrontEntry(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_FrontEntry));
}

function MyAITileList_Passinglane::GetEntryPair(ps_id)
{
	return [this.GetEntry(ps_id), this.GetFrontEntry(ps_id)];
}

function MyAITileList_Passinglane::GetBlockEntry(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_BlockEntry));
}

function MyAITileList_Passinglane::GetFrontBlockEntry(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_FrontBlockEntry));
}

function MyAITileList_Passinglane::GetBlockEntryPair(ps_id)
{
	return [this.GetBlockEntry(ps_id), this.GetFrontBlockEntry(ps_id)];
}

function MyAITileList_Passinglane::GetExit(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_Exit));
}

function MyAITileList_Passinglane::GetFrontExit(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_FrontExit));
}

function MyAITileList_Passinglane::GetExitPair(ps_id)
{
	return [this.GetExit(ps_id), this.GetFrontExit(ps_id)];
}

function MyAITileList_Passinglane::GetBlockExit(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_BlockExit));
}

function MyAITileList_Passinglane::GetFrontBlockExit(ps_id)
{
	return this.GetTileByValue(MyAITileList_Passinglane.GetItem(ps_id, MyAITileList_Passinglane.PS_FrontBlockExit));
}

function MyAITileList_Passinglane::GetBlockExitPair(ps_id)
{
	return [this.GetBlockExit(ps_id), this.GetFrontBlockExit(ps_id)];
}

function MyAITileList_Passinglane::AddPassinglane(ps_id, ps_entry, ps_frontentry, ps_blockentry, ps_frontblockentry, ps_exit, ps_frontexit, ps_blockexit, ps_frontblockexit)
{
	if (ps_id == null || ps_entry == null || ps_frontentry == null || ps_exit == null || ps_frontexit == null) return null;
	local new_tile_id = ps_id * MyAITileList_Passinglane.PS_Items;
	this._myidlist.AddItem(ps_id, new_tile_id);
	this._mytilelist.AddItem(ps_entry, new_tile_id + MyAITileList_Passinglane.PS_Entry);
	this._mytilelist.AddItem(ps_frontentry, new_tile_id + MyAITileList_Passinglane.PS_FrontEntry);
	if (ps_blockentry != null) this._mytilelist.AddItem(ps_blockentry, new_tile_id + MyAITileList_Passinglane.PS_BlockEntry);
	if (ps_frontblockentry != null) this._mytilelist.AddItem(ps_frontblockentry, new_tile_id + MyAITileList_Passinglane.PS_FrontBlockEntry);
	this._mytilelist.AddItem(ps_exit, new_tile_id + MyAITileList_Passinglane.PS_Exit);
	this._mytilelist.AddItem(ps_frontexit, new_tile_id + MyAITileList_Passinglane.PS_FrontExit);
	if (ps_blockexit != null) this._mytilelist.AddItem(ps_blockexit, new_tile_id + MyAITileList_Passinglane.PS_BlockExit);
	if (ps_frontblockexit != null) this._mytilelist.AddItem(ps_frontblockexit, new_tile_id + MyAITileList_Passinglane.PS_FrontBlockExit);
	return true;
}
