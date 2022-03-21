::MSU.Class.RangeSetting <- class extends ::MSU.Class.AbstractSetting
{
	Min = null;
	Max = null;
	Step = null;
	static Type = "Range";

	constructor( _id, _value, _min, _max, _step, _name = null )
	{
		::MSU.requireOneFromTypes(["integer", "float"], _min, _max, _step);
		base.constructor(_id, _value, _name);

		this.Min = _min;
		this.Max = _max;
		this.Step = _step;
	}

	function getMin()
	{
		return this.Min;
	}

	function getMax()
	{
		return this.Max;
	}

	function getStep()
	{
		return this.Step;
	}

	function getUIData()
	{
		local ret = base.getUIData();
		ret.min <- this.getMin();
		ret.max <- this.getMax();
		ret.step <- this.getStep();
		return ret;
	}

	function tostring()
	{
		return base.tostring() + " | Min: " + this.getMin() + " | Max: " + this.getMax() + " | Step: " + this.getStep();
	}
}
