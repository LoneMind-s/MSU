if (::MSU.Mod.ModSettings.getSetting("ExpandedSkillTooltips").getValue())
		{
			local colorize = function ( _value, _percentage = true )
			{
				return (_value < 0 ? "[color=" + this.Const.UI.Color.PositiveValue + "]" : "[color=" + this.Const.UI.Color.PositiveValue + "]") + _value + (_percentage ? "%" : "") + "[/color] ";
			}

			local user = this.getContainer().getActor();
			
			local currentProperties = user.getCurrentProperties();
			local useProperties = user.buildPropertiesForUse(this, _targetTile);
			local distanceToTarget = _targetTile.getDistanceTo(user.getTile());
			local targetEntity = _targetTile.getEntity();
			local targetProperties = targetEntity != null ? targetEntity.getCurrentProperties() : null;

			local badTerrainIdx = null;
			local targetBadTerrainIdx = null;

			local skillsWithChanges = {};
			local propertiesClone = user.getCurrentProperties().getClone();

			local addChanges <- function( _function )
			{
				foreach (skill in this.getContainer().m.Skills)
				{
					local skillBefore = this.isRanged() ? propertiesClone.RangedSkill : propertiesClone.MeleeSkill;
					local skillMultBefore = this.isRanged() ? propertiesClone.RangedSkillMult : propertiesClone.MeleeSkillMult;

					if (!skill.isGarbage()) 
					{
						if (_function == "onAnySkillUsed") skill[_function](this, _targetTile, propertiesClone);
						else skill[_function](propertiesClone);

						if (skill.m.IsTacticalHitFactors)
						{
							if (!(skill.getName() in skillsWithChanges)) skillsWithChanges[skill.getName()] <- { SkillChange = 0, MultChange = 0 };
							skillsWithChanges[skill.getName()].SkillChange += (this.isRanged() ? propertiesClone.RangedSkill : propertiesClone.MeleeSkill) - skillBefore;
							skillsWithChanges[skill.getName()].MultChange += (this.isRanged() ? propertiesClone.RangedSkillMult : propertiesClone.MeleeSkillMult) - skillMultBefore;
						}
					}
				}
			}

			addChanges("onUpdate");
			addChanges("onAfterUpdate");
			addChanges("onAnySkillUsed");

			foreach (skillName, skill in skillsWithChanges)
			{
				if (skill.SkillChange != 0)
				{
					toAppend.push({
						icon = skill.SkillChange > 0 ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
						text = colorize(skill.SkillChange) + skillName
					});
				}
				if (skill.MultChange != 0)
				{
					toAppend.push({
						icon = skill.MultChange > 0 ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
						text = colorize(skill.MultChange) + skillName
					});
				}
			}
			
			foreach (skill in this.getContainer().m.Skills)
			{
				local skillBefore = this.isRanged() ? propertiesClone.RangedSkill : propertiesClone.MeleeSkill;
				local skillMultBefore = this.isRanged() ? propertiesClone.RangedSkillMult : propertiesClone.MeleeSkillMult;

				if (!skill.isGarbage()) 
				{
					skill.onUpdate(propertiesClone);
					if (skill.m.IsTacticalHitFactors)
					{
						local change = (this.isRanged() ? propertiesClone.RangedSkill : propertiesClone.MeleeSkill) - skillBefore;
						local changeMult = (this.isRanged() ? propertiesClone.RangedSkillMult : propertiesClone.RangedSkillMult) - skillMultBefore;
						skillsWithChanges[skill.getName()] <- { SkillChange = change, MultChange = changeMult };
					}
				}
			}

			foreach (skill in this.getContainer().m.Skills)
			{
				local skillBefore = this.isRanged() ? propertiesClone.RangedSkill : propertiesClone.MeleeSkill;
				local skillMultBefore = this.isRanged() ? propertiesClone.RangedSkillMult : propertiesClone.MeleeSkillMult;

				if (!skill.isGarbage()) 
				{
					skill.onUpdate(propertiesClone);
					if (skill.m.IsTacticalHitFactors)
					{
						local change = (this.isRanged() ? propertiesClone.RangedSkill : propertiesClone.MeleeSkill) - skillBefore;
						local changeMult = (this.isRanged() ? propertiesClone.RangedSkillMult : propertiesClone.RangedSkillMult) - skillMultBefore;
						skillsWithChanges[skill.getName()] <- { SkillChange = change, MultChange = changeMult };
					}
				}
			}
			local skills = this.getContainer().getSkillsByFunction(this, @(skill) skill.m.IsTacticalHitFactors);
			foreach (skill in skills)
			{
				
				local skillMultBefore = this.isRanged() ? baseProperties.RangedSkillMult : baseProperties.MeleeSkillMult;

				skill.onUpdate(baseProperties);
				skill.onAfterUpdate(baseProperties);
				skill.onAnySkillUsed(this, _targetTile, baseProperties);

				local skillAfter = this.isRanged() ? baseProperties.RangedSkill : baseProperties.MeleeSkill;
				local skillMultAfter = this.isRanged() ? baseProperties.RangedSkillMult : baseProperties.MeleeSkillMult

				if (skillAfter != skillBefore)
				{
					toAppend.push({
						icon = skillAfter > skillBefore ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
						text = colorize(skillAfter - skillBefore) + skill.getName()
					});
				}
				if (skillMultAfter != skillMultBefore)
				{
					toAppend.push({
						icon = skillMultAfter > skillMultBefore ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
						text = colorize(skillMultAfter - skillMultBefore) + skill.getName()
					});
				}
			}

			local modifier = {};
			modifier[this.getName()] <- function( _entry ) {
				if (this.isRanged())
				{
					entry.icon = this.m.AdditionalAccuracy > 0 ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
					return this.m.AdditionalAccuracy;
				}
				else
				{
					entry.icon = this.m.HitChanceBonus > 0 ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
					return this.m.HitChanceBonus;
				}
			};
			modifier["Distance of " + distanceToTarget] <- function( _entry ) {
				return (distanceToTarget - thisSkill.m.MinRange) * useProperties.HitChanceAdditionalWithEachTile * propertiesWithSkill.HitChanceWithEachTileMult;
			};
			modifier["Line of fire blocked"] <- function( _entry ) {
				return ::Math.ceil(::Const.Combat.RangedAttackBlockedChance * useProperties.RangedAttackBlockedChanceMult * 100);
			};
			modifier["Surrounded"] <- function( _entry ) {
				return this.Math.max(0, currentProperties.SurroundedBonus * currentProperties.SurroundedBonusMult - targetProperties.SurroundedDefense) * targetEntity.getSurroundedCount();
			};
			modifier["Height advantage"] <- function( _entry ) {
				return ::Const.Combat.LevelDifferenceToHitBonus;
			};
			modifier["Height disadvantage"] <- function( _entry ) {
				return ::Const.Combat.LevelDifferenceToHitMalus * (user.getTile().Level - _targetTile.Level);
			};
			modifier["Fast adaptation"] <- function( _entry ) {
				return this.getContainer().getSkillByID("perk.fast_adaption").m.Stacks * 10;
			};
			modifier["Oath of wrath"] <- function( _entry ) {
				return 15;
			};
			modifier["Too close"] <- function( _entry ) {
				return 15;
			};

				if (info == "")
				{
					switch (entry.text)
					{
						case "Height advantage":
							info = ::Const.Combat.LevelDifferenceToHitBonus;
							break;

						case "Height disadvantage":
							info = ::Const.Combat.LevelDifferenceToHitMalus * (user.getTile().Level - _targetTile.Level);
							break;

						case "On bad terrain":
							badTerrainIdx = row;
							continue;

						case "Target on bad terrain":
							targetBadTerrainIdx = row;
							continue;

						case "Fast adaptation":

					}
				}

				entry.text = colorize(info) + "% " + entry.text;
			}

			local addBadTerrainInfo = function( _idx, _entity )
			{
				ret.remove(_idx);
				local terrainEffects = this.getContainer().getAllSkillsOfType(::Const.SkillType.Terrain);
				local iconToFind = this.isRanged() ? "ranged_skill" : "melee_skill";
				local iconToUse = _entity.getID() == user.getID() ? "ui/tooltips/negative.png" : "ui/tooltips/positive.png";
				foreach (effect in terrainEffects)
				{
					foreach (i, row in effect.getTooltip())
					{
						if (("icon" in row) && row.icon.find(iconToFind) != null)
						{
							ret.push({
								icon = iconToUse,
								text = row.text + "(" + effect.getName() + ")"
							});
						}
					}
				}
			}

			if (badTerrainIdx != null) addBadTerrainInfo(badTerrainIdx, user);
			if (targetBadTerrainIdx != null) addBadTerrainInfo(badTerrainIdx, targetEntity);
		}






