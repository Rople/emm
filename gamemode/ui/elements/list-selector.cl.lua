ListSelector = ListSelector or Class.New(Element)

local hamburger_material = Material("emm2/ui/hamburger.png", "noclamp smooth")

function ListSelector:Init(v, props)
	ListSelector.super.Init(self, {
		width = CHECKBOX_SIZE,
		height = CHECKBOX_SIZE,
		background_color = COLOR_GRAY_DARK,
		border = LINE_THICKNESS,
		border_alpha = 0,
		cursor = "hand",
		bubble_mouse = false,

		hover = {
			border_alpha = 255
		},

		press = {
			border_alpha = 0
		},

		check = Element.New {
			layout = false,
			origin_position = true,
			origin_justification_x = JUSTIFY_CENTER,
			origin_justification_y = JUSTIFY_CENTER,
			position_justification_x = JUSTIFY_CENTER,
			position_justification_y = JUSTIFY_CENTER,
			width = BUTTON_ICON_SIZE,
			height = BUTTON_ICON_SIZE,
			material = hamburger_material,
		},
	})

	self.value = v
	self.original_value = v
	self.options = props.options

	self.original_values = {}
	self.changed_values = {}

	self.inputs = {}

	for _, k in pairs(props.options) do
		self.original_values[k] = v[k]
	end

	if props then
		self:SetAttributes(props)
		self.read_only = props.read_only
		self.on_change = props.on_change

		if props.read_only then
			self:Disable()
		end
	end
end

function ListSelector:Disable()
	self.disabled = true

	for _, input in pairs(self.inputs) do
		input:Disable()
	end
end

function ListSelector:Enable()
	self.disabled = false

	for _, input in pairs(self.inputs) do
		input:Enable()
	end
end

function ListSelector:Finish()
	if self.list then
		self:FinishList()
	end

	if ListSelector.focused == self then
		ListSelector.focused = nil
	end

	ListSelector.super.Finish(self)
end

function ListSelector:CreateList()
	local input_w = self:GetFinalWidth()
	local input_h = self:GetFinalHeight()
	local screen_x, screen_y = self.panel:LocalToScreen(input_w/2, input_h/2)

	self.list = Element.New {
		clamp_to_screen = true,
		origin_position = true,
		origin_x = screen_x,
		origin_y = screen_y,
		position_justification_x = JUSTIFY_CENTER,
		position_justification_y = JUSTIFY_CENTER,
		fit_y = true,
		width = COLUMN_WIDTH,
		padding_y = MARGIN * 2,
		background_color = COLOR_GRAY,
		alpha = 0,
		border = 2
	}

	self.list.panel:MakePopup()
	self.list.panel:SetKeyboardInputEnabled(false)

	ListSelector.focused = self

	for _, list_option in pairs(self.options) do
		self.inputs[list_option] = self.list:Add(InputBar.New(list_option, nil, self.value[list_option], {
			read_only = self.disabled,

			on_change = function (input, v)
				self:OnListValueChanged(list_option, v)
			end
		}))
	end

	self.list:AnimateAttribute("alpha", 255)
end

function ListSelector:FinishList()
	local old_list = self.list

	if old_list then
		old_list:AnimateAttribute("alpha", 0, {
			callback = function ()
				old_list:Finish()
			end
		})
		
		self.list = nil
		self.inputs = {}
	end
end

function ListSelector:OnListValueChanged(k, v)
	self:OnValueChanged(k, v)
end

function ListSelector.MousePressed(panel)
	if ListSelector.focused and ListSelector.focused.list and ListSelector.focused.list.panel:IsCursorOutBounds() then
		ListSelector.focused:FinishList()
		ListSelector.focused = nil
	end
end
hook.Add("VGUIMousePressed", "ListSelector.MousePressed", ListSelector.MousePressed)

function ListSelector:OnValueChanged(k, v, no_callback)
	if k then
		self.value[k] = v
	else
		self.value = v
	end

	if not no_callback and self.on_change then
		self.on_change(self, k, v)
	end
end

function ListSelector:OnMousePressed(mouse)
	ListSelector.super.OnMousePressed(self, mouse)

	if not self.list then
		self:CreateList()
	end
end

function ListSelector:SetValue(k, v, no_callback)
	if self.inputs[k] and v ~= self.inputs[k].value then
		self.inputs[k]:SetValue(v, no_callback)
		self:OnValueChanged(k, v, no_callback)
	elseif v ~= self.value[k] then
		self:OnValueChanged(k, v, no_callback)
	end
end
