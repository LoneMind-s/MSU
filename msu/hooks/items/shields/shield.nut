::mods_hookExactClass("items/shields/shield", function(o) {
	o.m.ShieldExpertDefenseMult <- 1.25;

	o.getMeleeDefense = function()
	{
		if (!::MSU.isNull(this.m.Container) && !::MSU.isNull(this.m.Container.getActor()) && this.m.Container.getActor().isAlive())
		{
			local shieldExpert = this.m.Container.getActor().getSkills().getSkillByID("perk.shield_expert");
			if (shieldExpert != null) return this.m.MeleeDefense * shieldExpert.m.ShieldDefenseMult;
		}

		return this.m.MeleeDefense;
	}

	o.getRangedDefense = function()
	{
		if (!::MSU.isNull(this.m.Container) && !::MSU.isNull(this.m.Container.getActor()) && this.m.Container.getActor().isAlive())
		{
			local shieldExpert = this.m.Container.getActor().getSkills().getSkillByID("perk.shield_expert");
			if (shieldExpert != null) return this.m.RangedDefense * shieldExpert.m.ShieldDefenseMult;
		}

		return this.m.RangedDefense;
	}
});