::Const.ItemActionOrder <- {
	First = 0,
	Early = 1000,
	Any = 50000,
	BeforeLast = 60000
	Last = 70000,
	VeryLast = 80000
};

::Const.Damage <- {
	function addNewDamageType ( _damageType, _injuriesOnHead, _injuriesOnBody, _damageTypeName = "" )
	{
		if (_damageType in this.DamageType)
		{
			throw ::MSU.Exception.DuplicateKey(_damageType);
		}

		local n = 0;
		foreach (d in this.DamageType)
		{
			if (d > n)
			{
				n = d;
			}
		}

		this.DamageType[_damageType] <- n << 1;

		this.DamageTypeInjuries.push({
			DamageType = this.DamageType[_damageType],
			Injuries = {
				Head = _injuriesOnHead,
				Body = _injuriesOnBody
			}
		});

		if (_damageTypeName = "")
		{
			_damageTypeName = _damageType;
		}

		::Const.Damage.DamageTypeName.push(_damageTypeName);
	}

	function getDamageTypeName( _damageType )
	{
		local idx = ::MSU.Math.log2int(_damageType) + 1;
		if (idx == idx.tointeger() && idx < this.DamageTypeName.len())
		{
			return this.DamageTypeName[idx];
		}
		throw ::MSU.Exception.KeyNotFound(_damageType);
	}

	function getDamageTypeInjuries ( _damageType )
	{
		local idx = ::MSU.Math.log2int(_damageType) + 1;
		if (idx == idx.tointeger() && idx < this.DamageTypeInjuries.len())
		{
			return clone this.DamageTypeInjuries[idx].Injuries;
		}
		throw ::MSU.Exception.KeyNotFound(_damageType);
	}

	function setDamageTypeInjuries ( _damageType, _injuriesOnHead, _injuriesOnBody )
	{
		local injuries = this.getDamageTypeInjuries(_damageType);

		injuries.Injuries.Head = _injuriesOnHead;
		injuries.Injuries.Body = _injuriesOnBody;
	}

	function getApplicableInjuries ( _damageType, _bodyPart, _targetEntity = null )
	{
		local injuries = [];

		foreach (d in this.DamageType)
		{
			if (_damageType == d)
			{
				local inj = this.getDamageTypeInjuries(d);
				injuries = clone (_bodyPart == ::Const.BodyPart.Head ? inj.Head : inj.Body);
				break;
			}
		}

		if (_targetEntity != null && injuries.len() > 0)
		{
			foreach (injury in _targetEntity.m.ExcludedInjuries)
			{
				if (injuries.find(injury) != null)
				{
					injuries.remove(injury);
				}
			}
		}

		return injuries;
	}
};

::Const.Damage.DamageType <- {
		None = 0,
		Unknown = 1,
		Blunt = 2,
		Piercing = 3,
		Cutting = 4,
		Burning = 5
};

::Const.Damage.DamageTypeName <- [
	"No Damage Type",
	"Unknown",
	"Blunt",
	"Piercing",
	"Cutting",
	"Burning"
];

::Const.Damage.DamageTypeInjuries <- [
	{
		Head = [],
		Body = []
	},
	{
		Head = [],
		Body = []
	},
	{
		Head = ::Const.Injury.BluntHead,
		Body = ::Const.Injury.BluntBody
	},
	{
		Head = ::Const.Injury.PiercingHead,
		Body = ::Const.Injury.PiercingBody
	},
	{
		Head = ::Const.Injury.CuttingHead,
		Body = ::Const.Injury.CuttingBody
	},
	{
		Head = ::Const.Injury.BurningHead,
		Body = ::Const.Injury.BurningBody
	}
];
