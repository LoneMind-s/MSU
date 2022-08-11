::MSU.Class.SerializationSystem <- class extends ::MSU.Class.System
{
	Mods = null;
	FlagsToClear = null;
	SerializeFunctions = null;
	DeserializeFunctions = null;

	constructor()
	{
		base.constructor(::MSU.SystemID.Serialization);
		this.Mods = [];
		this.FlagsToClear = [];
		this.SerializeFunctions = [];
		this.DeserializeFunctions = [];
	}

	function registerMod( _mod )
	{
		base.registerMod(_mod);
		this.Mods.push(_mod);
		_mod.Serialization = ::MSU.Class.SerializationModAddon(_mod);
	}

	function flagSerialize( _mod, _id, _object, _flags = null )
	{
		if (_flags == null) _flags = ::World.Flags;
		local outEmulator = ::MSU.Class.SerializationEmulator(_mod, _id);
		if (::MSU.isBBObject(_object))
		{
			_object.onSerialize(outEmulator);
		}
		else
		{
			::MSU.Utils.serialize(_object, outEmulator);
		}
		outEmulator.storeDataInFlagContainer(_flags);
		this.FlagsToClear.push([outEmulator.getEmulatorString(), _flags]);
	}

	function flagDeserialize( _mod, _id, _object = null, _flags = null )
	{
		if (_flags == null) _flags = ::World.Flags;
		local inEmulator = ::MSU.Class.DeserializationEmulator(_mod, _id);
		inEmulator.loadDataFromFlagContainer(_flags);
		this.FlagsToClear.push([inEmulator.getEmulatorString(), _flags]);
		if (::MSU.isBBObject(_object))
		{
			_object.onDeserialize(inEmulator);
			return null; // yes ik this is unnecessary but looks better imo
		}
		else
		{
			return ::MSU.Utils.deserialize(inEmulator, _object);
		}
	}

	function registerSerializeFunction(_function)
	{
		::MSU.requireFunction(_function);
		this.SerializeFunctions.push(_function);
	}

	function registerDeserializeFunction(_function)
	{
		::MSU.requireFunction(_function);
		this.DeserializeFunctions.push(_function);
	}

	function clearFlags()
	{
		foreach (flagPair in this.FlagsToClear)
		{
			if (flagPair[1].has(flagPair[0]))
			{
				for (local i = 0; i < flagPair[1].get(flagPair[0]); ++i)
				{
					flagPair[1].remove(flagPair[0] + "." + i);
				}
				flagPair[1].remove(flagPair[0]);
			}
		}
		this.FlagsToClear.clear();
	}
}
