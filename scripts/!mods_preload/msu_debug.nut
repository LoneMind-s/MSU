local gt = this.getroottable();

gt.MSU.setupDebuggingUtils <- function()
{

	this.MSU.Class.DebugSystem <- class extends this.MSU.Class.System
	{
		ModTable = null;
		LogType = null;
		FullDebug = null;
		DefaultFlag = null;
		VanillaLogName = null;
		MSUMainDebugFlag = null;
		MSUDebugFlags = null;

		constructor()
		{
			base.constructor(this.MSU.SystemIDs.Debug, [this.MSU.SystemIDs.ModRegistry]);
			this.ModTable = {};
			this.LogType = {
				Info = 1,
				Warning = 2,
				Error = 3
			};
			this.FullDebug = false;
			this.DefaultFlag = "default";
			this.VanillaLogName = "vanilla";

			this.MSUMainDebugFlag = {
				debug = true
			}
			this.MSUDebugFlags = {
				movement = true,
				skills = false,
				keybinds = false,
				persistence = true
			}
		}

		function registerMod( _modID, _defaultFlagBool = false, _flagTable = null, _flagTableBool = null )
		{
			base.registerMod(_modID);
			if (_modID in this.ModTable)
			{
				this.logError(format("Mod %s already exists in the debug log table!"), _modID);
				throw this.Exception.DuplicateKey;
			}

			this.ModTable[_modID] <- {};
			this.setFlag(_modID, this.DefaultFlag, _defaultFlagBool);

			if (_flagTable != null)
			{
				this.setFlags(_modID, _flagTable, _flagTableBool);
			}
		}

		function setFlags(_modID, _flagTable, _flagTableBool = null)
		{
			foreach(flagID, flagBool in _flagTable)
			{
				this.setFlag(_modID, flagID, _flagTableBool != null ? _flagTableBool : flagBool);
			}
		}

		function setFlag(_modID, _flagID, _flagBool)
		{
			if (!(_modID in this.ModTable))
			{
				::printWarning(format("Mod '%s' does not exist in the debug log table! Please initialise using registerMod().", _modID), this.MSU.MSUModName);
				return;
			}
			this.ModTable[_modID][_flagID] <- _flagBool;
			if (_flagBool == true)
			{
				if (_modID == this.MSU.MSUModName && _flagID == this.DefaultFlag)
				{
					this.logInfo(format("Debug flag '%s' set to true for mod '%s'.", _flagID, _modID));
				}
				else
				{
					if (this.isEnabledForMod(this.MSU.MSUModName, "debug")){
						::printWarning(format("Debug flag '%s' set to true for mod '%s'.", _flagID, _modID), this.MSU.MSUModName, "debug");
					}
				}
			}
		}

		function isEnabledForMod( _modID, _flagID = "default")
		{
			if (!(_modID in this.ModTable))
			{
				//circumvent infinite loop if MSU flag is somehow missing
				if (("debug" in this.ModTable[this.MSU.MSUModName] && this.ModTable[this.MSU.MSUModName]["debug" ] == true)  || this.isFullDebug()){
					::printWarning(format("Mod '%s' not found in debug table!", _modID), this.MSU.MSUModName, "debug");
				}
				return false;
			}
			if (!(_flagID in this.ModTable[_modID]))
			{
				//circumvent infinite loop if MSU flag is somehow missing
				if (("debug" in this.ModTable[this.MSU.MSUModName] && this.ModTable[this.MSU.MSUModName]["debug" ] == true)  || this.isFullDebug()){
					::printWarning(format("Flag '%s' not found in mod '%s'! ", _flagID, _modID), this.MSU.MSUModName, "debug");
				}
				return false;
			}

			return (this.ModTable[_modID][_flagID] == true) || this.isFullDebug();
		}

		function isFullDebug()
		{
			return this.FullDebug;
		}

		function setFullDebug(_bool)
		{
			this.FullDebug = _bool;
		}

		// maxLen is the maximum length of an array/table whose elements will be displayed
		// maxDepth is the maximum depth at which arrays/tables elements will be displayed
		// advanced allows the ID of the object to be displayed to identify different/identical objects
		function printStackTrace( _maxDepth = 0, _maxLen = 10, _advanced = false )
		{
			local count = 2;
			local string = "";
			while (getstackinfos(count) != null)
			{
				local line = getstackinfos(count++);
				string += "Function:\t\t";

				if (line.func != "unknown")
				{
					string += line.func + " ";
				}

				string += "-> " + line.src + " : " + line.line + "\nVariables:\t\t";

				foreach (key, value in line.locals)
				{
					string += this.getLocalString(key, value, _maxLen, _maxDepth, _advanced);
				}
				string = string.slice(0, string.len() - 2);
				string += "\n";
			}
			this.logInfo(string);
		}

		function printData(_data, _maxDepth = 1, _advanced = false){
			local maxLen = 1;
			if(typeof _data == "array" || typeof _data == "table"){
				maxLen = _data.len();
			}
			return this.getLocalString("Printing Data", _data, maxLen, _maxDepth, _advanced)
		}

		function getLocalString( _key, _value, _maxLen, _depth, _advanced, _isArray = false )
		{
			local string = "";

			if (_key == "this" || _key == "_release_hook_DO_NOT_delete_it_")
			{
				return string;
			}

			if (!_isArray)
			{
				string += _key + " = ";
			}
			local arrayVsTable = ["{", false, "}"];
			switch (typeof _value)
			{
				case "array":
					arrayVsTable = ["[", true, "]"]
				case "table":
					if (_value.len() <= _maxLen && _depth > 0)
					{
						string += arrayVsTable[0];
						foreach (key2, value2 in _value)
						{
							string += this.getLocalString(key2, value2, _maxLen, _depth - 1, _advanced, arrayVsTable[1]);
						}
						string = string.slice(0, string.len() - 2) + arrayVsTable[2] + ", ";
						break;
					}
				case "function":
				case "instance":
				case "null":
					if (!_advanced)
					{
						string += this.MSU.String.capitalizeFirst(typeof _value) + ", ";
						break;
					}
				default:
					string += _value + ", ";
			}
			return string;
		}

		function print( _printText, _modID, _logType, _flagID = "default")
		{
			if (!(_modID in this.ModTable))
			{
				if (this.isEnabledForMod(this.MSU.MSUModName, "debug")){
					this.printWarning(format("Mod '%s' not registered in debug logging! Call this.registerMod().", _modID), this.MSU.MSUModName, "debug");
				}
				return;
			}

			if (this.isEnabledForMod(_modID, _flagID))
			{
				local src = getstackinfos(3).src.slice(0, -4);
				src = split(src, "/")[split(src, "/").len()-1] + ".nut";
				local string = format("%s::%s -- %s -- %s", _modID, _flagID, src, _printText);
				switch (_logType)
				{
					case this.LogType.Info:
						this.logInfo(string);
						return;
					case this.LogType.Warning:
						this.logWarning(string);
						return;
					case this.LogType.Error:
						this.logError(string);
						return;
					default:
						this.printWarning("No log type defined for this log:", this.MSU.MSUModName, "debug");
						this.logInfo(string);
						return;
				}
			}
		}
	}

	this.MSU.Systems.Debug <- this.MSU.Class.DebugSystem();

	::printLog <- function( _arg, _modID, _flagID = this.MSU.Systems.Debug.DefaultFlag)
	{
		this.MSU.Systems.Debug.print(_arg, _modID, this.MSU.Systems.Debug.LogType.Info, _flagID);
	}

	::printWarning <- function( _arg,  _modID, _flagID = this.MSU.Systems.Debug.DefaultFlag)
	{
		this.MSU.Systems.Debug.print(_arg, _modID, this.MSU.Systems.Debug.LogType.Warning, _flagID);
	}

	::printError <- function( _arg,  _modID, _flagID = this.MSU.Systems.Debug.DefaultFlag)
	{
		this.MSU.Systems.Debug.print(_arg, _modID, this.MSU.Systems.Debug.LogType.Error, _flagID);
	}

	::isDebugEnabled <- function(_modID, _flagID = this.MSU.Systems.Debug.DefaultFlag){
		return this.MSU.Systems.Debug.isEnabledForMod( _modID, _flagID)
	}

	this.MSU.Systems.Debug.registerMod(this.MSU.MSUModName, true);

	//need to set this first to print the others
	this.MSU.Systems.Debug.setFlags(this.MSU.MSUModName, this.MSU.Systems.Debug.MSUMainDebugFlag);

	this.MSU.Systems.Debug.setFlags(this.MSU.MSUModName, this.MSU.Systems.Debug.MSUDebugFlags);

	this.MSU.Systems.Debug.registerMod(this.MSU.Systems.Debug.VanillaLogName, true);
}
