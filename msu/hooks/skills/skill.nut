::mods_hookDescendants("skills/skill", function(o) {
	if ("create" in o)
	{
		local create = o.create;
		o.create = function()
		{
			create();
			if (this.m.IsAttack && this.m.DamageType.len() == 0)
			{
				switch (this.m.InjuriesOnBody)
				{
					case null:
						this.m.DamageType.add(::Const.Damage.DamageType.None);
						break;

					case ::Const.Injury.BluntBody:
						this.m.DamageType.add(::Const.Damage.DamageType.Blunt);
						break;

					case ::Const.Injury.PiercingBody:
						this.m.DamageType.add(::Const.Damage.DamageType.Piercing);
						break;

					case ::Const.Injury.CuttingBody:
						this.m.DamageType.add(::Const.Damage.DamageType.Cutting);
						break;

					case ::Const.Injury.BurningBody:
						this.m.DamageType.add(::Const.Damage.DamageType.Burning);
						break;

					case ::Const.Injury.BluntAndPiercingBody:
						this.m.DamageType.add(::Const.Damage.DamageType.Blunt, 55);
						this.m.DamageType.add(::Const.Damage.DamageType.Piercing, 45);
						break;

					case ::Const.Injury.BurningAndPiercingBody:
						this.m.DamageType.add(::Const.Damage.DamageType.Burning, 25);
						this.m.DamageType.add(::Const.Damage.DamageType.Piercing, 75);
						break;

					case ::Const.Injury.CuttingAndPiercingBody:
						this.m.DamageType.add(::Const.Damage.DamageType.Cutting);
						this.m.DamageType.add(::Const.Damage.DamageType.Piercing);
						break;

					default:
						this.m.DamageType.add(::Const.Damage.DamageType.Unknown);
				}
			}
		}
	}
});

