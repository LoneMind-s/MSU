var MSU = {};
MSU.printData = function( _obj, _depth, _maxLen )
{
	if (_depth === undefined) _depth = 1;
	if (_maxLen === undefined) _maxLen = 0;
	var length = 1;
	var isArray = false;
	if (typeof _obj == "object" && _obj !== null)
	{
		if (Array.isArray(_obj))
		{
			isArray = true;
			length = _obj.length;
		}
		else
		{
			length = Object.keys(_obj).length;
		}
	}
	var string = MSU.getLocalString("Data: ", _obj, Math.max(length, _maxLen), _depth, isArray);
	for (var i = 0; i < string.length; i = i + 900)
	{
		console.error(string.slice(i, Math.min(i + 900, string.length)));
	}
};

MSU.getLocalString = function( _key, _value, _maxLen, _depth, _isArray )
{
	if (_isArray === undefined) _isArray = false;
	var string = "";

	if (!_isArray)
	{
		string += _key + " = ";
	}

	switch(typeof _value)
	{
		case "object":
			if (_value === null)
			{
				string += "null, ";
				break;
			}
			if (Array.isArray(_value))
			{
				if (_value.length > _maxLen || _depth <= 0)
				{
					string += "array, ";
					break;
				}

				string += '[';
				for (var i = 0; i < _value.length; i++)
				{
					string += MSU.getLocalString(i, _value[i], _maxLen, _depth - 1, true);
				}

				if (_value.length > 0)
				{
					string = string.slice(0, string.length - 2);
				}
				string += '], ';
			}
			else
			{
				var keys = Object.keys(_value);
				if (keys.length > _maxLen || _depth <= 0)
				{
					string += "object, ";
					break;
				}

				string += '{';
				for (var i = 0; i < keys.length; i++)
				{
					string += MSU.getLocalString(keys[i], _value[keys[i]], _maxLen, _depth - 1, false);
				}

				if (keys.length > 0)
				{
					string = string.slice(0, string.length - 2);
				}
				string += "}, ";
			}
			break;
		default:
			string += "(" + typeof _value + ") " + _value + ", ";
	}

	return string;
};

MSU.capitalizeFirst = function ( _string )
{
	return _string.charAt(0).toUpperCase() + _string.slice(1);
};