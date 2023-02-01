::MSU.Class.TooltipsSystem <- class extends ::MSU.Class.System
{
	Mods = null;
	ImageKeywordMap = null;

	constructor()
	{
		base.constructor(::MSU.SystemID.Tooltips);
		this.Mods = {};
		this.ImageKeywordMap = {};
	}

	function registerMod( _mod )
	{
		base.registerMod(_mod);
		_mod.Tooltips = ::MSU.Class.TooltipsModAddon(_mod);
		this.Mods[_mod.getID()] <- {};
	}

	function setTooltips( _modID, _tooltipTable )
	{
		this.__addTable(this.Mods[_modID], _tooltipTable);
	}

	function __addTable( _currentTable, _tableToAdd )
	{
		foreach (key, value in _tableToAdd)
		{
			if (!(key in _currentTable) && typeof value == "table")
			{
				_currentTable[key] <- {};
				this.__addTable(_currentTable[key], value);
			}
			else
			{
				_currentTable[key] <- value;
			}
		}
	}

	function setTooltipImageKeywords(_modID, _tooltipTable)
	{
		local identifier, path;
		foreach (imagePath, id in _tooltipTable)
		{
			imagePath = "coui://gfx/" + imagePath;
			identifier = {mod = _modID, id = id};
			this.ImageKeywordMap[imagePath] <- identifier;
		}
	}

	function passTooltipIdentifiers()
	{
		::MSU.UI.JSConnection.passTooltipIdentifiers(this.ImageKeywordMap);
	}

	function getTooltip( _modID, _identifier )
	{
		local fullKey = split(_identifier, ".");
		local currentTable = this.Mods[_modID];
		for (local i = 0; i < fullKey.len(); ++i)
		{
			local currentKey = fullKey[i];
			if (currentKey in currentTable && currentTable[currentKey] instanceof ::MSU.Class.Tooltip)
			{
				local data = fullKey.slice(i+1).reduce( @(_a, _b) _a + "." + _b);
				return {
					Tooltip = currentTable[currentKey],
					Data = data
				}
			}
			currentTable = currentTable[fullKey[i]];
		}
		return {
			Tooltip = currentTable,
			Data = null
		}
	}
}
