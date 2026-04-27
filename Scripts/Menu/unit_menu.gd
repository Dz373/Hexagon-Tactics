extends Control

func display_stats(unit:Unit):
	visible = true
	
	$Class.text = "Class: " + str(unit.stats["class_name"])
	$Stats/Hp.text = "Hp: %d / %d" %[unit.hp, unit.stats["hp"]]
	$Stats/Atk.text = "Atk: " + str(unit.stats["atk"])
	$Stats/Def.text = "Def: " + str(unit.stats["def"])
	$Stats/Mv.text = "Mv: " + str(unit.stats["mv"])
	
	if unit.stats["min_range"] != unit.stats["max_range"]:
		$Stats/AtkRange.text = "Range: %d - %d" %[unit.stats["min_range"], unit.stats["max_range"]]
	else:
		$Stats/AtkRange.text = "Range: %d" %unit.stats["min_range"]
	
	var skills = unit.stats["skills"]
	if skills.is_empty():
		$Skill/Skill1.text = ""
	for skl in skills:
		$Skill/Skill1.text = skl
