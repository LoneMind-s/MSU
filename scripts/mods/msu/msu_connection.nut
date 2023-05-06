this.msu_connection <- ::inherit("scripts/mods/msu/js_connection", {
	m = {},

	function connect()
	{
		this.m.JSHandle = ::UI.connect("MSUConnection", this);
		this.querySettingsData();
		this.checkForModUpdates();
	}

	function querySettingsData()
	{
		local data = {
			keybinds = ::MSU.System.Keybinds.getJSKeybinds(),
			settings = ::MSU.System.ModSettings.getUIData()
		};
		this.m.JSHandle.asyncCall("onQuerySettingsData", data);
	}

	function removeKeybind( _keybind )
	{
		if (this.m.JSHandle != null)
		{
			this.m.JSHandle.asyncCall("removeKeybind", _keybind.getUIData())
		}
	}

	function addKeybind( _keybind )
	{
		if (this.m.JSHandle != null)
		{
			this.m.JSHandle.asyncCall("addKeybind", _keybind.getUIData())
		}
	}

	function clearKeys()
	{
		this.m.JSHandle.asyncCall("clearKeys", null);
	}

	function checkForModUpdates()
	{
		this.m.JSHandle.asyncCall("checkForModUpdates", ::MSU.System.Registry.getModsForUpdateCheck());
	}

	function compareModVersions( _modVersionData )
	{
		return ::MSU.System.Registry.checkIfModVersionsAreNew(_modVersionData);
	}
});
