InputBar = InputBar or Class.New(Element)

function InputBar:Init(label, type)
	InputBar.super.Init(self, {
		layout_justification_y = JUSTIFY_CENTER,
		fit_y = true,
		width = BAR_WIDTH,
		padding_x = MARGIN * 8,
		padding_y = MARGIN * 4,
		inherit_color = false,
		color = COLOR_WHITE,

		label = Element.New {
			fit_y = true,
			width_percent = 0.75,
			crop_top = 0.15,
			font = "InputLabel",
			text = label,
		},

		Element.New {
			layout = false,
			origin_position = true,
			origin_justification_x = JUSTIFY_CENTER,
			origin_justification_y = JUSTIFY_END,
			position_justification_x = JUSTIFY_CENTER,
			position_justification_y = JUSTIFY_END,
			width_percent = 1,
			height = 1,
			inherit_color = false,
			fill_color = true,
			color = COLOR_BACKGROUND_LIGHT,

			alpha = function ()
				return self.last and 0 or 255
			end
		}
	})

	self.input_container = self:Add(Element.New {
		layout_justification_x = JUSTIFY_END,
		layout_justification_y = JUSTIFY_CENTER,
		fit_y = true,
		width_percent = 0.25
	})

	local input_element

	if not type or type == "boolean" then
		input_element = Checkbox
	else
		self.label:SetAttribute("width_percent", 0.5)
		self.input_container:SetAttribute("width_percent", 0.5)

		if type == "text" then
			input_element = TextInput
		elseif type == "time" then
			input_element = TimeInput
		end
	end

	self.input = self.input_container:Add(input_element.New())
end