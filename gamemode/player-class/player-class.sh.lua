PlayerClassService = PlayerClassService or {}

function PlayerClassService.CreatePlayerClass(props)
	local ply_class = table.Merge({
		key = props.key or props.name,
		display_name = true,
		color = props.color,
		can_walljump = true,
		can_wallslide = true,
		can_airaccel = true,
		can_autojump = false,
		can_regenerate_health = true,
		can_take_fall_damage = true,
		can_damage_everyone = true,
		can_damage = {},

		weapons = {
			weapon_crowbar = true
		}
	}, props)

	return ply_class
end

function PlayerClassService.MinigamePlayerClass(ply, id_or_key)
	for _, ply_class in pairs(ply.lobby.player_classes) do
		if id_or_key == ply_class.id or id_or_key == ply_class.key then
			return ply_class
		end
	end
end