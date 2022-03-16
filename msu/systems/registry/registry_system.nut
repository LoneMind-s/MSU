this.MSU.Class.RegistrySystem <- class extends this.MSU.Class.System
{
	Mods = null;
	constructor()
	{
		base.constructor(this.MSU.SystemID.Registry);
		this.Mods = {}
	}

	function addMod( _mod )
	{
		this.Mods[_mod.getID()] <- _mod;
		this.logInfo(format("MSU registered mod %s, version: %s", _mod.getName(), _mod.getVersionString()));
	}

	function registerMod( _mod )
	{
		if (_mod.getID() in this.Mods)
		{
			this.logError("Duplicate Mod ID for mod: " + _mod.getID());
			throw this.Exception.DuplicateKey;
		}
		else if (::mods_getRegisteredMod(_mod.getID()) == null && _mod.getID() != ::MSU.VanillaID)
		{
			this.logError("Register your mod using the same ID with mod_hooks before creating a ::MSU.Class.Mod");
			throw this.Exception.KeyNotFound;
		}

		this.addMod(_mod);
	}

	function formatVanillaVersionString( _vanillaVersion )
	{
		local versionArray = split(_vanillaVersion, ".");
		local preRelease = versionArray.pop();
		return versionArray.reduce(@(_a, _b) _a + "." + _b) + "-" +  preRelease;
	}

	function getVersionTable( _version )
	{
		local version = split(_version, "+");
		if (version.len() > 2)
		{
			throw this.Exception.NotSemanticVersion;
		}
		local metadata = version.len() == 2 ? version[1] : null;
		version = split(version[0], "-");

		if (version.len() > 2)
		{
			throw this.Exception.NotSemanticVersion;
		}

		local prerelease = version.len() == 2 ? version[1] : null;
		version = split(version[0], ".");

		if (version.len() > 3)
		{
			throw this.Exception.NotSemanticVersion;
		}
		else if (version.len() < 3)
		{
			version.extend(array(3 - version.len(), "0"))
		}

		try
		{
			for (local i = 0; i < version.len(); ++i)
			{
				if (!this.MSU.String.isInteger(version[i]))
				{
					throw this.Exception.NotSemanticVersion;
				}
				version[i] = version[i].tointeger();
			}
		}
		catch (error)
		{
			throw this.Exception.NotSemanticVersion;
		}

		local ret = {
			Metadata = null,
			PreRelease = null,
			Version = version
		}

		if (metadata != null)
		{
			ret.Metadata = split(metadata, ".");
		}

		if (prerelease != null)
		{
			ret.PreRelease = split(prerelease, ".");
		}

		return ret;
	}

	function compareModToVersion( _mod, _version )
	{
		switch (typeof _version)
		{
			case "string":
				return this.compareModVersions(_mod, this.getVersionTable(_version));
			case "instance":
				if (_version instanceof this.MSU.Class.Mod)
				{
					return this.compareModVersions(_mod, _version);
				}
			default:
				throw this.Exception.InvalidType;
		}
	}

	function compareModVersions( _mod1, _mod2 )
	{
		for (local i = 0; i < 3; ++i)
		{
			if (_mod1.Version[i] > _mod2.Version[i])
			{
				return -1;
			}
			else if (_mod1.Version[i] < _mod2.Version[i])
			{
				return 1;
			}
		}

		if (_mod1.PreRelease == null || _mod2.PreRelease == null)
		{
			if (_mod1.PreRelease == null && _mod2.PreRelease != null)
			{
				return -1;
			}
			if (_mod1.PreRelease != null && _mod2.PreRelease == null)
			{
				return 1;
			}
			return 0;
		}

		for (local i = 0; i < this.Math.min(_mod2.PreRelease.len(), _mod1.PreRelease.len()); ++i)
		{
			local isInt1 = this.MSU.String.isInteger(_mod1.PreRelease[i]);
			local isInt2 = this.MSU.String.isInteger(_mod2.PreRelease[i]);

			if (isInt1 || isInt2)
			{
				if (isInt1 && isInt2)
				{
					local int1 = _mod1.PreRelease[i].tointeger();
					local int2 = _mod2.PreRelease[i].tointeger();
					if (int1 < int2)
					{
						return 1;
					}
					else if (int1 > int2)
					{
						return -1;
					}
				}
				else
				{
					if (isInt1)
					{
						return 1;
					}
					else
					{
						return -1;
					}
				}
			}
			else
			{
				if (_mod1.PreRelease[i] > _mod2.PreRelease[i])
				{
					return -1;
				}
				else if (_mod1.PreRelease[i] < _mod2.PreRelease[i])
				{
					return 1;
				}
			}
		}

		if (_mod1.PreRelease.len() > _mod2.PreRelease.len())
		{
			return -1;
		}
		else if (_mod1.PreRelease.len() < _mod2.PreRelease.len())
		{
			return 1;
		}
		return 0;
	}
}