::mods_hookBaseClass("skills/skill", function(o) {
	o = o[o.SuperName];

	o.m.DamageType <- ::MSU.Class.WeightedContainer();
	o.m.ItemActionOrder <- ::Const.ItemActionOrder.Any;

	o.m.IsBaseValuesSaved <- false;
	o.m.ScheduledChanges <- [];

	o.m.IsApplyingPreview <- false;
	o.PreviewField <- {};

	o.scheduleChange <- function( _field, _change, _set = false )
	{
		this.m.ScheduledChanges.push({Field = _field, Change = _change, Set = _set});
		this.getContainer().m.ScheduledChangesSkills.push(this);
	}

	o.executeScheduledChanges <- function()
	{
		if (this.m.ScheduledChanges.len() == 0)
		{
			return;
		}

		foreach (c in this.m.ScheduledChanges)
		{
			switch (typeof c.Change)
			{
				case "integer":
				case "string":
					if (c.Set) this.m[c.Field] = c.Change;
					else this.m[c.Field] += c.Change;
					break;

				default:
					this.m[c.Field] = c.Change;
					break;
			}
		}

		this.m.ScheduledChanges.clear();
	}

	o.saveBaseValues <- function()
	{
		if (!this.m.IsBaseValuesSaved)
		{
			this.b <- clone this.skill.m;
			local obj = this;
			local tables = [];
			while (obj.ClassName != "skill")
			{
				tables.push(clone obj.m);
				obj = obj[obj.SuperName];
			}

			// Iterate in reverse so that the values of slots with the same name in a parent
			// are always taken from the bottom most child.
			for (local i = tables.len() - 1; i >= 0; i--)
			{
				foreach (key, value in tables[i])
				{
					this.b[key] <- value;
				}
			}

			this.m.IsBaseValuesSaved = true;
		}
	}

	o.getBaseValue <- function( _field )
	{
		return this.b[_field];
	}

	o.setBaseValue <- function( _field, _value )
	{
		if (this.m.IsBaseValuesSaved) this.b[_field] = _value;
	}

	o.softReset <- function()
	{
		if (!this.m.IsBaseValuesSaved)
		{
			::logWarning("MSU Mod softReset() skill \"" + this.getID() + "\" does not have base values saved.");
			::MSU.Log.printStackTrace();
			return false;
		}

		foreach (fieldName in ::MSU.Skills.SoftResetFields)
		{
			this.m[fieldName] = this.b[fieldName]
		}

		return true;
	}

	o.hardReset <- function( _exclude = null )
	{
		if (!this.m.IsBaseValuesSaved)
		{
			::logWarning("MSU Mod hardReset() skill \"" + this.getID() + "\" does not have base values saved.");
			::MSU.Log.printStackTrace();
			return false;
		}

		if (_exclude == null) _exclude = [];
		::MSU.requireArray(_exclude);

		local toExclude = ["IsNew", "Order", "Type"];
		toExclude.extend(_exclude);

		foreach (k, v in this.b)
		{
			if (toExclude.find(k) == null) this.m[k] = v;
		}

		return true;
	}

	o.resetField <- function( _field )
	{
		if (!this.m.IsBaseValuesSaved)
		{
			::logWarning("MSU Mod resetField(\"" + _field + "\") skill \"" + this.getID() + "\" does not have base values saved.");
			::MSU.Log.printStackTrace();
			return false;
		}

		this.m[_field] = this.b[_field];

		return true;
	}

	local setContainer = o.setContainer;
	o.setContainer = function( _c )
	{
		if (_c != null)
		{
			this.saveBaseValues();
		}

		setContainer(_c);
	}

	local setFatigueCost = o.setFatigueCost;
	o.setFatigueCost = function( _f )
	{
		this.setBaseValue("FatigueCost", _f);
		setFatigueCost(_f);
	}

	o.onMovementStarted <- function( _tile, _numTiles )
	{
	}

	o.onMovementFinished <- function( _tile )
	{
	}

	o.onMovementStep <- function( _tile, _levelDifference )
	{
	}

	o.onAfterDamageReceived <- function()
	{
	}

	o.onAnySkillExecuted <- function( _skill, _targetTile, _targetEntity, _forFree )
	{
	}

	o.onBeforeAnySkillExecuted <- function( _skill, _targetTile, _targetEntity, _forFree )
	{
	}

	o.onUpdateLevel <- function()
	{
	}

	o.getItemActionCost <- function( _items )
	{
	}

	o.getItemActionOrder <- function()
	{
		return this.m.ItemActionOrder;
	}

	o.onPayForItemAction <- function( _skill, _items )
	{
	}

	o.onNewMorning <- function()
	{
	}

	o.onGetHitFactors <- function( _skill, _targetTile, _tooltip ) 
	{
	}

	o.onQueryTooltip <- function( _skill, _tooltip )
	{
	}

	o.onDeathWithInfo <- function( _killer, _skill, _deathTile, _corpseTile, _fatalityType )
	{
	}

	o.onOtherActorDeath <- function( _killer, _victim, _skill, _deathTile, _corpseTile, _fatalityType )
	{			
	}

	o.onEnterSettlement <- function( _settlement )
	{		
	}

	o.onEquip <- function( _item )
	{
	}

	o.onUnequip <- function( _item )
	{
	}

	o.onBeforeGettingHit <- function( _attacker, _skill, _hitinfo )
	{
	}

	o.onGettingHit <- function( _attacker, _skill, _hitinfo )
	{
	}

	o.onAffordablePreview <- function( _skill, _movementTile )
	{
	}

	o.modifyPreviewField <- function( _skill, _field, _newChange, _multiplicative )
	{
		::MSU.Skills.modifyPreview(this, _skill, _field, _newChange, _multiplicative);
	}

	o.modifyPreviewProperty <- function( _skill, _field, _newChange, _multiplicative )
	{
		::MSU.Skills.modifyPreview(this, null, _field, _newChange, _multiplicative);
	}

	local use = o.use;
	o.use = function( _targetTile, _forFree = false )
	{
		// Save the container as a local variable because some skills delete
		// themselves during use (e.g. Reload Bolt) causing this.m.Container
		// to point to null.
		local container = this.m.Container;
		local targetEntity = _targetTile.IsOccupiedByActor ? _targetTile.getEntity() : null;

		container.onBeforeAnySkillExecuted(this, _targetTile, targetEntity, _forFree);

		local ret = use(_targetTile, _forFree);

		container.onAnySkillExecuted(this, _targetTile, targetEntity, _forFree);

		return ret;
	}

	o.getDamageType <- function()
	{
		return this.m.DamageType;
	}

	o.getWeightedRandomDamageType <- function()
	{
		return this.m.DamageType.roll();
	}

	o.verifyTargetAndRange <- function( _targetTile, _origin = null )
	{
		if (_origin == null)
		{
			_origin = this.getContainer().getActor().getTile();	
		}
		
		return this.onVerifyTarget(_origin, _targetTile) && this.isInRange(_targetTile, _origin);
	}

	local getDescription = o.getDescription;
	o.getDescription = function()
	{
		if (this.m.DamageType.len() == 0 || !::MSU.Mod.ModSettings.getSetting("ExpandedSkillTooltips").getValue())
		{
			return getDescription();
		}

		local ret = "[color=" + ::Const.UI.Color.NegativeValue + "]Inflicts ";

		foreach (d in this.m.DamageType.toArray())
		{
			local probability = ::Math.round(this.m.DamageType.getProbability(d) * 100);

			if (probability < 100)
			{
				ret += probability + "% ";
			}

			ret += ::Const.Damage.getDamageTypeName(d) + ", ";
		}

		ret = ret.slice(0, -2);

		ret += " Damage [/color]\n\n" + getDescription();

		return ret;
	}

	local getHitFactors = o.getHitFactors;
	o.getHitFactors = function( _targetTile )
	{
		local ret = getHitFactors(_targetTile);
		if (::MSU.Mod.ModSettings.getSetting("ExpandedSkillTooltips").getValue() && ::MSU.isIn("AdditionalAccuracy", this.m, true) && this.m.AdditionalAccuracy != 0)
		{
			local payload = {
				icon = this.m.AdditionalAccuracy > 0 ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
				text = this.getName()
			};

			if (this.m.AdditionalAccuracy > 0) ret.insert(0, payload);
			else ret.push(payload);
		}
		this.getContainer().onGetHitFactors(this, _targetTile, ret);
		return ret;
	}

	o.getRangedTooltip <- function( _tooltip = null )
	{
		if (_tooltip == null) _tooltip = [];
		
		local rangeBonus = ", more";
		if (this.m.MaxRangeBonus == 0)
		{
			rangeBonus = " or"
		}
		else if (this.m.MaxRangeBonus < 0)
		{
			rangeBonus = ", less"
		}

		_tooltip.push({
			id = 6,
			type = "text",
			icon = "ui/icons/vision.png",
			text = "Has a range of [color=" + ::Const.UI.Color.PositiveValue + "]" + this.getMaxRange() + "[/color] tiles on even ground" + rangeBonus + " if shooting downhill"
		});

		local accuText = "";
		if (this.m.AdditionalAccuracy != 0)
		{
			local color = this.m.AdditionalAccuracy > 0 ? ::Const.UI.Color.PositiveValue : ::Const.UI.Color.NegativeValue;
			local sign = this.m.AdditionalAccuracy > 0 ? "+" : "";
			accuText = "Has [color=" + color + "]" + sign + this.m.AdditionalAccuracy + "%[/color] chance to hit";
		}

		if (this.m.AdditionalHitChance != 0)
		{
			accuText += this.m.AdditionalAccuracy == 0 ? "Has" : ", and";
			local additionalHitChance = this.m.AdditionalHitChance + this.getContainer().getActor().getCurrentProperties().HitChanceAdditionalWithEachTile;
			local sign = additionalHitChance > 0 ? "+" : "";
			accuText += " [color=" + (additionalHitChance > 0 ? ::Const.UI.Color.PositiveValue : ::Const.UI.Color.NegativeValue) + "]" + sign + additionalHitChance + "%[/color]";
			accuText += this.m.AdditionalAccuracy == 0 ? " chance to hit " : "";
			accuText += " per tile of distance";
		}

		if (accuText.len() != 0)
		{
			_tooltip.push({
				id = 7,
				type = "text",
				icon = "ui/icons/hitchance.png",
				text = accuText
			});
		}

		return _tooltip;
	}

	function getShieldRelevantHitchanceBonus( _skill, _targetEntity )
	{
		if (_skill.m.IsShieldRelevant) return 0;

		local ret = 0;

		local shield = _targetEntity.getItems().getItemAtSlot(::Const.ItemSlot.Offhand);

		if (shield != null && shield.isItemType(::Const.Items.ItemType.Shield))
		{
			ret += this.m.IsRanged ? shield.getRangedDefense() : shield.getMeleeDefense();

			if (!this.m.IsShieldwallRelevant && _targetEntity.getSkills().hasSkill("effects.shieldwall"))
			{
				ret += shieldBonus;
			}
		}

		return ret;
	}

	function getHitchance( _targetEntity, _allowDiversion = null, _attackerProperties = null, _defenderProperties = null )
	{
		if (!_targetEntity.isAttackable())
		{
			return 0;
		}

		local user = this.m.Container.getActor();
		if (_attackerProperties == null) _attackerProperties = this.m.Container.buildPropertiesForUse(this, _targetEntity);

		if (!this.isUsingHitchance())
		{
			return 100;
		}

		if (_allowDiversion == null) _allowDiversion = this.m.IsRanged && this.m.MaxRangeBonus > 1;
		if (_defenderProperties == null) _defenderProperties = _targetEntity.getSkills().buildPropertiesForDefense(user, this);
		local skill = this.m.IsRanged ? _attackerProperties.getRangedSkill() : _attackerProperties.getMeleeSkill();
		local defense = _targetEntity.getDefense(user, this, _defenderProperties);
		local levelDifference = _targetEntity.getTile().Level - user.getTile().Level;
		local distanceToTarget = user.getTile().getDistanceTo(_targetEntity.getTile());
		local toHit = skill - defense;

		if (this.m.IsRanged)
		{
			toHit = toHit + (distanceToTarget - this.m.MinRange) * _attackerProperties.HitChanceAdditionalWithEachTile * _attackerProperties.HitChanceWithEachTileMult;
		}

		if (levelDifference < 0)
		{
			toHit = toHit + ::Const.Combat.LevelDifferenceToHitBonus;
		}
		else
		{
			toHit = toHit + ::Const.Combat.LevelDifferenceToHitMalus * levelDifference;
		}

		toHit += this.getShieldRelevantHitchanceBonus(this, _targetEntity);

		toHit = toHit * _attackerProperties.TotalAttackToHitMult;
		toHit = toHit + this.Math.max(0, 100 - toHit) * (1.0 - _defenderProperties.TotalDefenseToHitMult);
		local userTile = user.getTile();

		if (_allowDiversion && this.m.IsRanged && userTile.getDistanceTo(_targetEntity.getTile()) > 1)
		{
			local blockedTiles = ::Const.Tactical.Common.getBlockedTiles(userTile, _targetEntity.getTile(), user.getFaction(), true);

			if (blockedTiles.len() != 0)
			{
				local blockChance = ::Const.Combat.RangedAttackBlockedChance * _attackerProperties.RangedAttackBlockedChanceMult;
				toHit = ::Math.floor(toHit * (1.0 - blockChance));
			}
		}

		return ::Math.max(::Const.Combat.HitChanceMin, ::Math.min(::Const.Combat.HitChanceMax, toHit));
	}

	function attackEntity( _user, _targetEntity, _allowDiversion = true, _isDiverted = false )
	{
		if (_targetEntity != null && !_targetEntity.isAlive())
		{
			return false;
		}

		local properties = this.m.Container.buildPropertiesForUse(this, _targetEntity);
		local userTile = _user.getTile();
		local astray = false;

		if (_allowDiversion && this.m.IsRanged && userTile.getDistanceTo(_targetEntity.getTile()) > 1)
		{
			local blockedTiles = ::Const.Tactical.Common.getBlockedTiles(userTile, _targetEntity.getTile(), _user.getFaction());

			if (blockedTiles.len() != 0 && this.Math.rand(1, 100) <= this.Math.ceil(this.Const.Combat.RangedAttackBlockedChance * properties.RangedAttackBlockedChanceMult * 100))
			{
				_allowDiversion = false;
				_isDiverted = true;
				astray = true;
				_targetEntity = blockedTiles[this.Math.rand(0, blockedTiles.len() - 1)].getEntity();
			}
		}

		if (!_targetEntity.isAttackable())
		{
			if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
			{
				local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;

				if (_user.getTile().getDistanceTo(_targetEntity.getTile()) >= this.Const.Combat.SpawnProjectileMinDist)
				{
					this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), _targetEntity.getTile(), 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
				}
			}

			return false;
		}

		local defenderProperties = _targetEntity.getSkills().buildPropertiesForDefense(_user, this);
		local defense = _targetEntity.getDefense(_user, this, defenderProperties);
		local levelDifference = _targetEntity.getTile().Level - _user.getTile().Level;
		local distanceToTarget = _user.getTile().getDistanceTo(_targetEntity.getTile());
		local toHit = this.getHitchance(_targetEntity, _allowDiversion, properties, defenderProperties);

		if (this.m.IsRanged && _isDiverted && this.m.IsShowingProjectile)
		{
			toHit += ::Const.Combat.DivertedAttackHitchanceAdd;
			properties.DamageTotalMult *= ::Const.Combat.DivertedAttackDamageMult;
		}

		if (defense > -100 && skill > -100)
		{
			toHit = this.Math.max(::Const.Combat.HitChanceMin, this.Math.min(::Const.Combat.HitChanceMax, toHit));
		}

		_targetEntity.onAttacked(_user);

		if (this.m.IsDoingAttackMove && !_user.isHiddenToPlayer() && !_targetEntity.isHiddenToPlayer())
		{
			this.Tactical.getShaker().cancel(_user);

			if (this.m.IsDoingForwardMove)
			{
				this.Tactical.getShaker().shake(_user, _targetEntity.getTile(), 5);
			}
			else
			{
				local otherDir = _targetEntity.getTile().getDirectionTo(_user.getTile());

				if (_user.getTile().hasNextTile(otherDir))
				{
					this.Tactical.getShaker().shake(_user, _user.getTile().getNextTile(otherDir), 6);
				}
			}
		}

		if (!_targetEntity.isAbleToDie() && _targetEntity.getHitpoints() == 1)
		{
			toHit = 0;
		}

		if (!this.isUsingHitchance())
		{
			toHit = 100;
		}

		local r = this.Math.rand(1, 100);

		if (("Assets" in this.World) && this.World.Assets != null && this.World.Assets.getCombatDifficulty() == 0)
		{
			if (_user.isPlayerControlled())
			{
				r = this.Math.max(1, r - ::Const.Combat.BeginnerDifficultyHitchanceBonus);
			}
			else if (_targetEntity.isPlayerControlled())
			{
				r = this.Math.min(100, r + ::Const.Combat.BeginnerDifficultyDefenseBonus);
			}
		}

		local isHit = r <= toHit;

		if (!_user.isHiddenToPlayer() && !_targetEntity.isHiddenToPlayer())
		{
			local rolled = r;
			this.Tactical.EventLog.log_newline();

			if (astray)
			{
				if (this.isUsingHitchance())
				{
					if (isHit)
					{
						this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and the shot goes astray and hits " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(::Const.Combat.HitChanceMax, this.Math.max(::Const.Combat.HitChanceMin, toHit)) + ", Rolled: " + rolled + ")");
					}
					else
					{
						this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and the shot goes astray and misses " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(::Const.Combat.HitChanceMax, this.Math.max(::Const.Combat.HitChanceMin, toHit)) + ", Rolled: " + rolled + ")");
					}
				}
				else
				{
					this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and the shot goes astray and hits " + this.Const.UI.getColorizedEntityName(_targetEntity));
				}
			}
			else if (this.isUsingHitchance())
			{
				if (isHit)
				{
					this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and hits " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(::Const.Combat.HitChanceMax, this.Math.max(::Const.Combat.HitChanceMin, toHit)) + ", Rolled: " + rolled + ")");
				}
				else
				{
					this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and misses " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(::Const.Combat.HitChanceMax, this.Math.max(::Const.Combat.HitChanceMin, toHit)) + ", Rolled: " + rolled + ")");
				}
			}
			else
			{
				this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and hits " + this.Const.UI.getColorizedEntityName(_targetEntity));
			}
		}

		if (isHit && this.Math.rand(1, 100) <= _targetEntity.getCurrentProperties().RerollDefenseChance)
		{
			r = this.Math.rand(1, 100);
			isHit = r <= toHit;
		}

		if (isHit)
		{
			this.getContainer().setBusy(true);
			local info = {
				Skill = this,
				Container = this.getContainer(),
				User = _user,
				TargetEntity = _targetEntity,
				Properties = properties,
				DistanceToTarget = distanceToTarget,
				PropertiesForDefense = defenderProperties
			};

			if (this.m.IsShowingProjectile && this.m.ProjectileType != 0 && _user.getTile().getDistanceTo(_targetEntity.getTile()) >= this.Const.Combat.SpawnProjectileMinDist && (!_user.isHiddenToPlayer() || !_targetEntity.isHiddenToPlayer()))
			{
				local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;
				local time = this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), _targetEntity.getTile(), 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
				this.Time.scheduleEvent(this.TimeUnit.Virtual, time, this.onScheduledTargetHit, info);

				if (this.m.SoundOnHit.len() != 0)
				{
					this.Time.scheduleEvent(this.TimeUnit.Virtual, time + this.m.SoundOnHitDelay, this.onPlayHitSound.bindenv(this), {
						Sound = this.m.SoundOnHit[this.Math.rand(0, this.m.SoundOnHit.len() - 1)],
						Pos = _targetEntity.getPos()
					});
				}
			}
			else
			{
				if (this.m.SoundOnHit.len() != 0)
				{
					this.Sound.play(this.m.SoundOnHit[this.Math.rand(0, this.m.SoundOnHit.len() - 1)], this.Const.Sound.Volume.Skill * this.m.SoundVolume, _targetEntity.getPos());
				}

				if (this.Tactical.State.getStrategicProperties() != null && this.Tactical.State.getStrategicProperties().IsArenaMode && toHit <= 15)
				{
					this.Sound.play(this.Const.Sound.ArenaShock[this.Math.rand(0, this.Const.Sound.ArenaShock.len() - 1)], this.Const.Sound.Volume.Tactical * this.Const.Sound.Volume.Arena);
				}

				this.onScheduledTargetHit(info);
			}

			return true;
		}
		else
		{
			local distanceToTarget = _user.getTile().getDistanceTo(_targetEntity.getTile());
			_targetEntity.onMissed(_user, this, this.m.IsShieldRelevant && shield != null && r <= toHit + shieldBonus * 2);
			this.m.Container.onTargetMissed(this, _targetEntity);
			local prohibitDiversion = false;

			if (_allowDiversion && this.m.IsRanged && !_user.isPlayerControlled() && this.Math.rand(1, 100) <= ::Const.Combat.AIRangedAttackDiversionChance && distanceToTarget > 2)
			{
				local targetTile = _targetEntity.getTile();

				for (local i = 0; i < this.Const.Direction.COUNT; i++)
				{
					if (targetTile.hasNextTile(i))
					{
						local tile = targetTile.getNextTile(i);

						if (!tile.IsEmpty && tile.IsOccupiedByActor && tile.getEntity().isAlliedWith(_user))
						{
							prohibitDiversion = true;
							break;
						}
					}
				}
			}

			if (_allowDiversion && this.m.IsRanged && !(this.m.IsShieldRelevant && shield != null && r <= toHit + shieldBonus * 2) && !prohibitDiversion && distanceToTarget > 2)
			{
				this.divertAttack(_user, _targetEntity);
			}
			else if (this.m.IsShieldRelevant && shield != null && r <= toHit + shieldBonus * 2)
			{
				local info = {
					Skill = this,
					User = _user,
					TargetEntity = _targetEntity,
					Shield = shield
				};

				if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
				{
					local divertTile = _targetEntity.getTile();
					local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;
					local time = 0;

					if (_user.getTile().getDistanceTo(divertTile) >= this.Const.Combat.SpawnProjectileMinDist)
					{
						time = this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), divertTile, 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
					}

					this.Time.scheduleEvent(this.TimeUnit.Virtual, time, this.onShieldHit, info);
				}
				else
				{
					this.onShieldHit(info);
				}
			}
			else
			{
				if (this.m.SoundOnMiss.len() != 0)
				{
					this.Sound.play(this.m.SoundOnMiss[this.Math.rand(0, this.m.SoundOnMiss.len() - 1)], this.Const.Sound.Volume.Skill * this.m.SoundVolume, _targetEntity.getPos());
				}

				if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
				{
					local divertTile = _targetEntity.getTile();
					local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;

					if (_user.getTile().getDistanceTo(divertTile) >= this.Const.Combat.SpawnProjectileMinDist)
					{
						this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), divertTile, 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
					}
				}

				if (this.Tactical.State.getStrategicProperties() != null && this.Tactical.State.getStrategicProperties().IsArenaMode)
				{
					if (toHit >= 90 || _targetEntity.getHitpointsPct() <= 0.1)
					{
						this.Sound.play(this.Const.Sound.ArenaMiss[this.Math.rand(0, this.Const.Sound.ArenaBigMiss.len() - 1)], this.Const.Sound.Volume.Tactical * this.Const.Sound.Volume.Arena);
					}
					else if (this.Math.rand(1, 100) <= 20)
					{
						this.Sound.play(this.Const.Sound.ArenaMiss[this.Math.rand(0, this.Const.Sound.ArenaMiss.len() - 1)], this.Const.Sound.Volume.Tactical * this.Const.Sound.Volume.Arena);
					}
				}
			}

			return false;
		}
	}

	function divertAttack( _user, _targetEntity )
	{
		local tile = _targetEntity.getTile();
		local dist = _user.getTile().getDistanceTo(tile);

		if (dist < this.Const.Combat.DiversionMinDist)
		{
			return;
		}

		local d = _user.getTile().getDirectionTo(tile);

		if (dist >= this.Const.Combat.DiversionSpreadMinDist)
		{
			d = this.Math.rand(0, this.Const.Direction.COUNT - 1);
		}

		if (tile.hasNextTile(d))
		{
			local divertTile = tile.getNextTile(d);
			local levelDifference = divertTile.Level - _targetEntity.getTile().Level;

			if (divertTile.IsOccupiedByActor && levelDifference <= this.Const.Combat.DiversionMaxLevelDifference)
			{
				this.attackEntity(_user, divertTile.getEntity(), false, true);
			}
			else
			{
				local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;
				local time = 0;

				if (this.m.IsShowingProjectile && this.m.ProjectileType != 0 && _user.getTile().getDistanceTo(tile) >= this.Const.Combat.SpawnProjectileMinDist)
				{
					time = this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), divertTile, 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
				}

				this.getContainer().setBusy(true);

				if (this.m.SoundOnMiss.len() != 0)
				{
					this.Sound.play(this.m.SoundOnMiss[this.Math.rand(0, this.m.SoundOnMiss.len() - 1)], this.Const.Sound.Volume.Skill * this.m.SoundVolume, divertTile.Pos);
				}

				if (divertTile.IsEmpty && !divertTile.IsCorpseSpawned && this.Const.Tactical.TerrainSubtypeAllowProjectileDecals[divertTile.Subtype] && this.Const.ProjectileDecals[this.m.ProjectileType].len() != 0 && this.Math.rand(0, 100) < this.Const.Combat.SpawnArrowDecalChance)
				{
					local info = {
						Skill = this,
						Container = this.getContainer(),
						User = _user,
						TileHit = divertTile
					};

					if (this.m.IsShowingProjectile && _user.getTile().getDistanceTo(divertTile) >= this.Const.Combat.SpawnProjectileMinDist && (!_user.isHiddenToPlayer() || divertTile.IsVisibleForPlayer))
					{
						this.Time.scheduleEvent(this.TimeUnit.Virtual, time, this.onScheduledProjectileSpawned, info);
					}
					else
					{
						this.onScheduledProjectileSpawned(info);
					}
				}
			}
		}
	}

	function onScheduledTargetHit( _info )
	{
		_info.Container.setBusy(false);

		if (!_info.TargetEntity.isAlive())
		{
			return;
		}

		local partHit = this.Math.rand(1, 100);
		local bodyPart = this.Const.BodyPart.Body;
		local bodyPartDamageMult = 1.0;

		if (partHit <= _info.Properties.getHitchance(this.Const.BodyPart.Head))
		{
			bodyPart = this.Const.BodyPart.Head;
		}
		else
		{
			bodyPart = this.Const.BodyPart.Body;
		}

		bodyPartDamageMult = bodyPartDamageMult * _info.Properties.DamageAgainstMult[bodyPart];
		local damageMult = this.m.IsRanged ? _info.Properties.RangedDamageMult : _info.Properties.MeleeDamageMult;
		damageMult = damageMult * _info.Properties.DamageTotalMult;
		// local damageRegular = this.Math.rand(_info.Properties.DamageRegularMin, _info.Properties.DamageRegularMax) * _info.Properties.DamageRegularMult;
		local damageRegular = ::Math.rand(_info.Properties.getDamageRegularMin(), _info.Properties.getDamageRegularMax());
		// local damageArmor = this.Math.rand(_info.Properties.DamageRegularMin, _info.Properties.DamageRegularMax) * _info.Properties.DamageArmorMult;
		local damageArmor = ::Math.rand(_info.Properties.getDamageArmorMin(), _info.Properties.getDamageArmorMax());
		damageRegular = this.Math.max(0, damageRegular + _info.DistanceToTarget * _info.Properties.DamageAdditionalWithEachTile);
		damageArmor = this.Math.max(0, damageArmor + _info.DistanceToTarget * _info.Properties.DamageAdditionalWithEachTile);
		local damageDirect = _info.Properties.getDamageDirect(_info.Skill);
		local injuries;


		// Bring the MSU Damage system here instead of skill_container onBeforeTargetHit

		if (this.m.InjuriesOnBody != null && bodyPart == this.Const.BodyPart.Body)
		{
			injuries = this.m.InjuriesOnBody;
		}
		else if (this.m.InjuriesOnHead != null && bodyPart == this.Const.BodyPart.Head)
		{
			injuries = this.m.InjuriesOnHead;
		}

		local hitInfo = clone this.Const.Tactical.HitInfo;
		hitInfo.PropertiesForUse = _info.Properties;
		hitInfo.PropertiesForDefense = _info.PropertiesForDefense;
		hitInfo.DamageRegular = damageRegular * damageMult;
		hitInfo.DamageArmor = damageArmor * damageMult;
		hitInfo.DamageDirect = damageDirect;
		hitInfo.DamageFatigue = this.Const.Combat.FatigueReceivedPerHit * _info.Properties.FatigueDealtPerHitMult;
		hitInfo.DamageMinimum = _info.Properties.DamageMinimum;
		hitInfo.BodyPart = bodyPart;
		hitInfo.BodyDamageMult = bodyPartDamageMult;
		hitInfo.FatalityChanceMult = _info.Properties.FatalityChanceMult;
		hitInfo.Injuries = injuries;
		hitInfo.InjuryThresholdMult = _info.Properties.ThresholdToInflictInjuryMult;
		hitInfo.Tile = _info.TargetEntity.getTile();
		_info.Container.onBeforeTargetHit(_info.Skill, _info.TargetEntity, hitInfo);
		_info.TargetEntity.getSkills().onBeforeGettingHit(_info.User, _info.Skill, hitInfo);
		local pos = _info.TargetEntity.getPos();
		local hasArmorHitSound = _info.TargetEntity.getItems().getAppearance().ImpactSound[bodyPart].len() != 0;
		_info.TargetEntity.onDamageReceived(_info.User, _info.Skill, hitInfo);

		// TODO: An issue is that onAfterDamageReceived is only called when the target entity is alive and it is called via <actor>.onDamageReceived, and not this function

		if (hitInfo.DamageInflictedHitpoints >= this.Const.Combat.PlayHitSoundMinDamage)
		{
			if (this.m.SoundOnHitHitpoints.len() != 0)
			{
				this.Sound.play(this.m.SoundOnHitHitpoints[this.Math.rand(0, this.m.SoundOnHitHitpoints.len() - 1)], this.Const.Sound.Volume.Skill * this.m.SoundVolume, pos);
			}
		}

		if (hitInfo.DamageInflictedHitpoints == 0 && hitInfo.DamageInflictedArmor >= this.Const.Combat.PlayHitSoundMinDamage)
		{
			if (this.m.SoundOnHitArmor.len() != 0)
			{
				this.Sound.play(this.m.SoundOnHitArmor[this.Math.rand(0, this.m.SoundOnHitArmor.len() - 1)], this.Const.Sound.Volume.Skill * this.m.SoundVolume, pos);
			}
		}

		if (typeof _info.User == "instance" && _info.User.isNull() || !_info.User.isAlive() || _info.User.isDying())
		{
			return;
		}

		_info.Container.onTargetHit(_info.Skill, _info.TargetEntity, hitInfo.BodyPart, hitInfo.DamageInflictedHitpoints, hitInfo.DamageInflictedArmor);
		if (_info.TargetEntity.isAlive()) _info.TargetEntity.getSkills().onGettingHit(_info.User, _info.Skill, hitInfo);
		_info.User.getItems().onDamageDealt(_info.TargetEntity, this, hitInfo);

		if (hitInfo.DamageInflictedHitpoints >= this.Const.Combat.SpawnBloodMinDamage && !_info.Skill.isRanged() && (_info.TargetEntity.getBloodType() == this.Const.BloodType.Red || _info.TargetEntity.getBloodType() == this.Const.BloodType.Dark))
		{
			_info.User.addBloodied();
			local item = _info.User.getItems().getItemAtSlot(this.Const.ItemSlot.Mainhand);

			if (item != null && item.isItemType(this.Const.Items.ItemType.MeleeWeapon))
			{
				item.setBloodied(true);
			}
		}
	}
});

