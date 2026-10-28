class_name ChaosSkillModifier
extends RefCounted

## ST.4：混乱符号能力的技能修正 → 信息层 MODIFIER Buff（THIS_SKILL_TEST）。
## 禁止只写 SkillTestContext.chaos_modifier；经 seq.effect.register 创建。


## 施加 amount（可负）到本次检定技能；成功后镜像写入 ctx.chaos_modifier 供审计。
static func apply(game_ctx: GameContext, ctx: SkillTestContext, amount: int) -> bool:
	if ctx == null or amount == 0:
		return true
	if game_ctx == null or game_ctx.sequence_catalog == null:
		push_error("ChaosSkillModifier: no sequence_catalog; refused vacuum register")
		return false
	var inv_id := ctx.performing_investigator
	if inv_id == &"":
		push_error("ChaosSkillModifier: missing performing_investigator")
		return false
	var template := RegistrationTemplate.skill_modifier_this_test(
		inv_id,
		_skill_to_stat(ctx.skill),
		amount
	)
	var result: Dictionary = game_ctx.sequence_catalog.nest(
		game_ctx,
		&"seq.effect.register",
		{
			"controller_id": inv_id,
			"template": template,
		}
	)
	if not bool(result.get("ok", false)):
		push_error("ChaosSkillModifier: seq.effect.register failed")
		return false
	ctx.chaos_modifier += amount
	var reg_id: StringName = result.get("reg_id", &"") as StringName
	if reg_id != &"":
		ctx.chaos_modifier_reg_ids.append(reg_id)
	return true


static func _skill_to_stat(skill: AhcEnums.SkillType) -> AhcEnums.StatRef:
	match skill:
		AhcEnums.SkillType.WILLPOWER:
			return AhcEnums.StatRef.SKILL_WILLPOWER
		AhcEnums.SkillType.INTELLECT:
			return AhcEnums.StatRef.SKILL_INTELLECT
		AhcEnums.SkillType.COMBAT:
			return AhcEnums.StatRef.SKILL_COMBAT
		AhcEnums.SkillType.AGILITY:
			return AhcEnums.StatRef.SKILL_AGILITY
		_:
			return AhcEnums.StatRef.SKILL_ANY
