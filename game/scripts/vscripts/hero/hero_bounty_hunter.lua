CreateEmptyTalents("bounty_hunter")

imba_bounty_hunter_shuriken_toss = class({})

LinkLuaModifier("modifier_imba_shuriken_toss_chain", "hero/hero_bounty_hunter", LUA_MODIFIER_MOTION_NONE)

function imba_bounty_hunter_shuriken_toss:IsHiddenWhenStolen() 		return false end
function imba_bounty_hunter_shuriken_toss:IsRefreshable() 			return true  end
function imba_bounty_hunter_shuriken_toss:IsStealable() 			return true  end
function imba_bounty_hunter_shuriken_toss:IsNetherWardStealable() 	return true end

function imba_bounty_hunter_shuriken_toss:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_BountyHunter.Shuriken", caster)
	local info = 
	{
		Target = target,
		Source = caster,
		Ability = self,	
		EffectName = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_suriken_toss.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("speed"),
		vSourceLoc= caster:GetAbsOrigin(),
		bDrawsOnMinimap = false,
		bDodgeable = true,
		bIsAttack = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = GameRules:GetGameTime() + 30,
		bProvidesVision = false,	
	}
	ProjectileManager:CreateTrackingProjectile(info)
	local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), Vector(0,0,0), nil, 250000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_UNITS_EVERYWHERE, false)
	for _, enemy in pairs(enemies) do
		if enemy:HasModifier("modifier_imba_track") and enemy ~= target then
			EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_BountyHunter.Shuriken", caster)
			local info = 
			{
				Target = enemy,
				Source = caster,
				Ability = self,	
				EffectName = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_suriken_toss.vpcf",
				iMoveSpeed = self:GetSpecialValueFor("speed"),
				vSourceLoc= caster:GetAbsOrigin(),
				bDrawsOnMinimap = false,
				bDodgeable = true,
				bIsAttack = false,
				bVisibleToEnemies = true,
				bReplaceExisting = false,
				flExpireTime = GameRules:GetGameTime() + 30,
				bProvidesVision = false,	
			}
			ProjectileManager:CreateTrackingProjectile(info)
		end
	end
end

function imba_bounty_hunter_shuriken_toss:OnProjectileHit(hTarget, vLocation)
	if not hTarget then
		return
	end
	if hTarget:TriggerStandardTargetSpell(self) then
		return
	end
	local caster = self:GetCaster()
	local target = hTarget
	EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_BountyHunter.Shuriken.Impact", hTarget)
	local damageTable = {
						victim = target,
						attacker = caster,
						damage = self:GetSpecialValueFor("damage"),
						damage_type = self:GetAbilityDamageType(),
						damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
						ability = self, --Optional.
						}
	ApplyDamage(damageTable)
	target:AddNewModifier(caster, self, "modifier_imba_stunned", {duration = self:GetSpecialValueFor("mini_stun")})
	target:AddNewModifier(caster, self, "modifier_imba_shuriken_toss_chain", {duration = self:GetSpecialValueFor("chain_duration")})
	return true
end

modifier_imba_shuriken_toss_chain = class({})

