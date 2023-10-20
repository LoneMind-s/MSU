::mods_hookExactClass("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o) {
	o.isActiveEntity <- function( _entity )
	{
		local activeEntity = this.getActiveEntity();
		return activeEntity != null && activeEntity.getID() == _entity.getID();
	}

	local setActiveEntityCostsPreview = o.setActiveEntityCostsPreview;
	o.setActiveEntityCostsPreview = function( _costsPreview )
	{
		if (::MSU.Mod.ModSettings.getSetting("ExpandedSkillTooltips").getValue())
		{
			local activeEntity = this.getActiveEntity();
			if (activeEntity != null)
			{
				local skillID = "SkillID" in _costsPreview ? _costsPreview.SkillID : "";
				local skill;
				local movementTile;
				if (skillID == "")
				{
					local movement = ::Tactical.getNavigator().getCostForPath(activeEntity, ::Tactical.getNavigator().getLastSettings(), activeEntity.getActionPoints(), activeEntity.getFatigueMax() - activeEntity.getFatigue());
					movementTile = movement.End;
				}
				else skill = activeEntity.getSkills().getSkillByID(skillID);

				activeEntity.getSkills().m.IsPreviewing = true;
				activeEntity.getSkills().onAffordablePreview(skill, movementTile);
			}
		}

		local table = {
			__JSHandle = this.m.JSHandle;
			function asyncCall( _funcName, ... )
			{
				if (_funcName == "updateCostsPreview")
					return;

				vargv.insert(0, _funcName);
				vargv.insert(0, this);
				this.__JSHandle.asyncCall.acall(vargv);
			}
		}
		table.setdelegate({
			function _get( _key )
			{
				if (_key in this.__JSHandle) return this.__JSHandle[_key];
				throw null;
			}
		});
		this.m.JSHandle = table;
		setActiveEntityCostsPreview(_costsPreview);
		this.m.JSHandle = table.__JSHandle;
		this.m.JSHandle.asyncCall("updateCostsPreview", this.m.ActiveEntityCostsPreview);
	}

	local resetActiveEntityCostsPreview = o.resetActiveEntityCostsPreview;
	o.resetActiveEntityCostsPreview = function()
	{
		local activeEntity = this.getActiveEntity();
		if (activeEntity != null) activeEntity.getSkills().m.IsPreviewing = false;
		resetActiveEntityCostsPreview();
	}
});