::MSU.EndQueue.add(function() {
	::mods_hookBaseClass("skills/skill", function(o) {
		o = o[o.SuperName];
		foreach (func in ::MSU.Skills.PreviewApplicableFunctions)
		{
			local oldFunc = o[func];
			o[func] = function()
			{
				if (!this.m.IsApplyingPreview) return oldFunc();

				local temp = {};
				foreach (field, change in this.PreviewField)
				{
					temp[field] <- this.m[field];
					if (change.Multiplicative)
					{
						this.m[field] *= change.Change;
					}
					else if (typeof change.Change == "boolean")
					{
						this.m[field] = change.Change;
					}
					else
					{
						this.m[field] += change.Change;
					}
				}

				local properties = this.getContainer().getActor().getCurrentProperties();
				foreach (field, change in this.getContainer().PreviewProperty)
				{
					temp[field] <- properties[field];
					if (change.Multiplicative)
					{
						properties[field] *= change.Change;
					}
					else if (typeof change.Change == "boolean")
					{
						properties[field] = change.Change;
					}
					else
					{
						properties[field] += change.Change;
					}
				}

				local ret = oldFunc();

				if (temp.len() > 0)
				{
					foreach (field, change in this.PreviewField)
					{
						this.m[field] = temp[field];
					}

					foreach (field, change in this.getContainer().PreviewProperty)
					{
						properties[field] = temp[field];
					}
				}

				return ret;
			}
		}

		local isAffordablePreview = o.isAffordablePreview;
		o.isAffordablePreview = function()
		{
			if (!this.getContainer().m.IsPreviewing) return isAffordablePreview();
			this.m.IsApplyingPreview = true;
			local ret = isAffordablePreview();
			this.m.IsApplyingPreview = false;
			return ret;
		}

		local getCostString = o.getCostString;
		o.getCostString = function()
		{
			if (!this.getContainer().m.IsPreviewing) return getCostString();
			local preview = ::Tactical.TurnSequenceBar.m.ActiveEntityCostsPreview;
			if (preview != null && preview.id == this.getContainer().getActor().getID())
			{
				this.m.IsApplyingPreview = true;
				local ret = getCostString();
				this.m.IsApplyingPreview = false;
				local skillID = this.getContainer().getActor().getPreviewSkillID();
				local str = " after " + (skillID == "" ? "moving" : "using " + this.getContainer().getSkillByID(skillID).getName());
				ret = ::MSU.String.replace(ret, "Fatigue[/color]", "Fatigue[/color]" + str);
				return ret;
			}

			return getCostString();
		}
	});
});
