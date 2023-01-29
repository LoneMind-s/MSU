local function queryVanillaTooltip(_id)
{
	return ::TooltipEvents.general_queryUIElementTooltipData(null, _id, null)
}
::MSU.Mod.Tooltips.setTooltips({
	Attributes = {
		Matk = ::MSU.Class.CustomTooltip(@(_) queryVanillaTooltip("character-stats.MeleeSkill")),
		Mdef = ::MSU.Class.CustomTooltip(@(_) queryVanillaTooltip("character-stats.MeleeDefense")),
		Ratk = ::MSU.Class.CustomTooltip(@(_) queryVanillaTooltip("character-stats.RangeSkill")),
		Rdef = ::MSU.Class.CustomTooltip(@(_) queryVanillaTooltip("character-stats.RangeDefense")),
	},
	ModSettings = {
		Main = {
			Cancel = ::MSU.Class.BasicTooltip("Cancel", "Don't save changes."),
			Reset = ::MSU.Class.BasicTooltip("Reset", "Resets all settings on this page."),
			Apply = ::MSU.Class.BasicTooltip("Apply", "Save all changes from every page without closing the screen."),
			OK = ::MSU.Class.BasicTooltip("Save all changes", "Save all changes from every page and close the screen.")
		},
		Element = {
			Tooltip = ::MSU.Class.CustomTooltip(@(_data) ::getModSetting(_data.elementModId, _data.settingsElementId).getTooltip(_data))
		},
		Keybind = {
			Popup = {
				Cancel = {
					Title = "Cancel",
					Description = "Don't save changes."
				},
				Add = {
					Title = "Add",
					Description = "Add another keybind."
				},
				OK = {
					Title = "Save",
					Description = "Save changes."
				},
				Modify = {
					Title = "Modify",
					Description = "Modify this keybind."
				},
				Delete = {
					Title = "Delete",
					Description = "Delete this keybind."
				},
			}
		}
	}
});
::MSU.Mod.Tooltips.setTooltipImageKeywords({
	"ui/icons/melee_skill.png" 		: "Attributes.Matk"
	"ui/icons/melee_defense.png" 	: "Attributes.Mdef"
	"ui/icons/ranged_skill.png" 	: "Attributes.Ratk"
	"ui/icons/ranged_defense.png" 	: "Attributes.Rdef"
})