function modifier_imba_shuriken_toss_chain:IsDebuff()			return true end
function modifier_imba_shuriken_toss_chain:IsHidden() 			return false end
function modifier_imba_shuriken_toss_chain:IsPurgable() 		return false end
function modifier_imba_shuriken_toss_chain:IsPurgeException() 	return false end
function modifier_imba_shuriken_toss_chain:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_imba_shuriken_toss_chain:OnCreated()
	if not IsServer() then
		return
	end
	local target_position = self:GetParent():GetAbsOrigin()
	self.dummy = CreateUnitByName("npc_dummy_unit", target_position, false, nil, nil, self:GetCaster():GetTeamNumber())
	self.dummy:SetAbsOrigin(target_position)
	self.dummy:AddNewModifier(self.dummy, nil, "modifier_kill", {duration = self:GetDuration() + 1.0})
	local pfx = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_trapper_beam_chain/pudge_nx_meathook_chain.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(pfx, 6, self.dummy, PATTACH_POINT_FOLLOW, "attach_hitloc", target_position, false)
	ParticleManager:SetParticleControlEnt(pfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", target_position, false)
	self:AddParticle(pfx, false, false, 15, false, false)
	self:StartIntervalThink(0.1)
end

function modifier_imba_shuriken_toss_chain:OnIntervalThink()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local ability = self:GetAbility()
	local chain_range = ability:GetSpecialValueFor("chain_range")
	local pull_strength = ability:GetSpecialValueFor("pull_strength_tooltip")

	-- Retrieve the target's distance from the impact point
	local target_position = target:GetAbsOrigin()
	local center_vector = self.dummy:GetAbsOrigin() - target_position
	local len = center_vector:Length2D()
	local tick_rate = 0.05

	-- Push the target towards the impact point with a strength proportional to its distance from it
	local pull_distance = center_vector:Normalized() * len / chain_range * pull_strength * tick_rate
	FindClearSpaceForUnit(target, target_position + pull_distance, false)
end

function modifier_imba_shuriken_toss_chain:OnDestroy()
	if not IsServer() then
		return
	end
	self.dummy = nil
end

imba_bounty_hunter_wind_walk = class({})

LinkLuaModifier("modifier_imba_wind_walk_fade", "hero/hero_bounty_hunter", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_wind_walk", "hero/hero_bounty_hunter", LUA_MODIFIER_MOTION_NONE)

function imba_bounty_hunter_wind_walk:IsHiddenWhenStolen() 		return false end
function imba_bounty_hunter_wind_walk:IsRefreshable() 			return true  end
function imba_bounty_hunter_wind_walk:IsStealable() 			return true  end
function imba_bounty_hunter_wind_walk:IsNetherWardStealable() 	return true end

function imba_bounty_hunter_wind_walk:OnSpellStart()
	EmitSoundOnLocationWithCaster(self:GetCaster():GetAbsOrigin(), "Hero_BountyHunter.WindWalk", self:GetCaster())
	self:GetCaster():AddNewModifier(self:GetCaster() , self, "modifier_imba_wind_walk_fade", {duration = self:GetSpecialValueFor("fade_time")})
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
	ParticleManager:ReleaseParticleIndex(pfx)
end

modifier_imba_wind_walk_fade = class({})

function modifier_imba_wind_walk_fade:IsDebuff()			return false end
function modifier_imba_wind_walk_fade:IsHidden() 			return false end
function modifier_imba_wind_walk_fade:IsPurgable() 			return false end
function modifier_imba_wind_walk_fade:IsPurgeException() 	return false end

function modifier_imba_wind_walk_fade:OnDestroy()
	if IsServer() then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_wind_walk", {duration = self:GetAbility():GetSpecialValueFor("duration")})
	end
end

modifier_imba_wind_walk = class({})

function modifier_imba_wind_walk:IsDebuff()				return false end
function modifier_imba_wind_walk:IsHidden() 			return false end
function modifier_imba_wind_walk:IsPurgable() 			return false end
function modifier_imba_wind_walk:IsPurgeException() 	return false end
function modifier_imba_wind_walk:GetEffectName() return "particles/generic_hero_status/status_invisibility_start.vpcf" end
function modifier_imba_wind_walk:GetEffectAttachType() return PATTACH_ABSORIGIN end

function modifier_imba_wind_walk:CheckState()
	return {[MODIFIER_STATE_INVISIBLE] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_imba_wind_walk:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_DISABLE_AUTOATTACK, MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_PROPERTY_INVISIBILITY_LEVEL}
end

function modifier_imba_wind_walk:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end

function modifier_imba_wind_walk:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("move_speed") end

function modifier_imba_wind_walk:GetDisableAutoAttack() return true end

function modifier_imba_wind_walk:OnAttack(keys)
	if not IsServer() then
		return
	end
	if keys.attacker == self:GetParent() and self:GetParent():IsRangedAttacker() then
		self:Destroy()
	end
end

function modifier_imba_wind_walk:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	if keys.attacker == self:GetParent() and not self:GetParent():IsRangedAttacker() then
		self:Destroy()
	end
end

function modifier_imba_wind_walk:OnAbilityExecuted(keys)
	if not IsServer() then
		return
	end
	if keys.unit ~= self:GetParent() then
		return
	end
	local ability = self:GetParent():FindAbilityByName("imba_bounty_hunter_track")
	local ability2 = self:GetParent():FindAbilityByName("imba_bounty_hunter_shadow_jaunt")
	if keys.ability == ability or keys.ability == ability2 then
		return
	end
	self:Destroy()
end

function modifier_imba_wind_walk:GetModifierInvisibilityLevel() return 1 end

imba_bounty_hunter_shadow_jaunt = class({})

function imba_bounty_hunter_shadow_jaunt:IsHiddenWhenStolen() 		return false end
function imba_bounty_hunter_shadow_jaunt:IsRefreshable() 			return true  end
function imba_bounty_hunter_shadow_jaunt:IsStealable() 				return false  end
function imba_bounty_hunter_shadow_jaunt:IsNetherWardStealable() 	return false end

function imba_bounty_hunter_shadow_jaunt:CastFilterResultTarget(target)
	if target:IsInvulnerable() then
		return UF_FAIL_INVULNERABLE
	end
	if target == self:GetCaster() or not target:IsHero() then
		return UF_FAIL_CUSTOM
	end
end

function imba_bounty_hunter_shadow_jaunt:GetCustomCastErrorTarget(target)
	if target == self:GetCaster() then
		return "#dota_hud_error_cant_cast_on_self"
	elseif not target:IsHero() then
		return "dota_hud_error_cant_cast_on_other"
	end
end

function imba_bounty_hunter_shadow_jaunt:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:TriggerStandardTargetSpell(self) then
		return
	end
	-- Blink geometry
	local caster_pos = caster:GetAbsOrigin()
	local target_pos = target:GetAbsOrigin()
	local blink_direction = (target_pos - caster_pos):Normalized()
	target_pos = target_pos + blink_direction * 100
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
	ParticleManager:ReleaseParticleIndex(pfx)

	-- Blink
	FindClearSpaceForUnit(caster, target_pos, false)
	if caster:GetTeamNumber() ~= target:GetTeamNumber() then
		caster:SetForwardVector((target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized())
	else
		caster:SetForwardVector(blink_direction)
	end

	local pfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(pfx2, 0, target_pos)
	ParticleManager:ReleaseParticleIndex(pfx2)

	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Riki.Blink_Strike", caster)

	-- If the target is tracked, refresh all abilities
	if target:HasModifier("modifier_imba_track") then

		-- Refresh all abilities
		local current_ability
		for i = 0, 15 do
			current_ability = caster:GetAbilityByIndex(i)
			if current_ability and self ~= current_ability then
				current_ability:EndCooldown()
			end
		end
	end

	-- If the target is an enemy, start attacking it
	if caster:GetTeamNumber() ~= target:GetTeamNumber() then
		caster:SetAttacking(target)
		caster:SetForceAttackTarget(target)
		Timers:CreateTimer(0.01, function()
			caster:SetForceAttackTarget(nil)
		end)
	end
end


imba_bounty_hunter_track = class({})

LinkLuaModifier("modifier_imba_track_cirt", "hero/hero_bounty_hunter", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_track", "hero/hero_bounty_hunter", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_track_aura", "hero/hero_bounty_hunter", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_track_speed", "hero/hero_bounty_hunter", LUA_MODIFIER_MOTION_NONE)

function imba_bounty_hunter_track:IsHiddenWhenStolen() 		return false end
function imba_bounty_hunter_track:IsRefreshable() 			return true  end
function imba_bounty_hunter_track:IsStealable() 			return true  end
function imba_bounty_hunter_track:IsNetherWardStealable() 	return true end
function imba_bounty_hunter_track:GetIntrinsicModifierName() return "modifier_imba_track_cirt" end

function imba_bounty_hunter_track:OnUpgrade()
	if self:GetLevel() >= 2 then
		local ability = self:GetCaster():FindAbilityByName("imba_bounty_hunter_shadow_jaunt")
		if ability then
			ability:SetLevel(1)
		end
	end
end

function imba_bounty_hunter_track:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:TriggerStandardTargetSpell(self) then
		return
	end
	local pfx = ParticleManager:CreateParticle("particles/hero/bounty_hunter/bounty_hunter_track_cast.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(pfx, 0, caster, PATTACH_POINT, "attach_attack2", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(pfx)
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_BountyHunter.Target", caster)
	local buff = target:AddNewModifier(caster, self, "modifier_imba_track", {duration = self:GetSpecialValueFor("duration")})
	target:AddNewModifier(caster, self, "modifier_imba_track_aura", {duration = self:GetSpecialValueFor("duration")})
	if caster:HasScepter() then
		buff:SetStackCount(1)
	end
end

modifier_imba_track_cirt = class({})

function modifier_imba_track_cirt:IsDebuff()			return false end
function modifier_imba_track_cirt:IsHidden() 			return true end
function modifier_imba_track_cirt:IsPurgable() 			return false end
function modifier_imba_track_cirt:IsPurgeException() 	return false end

function modifier_imba_track_cirt:DeclareFunctions() return {MODIFIER_EVENT_ON_ATTACK_START} end
function modifier_imba_track_cirt:GetIMBAPhysicalCirtChance() return self.cirt end
function modifier_imba_track_cirt:GetIMBAPhysicalCirtBonus() return self:GetAbility():GetSpecialValueFor("crit_percentage") end

function modifier_imba_track_cirt:OnAttackStart(keys)
	if not IsServer() then
		return
	end
	if keys.attacker == self:GetParent() and not self:GetParent():PassivesDisabled() and not self:GetParent():IsRangedAttacker() then
		if keys.target:HasModifier("modifier_imba_track") then
			self.cirt = 100
			self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_ATTACK_EVENT, self:GetParent():GetAttackSpeed())
		else
			self.cirt = 0
		end
	end
	if keys.attacker == self:GetParent() and not self:GetParent():PassivesDisabled() and self:GetParent():IsRangedAttacker() and keys.target:HasModifier("modifier_imba_track") then
		self.cirt = 100
	end
end


modifier_imba_track = class({})

function modifier_imba_track:IsDebuff()	return true end
function modifier_imba_track:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_imba_track:RemoveOnDeath() return true end
function modifier_imba_track:IsHidden()
	if self:GetStackCount() == 1 then
		return true
	end
	return false
end
function modifier_imba_track:IsPurgable()
	if self:GetStackCount() == 1 then
		return false
	end
	return true
end
function modifier_imba_track:IsPurgeException()
	if self:GetStackCount() == 1 then
		return false
	end
	return true
end
function modifier_imba_track:CheckState()
	if self:GetParent():HasModifier("modifier_imba_shadow_dance_effect") then
		return  nil
	end
	return {[MODIFIER_STATE_INVISIBLE] = false}
end

function modifier_imba_track:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION, MODIFIER_EVENT_ON_HERO_KILLED}
end

function modifier_imba_track:GetModifierProvidesFOWVision() return 1 end

function modifier_imba_track:GetModifierIncomingDamage_Percentage()
	if self:GetStackCount() == 1 then
		return self:GetAbility():GetSpecialValueFor("bonus_damage_scepter")
	end
	return 0
end

function modifier_imba_track:OnHeroKilled(keys)
	if not IsServer() then
		return
	end
	if keys.target ~= self:GetParent() then
		return
	end
	if not keys.target:IsRealHero() or keys.reincarnate then
		return
	end
	local ally_gold = self:GetAbility():GetSpecialValueFor("bonus_gold") + keys.target:GetLevel() * self:GetAbility():GetSpecialValueFor("bonus_gold_per_lvl")
	local self_gold = self:GetAbility():GetSpecialValueFor("bonus_gold_self") + keys.target:GetLevel() * self:GetAbility():GetSpecialValueFor("bonus_gold_self_per_lvl")

	local allies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
									self:GetParent():GetAbsOrigin(),
									nil,
									self:GetAbility():GetSpecialValueFor("aura_radius"),
									DOTA_UNIT_TARGET_TEAM_FRIENDLY,
									DOTA_UNIT_TARGET_HERO,
									DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
									FIND_ANY_ORDER,
									false)

	for _,ally in pairs(allies) do
		if ally ~= self:GetCaster() and ally:IsRealHero() then
			ally:ModifyGold(ally_gold, true, 0)
			SendOverheadEventMessage(ally, OVERHEAD_ALERT_GOLD, ally, ally_gold, ally:GetPlayerID())
		end
	end
	self:GetCaster():ModifyGold(self_gold, true, 0)
	SendOverheadEventMessage(self:GetCaster(), OVERHEAD_ALERT_GOLD, self:GetCaster(), self_gold, self:GetCaster():GetPlayerID())
	self:Destroy()
end

function modifier_imba_track:OnCreated()
	if IsServer() then
		local target = self:GetParent()
		local caster = self:GetCaster()
		self.pfx1 = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_trail.vpcf", PATTACH_POINT_FOLLOW, target, caster:GetTeam())
		ParticleManager:SetParticleControlEnt(self.pfx1, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(self.pfx1, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

		self.pfx2 = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_shield.vpcf", PATTACH_OVERHEAD_FOLLOW, target, caster:GetTeam())
		if self:GetCaster():HasTalent("special_bonus_imba_bounty_hunter_1") then
			self:StartIntervalThink(0.1)
		end
	end
end

function modifier_imba_track:OnIntervalThink()
	AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), self:GetCaster():GetTalentValue("special_bonus_imba_bounty_hunter_1"), 0.1, false)
end

function modifier_imba_track:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.pfx1, false)
		ParticleManager:DestroyParticle(self.pfx2, false)
		ParticleManager:ReleaseParticleIndex(self.pfx1)
		ParticleManager:ReleaseParticleIndex(self.pfx2)
	end
end

modifier_imba_track_aura = class({})

function modifier_imba_track_aura:IsDebuff()	return true end
function modifier_imba_track_aura:IsHidden()	return true end
function modifier_imba_track_aura:IsPurgable()	return false end
function modifier_imba_track_aura:IsPurgeException()	return false end

function modifier_imba_track_aura:IsAura() return true end
function modifier_imba_track_aura:GetAuraDuration() return 0.5 end
function modifier_imba_track_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_imba_track_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function modifier_imba_track_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_imba_track_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_imba_track_aura:GetModifierAura() return "modifier_imba_track_speed" end

function modifier_imba_track_aura:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0.2)
	end
end

function modifier_imba_track_aura:OnIntervalThink()
	if not self:GetParent():HasModifier("modifier_imba_track") then
		self:Destroy()
	end
end

modifier_imba_track_speed = class({})

function modifier_imba_track_speed:IsDebuff()			return false end
function modifier_imba_track_speed:IsHidden() 			return false end
function modifier_imba_track_speed:IsPurgable() 		return false end
function modifier_imba_track_speed:IsPurgeException() 	return false end

function modifier_imba_track_speed:OnCreated()
	if IsServer() then
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_haste.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:SetParticleControl(pfx, 0, self:GetParent():GetAbsOrigin())
		ParticleManager:SetParticleControl(pfx, 1, self:GetParent():GetAbsOrigin())
		ParticleManager:SetParticleControl(pfx, 2, self:GetParent():GetAbsOrigin())

		self:AddParticle(pfx, false, false, -1, false, false)
		ParticleManager:ReleaseParticleIndex(pfx)
	end
end