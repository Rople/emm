TimeInput = TimeInput or Class.New(Element)

local TimeInputPanel = {}

local max_time_digits = 6
local padding_x = 4
local padding_y = 3

local function ZeroString(len)
	len = len or max_time_digits

	return string.format("%0"..len.."d", 0)
end

local function TimeString(seconds)
	local time = string.FormattedTime(tonumber(seconds))

	return string.format("%02d%02d%02d", time.h, time.m, time.s)
end

local function Seconds(text)
	local h, m, s = string.match(string.format("%06d", tonumber(text)), "(%d%d)(%d%d)(%d%d)")

	return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s)
end

function TimeInputPanel:Init()
	self:SetUpdateOnType(true)
	
	self.time = ""
	self.colons = ""
	self.time_with_colons = ""

	self.old_caret_pos = max_time_digits
	self.last_caret_pos_change = CurTime()
	self.digit_width = 0
	self.formatted_lookup = {}
	
	self:OffsetCaretPos()
end

function TimeInputPanel:AllowInput(string)
	local allowed

	local is_num = string.find(string, "%d")

	if is_num then
		allowed = true
	else
		allowed = false
	end

	return not allowed
end

function TimeInputPanel:FormatDigits(digits)
	local trimmed_digits = string.TrimLeft(digits, "0")
	local lookup_start = (self.non_zero_i or (max_time_digits + 1)) - 1
	local digits_len = #trimmed_digits

	local time
	local colons
	local time_with_colons

	if tonumber(digits) == 0 then
		time = ""
		colons = ""
		time_with_colons = ""
	elseif 2 >= digits_len then
		time = trimmed_digits
		colons = ""
		time_with_colons = trimmed_digits
	
		self.formatted_lookup = {[0] = lookup_start, lookup_start + 1, lookup_start + 2}
	else
		self.formatted_lookup = {
			[0] = lookup_start
		}

		if (digits_len % 2) ~= 0 then
			time = trimmed_digits[1]
			colons = " "

			table.insert(self.formatted_lookup, lookup_start + 1)
		else
			time = string.sub(trimmed_digits, 1, 2)
			colons = "  "

			table.insert(self.formatted_lookup, lookup_start + 1)
			table.insert(self.formatted_lookup, lookup_start + 2)
		end

		time_with_colons = time
		
		for i = #time + 1, digits_len, 2 do
			local next_i = i + 1
			local curr_digit = trimmed_digits[i]
			local next_digit = trimmed_digits[next_i]
			local pair = curr_digit..next_digit

			time = time.." "..pair
			colons = colons..":".."  "
			time_with_colons = time_with_colons..":"..pair

			table.insert(self.formatted_lookup, lookup_start + i - 1)
			table.insert(self.formatted_lookup, lookup_start + i)
			table.insert(self.formatted_lookup, lookup_start + next_i)
		end
	end

	self.time = time
	self.colons = colons
	self.time_with_colons = time_with_colons
end

function TimeInputPanel:OnValueChange(v)
	local text = tostring(v)
	local v_len = #text
	local caret_pos = self:GetCaretPos()
	
	if v_len > max_time_digits then
		local trim = max_time_digits - (v_len + 1)
		
		if self.non_zero_i == 1 and (max_time_digits + 1) > caret_pos then
			text = string.Left(v, trim)
		else
			text = string.Right(v, trim)
			caret_pos = caret_pos - 1
		end
	elseif max_time_digits > v_len then
		text = string.format("%06d", text)
		caret_pos = caret_pos + 1
	end

	self:SetText(text)
	self:OffsetCaretPos(caret_pos)
	self:FormatDigits(text)

	local sec = Seconds(text)

	self.seconds = sec
	self.element:OnValueChanged(sec)
end

function TimeInputPanel:ClampCaretPos(new_caret_pos)
	local caret_pos = new_caret_pos or self:GetCaretPos()

	self.non_zero_i = string.find(self:GetText(), "[^0]")

	if self.non_zero_i then
		caret_pos = math.max(caret_pos, self.non_zero_i - 1)
	else
		caret_pos = max_time_digits
	end

	self:SetCaretPos(caret_pos)
end

function TimeInputPanel:GenerateNewCaretPos()
	local caret_pos = self:GetCaretPos()
	local non_zero_i = self.non_zero_i or (max_time_digits + 1)
	local trimmed_caret_pos = caret_pos - non_zero_i + 1

	self.caret_pos_after_colon = trimmed_caret_pos

	if #self:GetText() > 2 then
		local offset_base

		if ((non_zero_i - 1) % 2) == 0 then
			offset_base = trimmed_caret_pos
		else
			offset_base = trimmed_caret_pos + 1
		end

		self.caret_pos_after_colon = trimmed_caret_pos + math.max(math.Round(offset_base/2) - 1, 0)
	end
end

function TimeInputPanel:OffsetCaretPos(new_caret_pos)
	self:ClampCaretPos(new_caret_pos)
	self:GenerateNewCaretPos()
end

function TimeInputPanel:PreventLetters()
	local text = self:GetText()

	if string.find(text, "[^%d]") then
		self:SetText(ZeroString())
		self.time = ""
		self.colons = ""
		self.time_with_colons = ""
	end
end

function TimeInputPanel:Think()
	self:PreventLetters()

	if self:HasFocus() then
		local caret_pos = self:GetCaretPos()

		if caret_pos ~= self.old_caret_pos then
			self:OffsetCaretPos()
			self.old_caret_pos = caret_pos
			self.last_caret_pos_change = CurTime()
		end
	else
		self:SetMouseInputEnabled(false)
	end
end

function TimeInputPanel:Paint(w, h)
	local attr = self.element.attributes
	local color = attr.text_color and attr.text_color.current or self.element:GetColor()

	surface.SetFont(self:GetFont())
	surface.SetTextColor(color)
	surface.SetTextPos(padding_x, padding_y)
	surface.DrawText(self.time)
	
	surface.SetTextColor(ColorAlpha(color, CombineAlphas(color.a, QUARTER_ALPHA) * 255))
	surface.SetTextPos(padding_x - 1, padding_y)
	surface.DrawText(self.colons)

	self.digit_width = surface.GetTextSize "0"

	surface.SetDrawColor(color)

	if self:HasFocus() and math.Round((CurTime() - self.last_caret_pos_change) % 1) == 0 then
		surface.DrawRect((self.digit_width * self.caret_pos_after_colon) + padding_x, 0, LINE_THICKNESS, h - padding_y)
	end
end

function TimeInputPanel:ManuallySetCaretPos()
	local x, _ = self:LocalCursorPos()
	local time_len = #self.time
	local corrected_caret_pos = self.formatted_lookup[math.Round(math.Clamp((x - padding_x)/(time_len * self.digit_width), 0, 1) * time_len)]

	self:OffsetCaretPos(corrected_caret_pos)
end

function TimeInputPanel:OnCursorEntered()
	self.element.panel:OnCursorEntered()
end

function TimeInputPanel:OnCursorExited()
	self.element.panel:OnCursorExited()
end

function TimeInputPanel:OnMousePressed(mouse)
	self.element.panel:OnMousePressed(mouse)
end

function TimeInputPanel:OnLoseFocus()
	self.element:OnUnFocus()
end

vgui.Register("TimeInputPanel", TimeInputPanel, "DTextEntry")

function TimeInput:Init(time, props)
	TimeInput.super.Init(self, {
		width_percent = 1,
		height_percent = 1,
		background_color = COLOR_GRAY_DARK,
		cursor = "beam",
		font = "NumberInfo",
		border = 2,
		border_alpha = 0,

		disabled = {
			background_color = COLOR_BLACK_CLEAR,
			border = 1,
			border_color = COLOR_GRAY_DARK,
			border_alpha = 255
		},
		
		hover = {
			border_alpha = 255
		},

		text_line = Element.New {
			overlay = true,
			layout = false,
			origin_position = true,
			origin_justification_x = JUSTIFY_CENTER,
			origin_justification_y = JUSTIFY_END,
			position_justification_x = JUSTIFY_CENTER,
			position_justification_y = JUSTIFY_END,
			width_percent = 1,
			height = LINE_THICKNESS,
			fill_color = true,
			alpha = 0
		}
	})

	
	self.panel.text = self.panel:Add(vgui.Create "TimeInputPanel")
	self.panel.text.element = self
	self.panel.text:SetFont(self:GetAttribute "font")
	
	local text = time and TimeString(time) or ZeroString()
	
	self.panel.text:SetText(text)
	self.panel.text:OffsetCaretPos(max_time_digits)
	self.panel.text:FormatDigits(text)
	self.value = time or 0

	if props then
		self:SetAttributes(props)
		self.read_only = props.read_only
		self.on_change = props.on_change
		self.on_click = props.on_click

		if props.read_only then
			self:Disable()
		end
	end
end

function TimeInput:Disable()
	TextInput.Disable(self)
end

function TimeInput:Enable()
	TextInput.Enable(self)
end

function TimeInput:Finish()
	if self.dragger then
		self.dragger:Finish()
	end

	self:OnUnFocus()

	TimeInput.super.Finish(self)
end

function TimeInput:OnValueChanged(v, no_callback)
	self.value = v

	if not no_callback and self.on_change then
		self.on_change(self, v)
	end
end

function TimeInput:SetValue(v, no_callback)
	v = TimeString(v)

	self.panel.text:SetText(v)
	self.panel.text:OnValueChange(v, no_callback)
end

function TimeInput:OnMousePressed(mouse)
	TimeInput.super.OnMousePressed(self, mouse)
	self.panel.text:ManuallySetCaretPos()
	
	if self.on_click then
		self.on_click(self, mouse)
	end
	
	self:OnFocus(self)
end

function TimeInput:OnMouseReleased(mouse)
	TimeInput.super.OnMouseReleased(self, mouse)
end

function TimeInput:OnMouseEntered()
	TextInput.OnMouseEntered(self)
end

function TimeInput:OnMouseExited()
	TextInput.OnMouseExited(self)
end

function TimeInput:OnFocus()
	self.panel.text:RequestFocus()
	
	hook.Run("TextEntryFocus", self)
	
	self.text_line:AnimateAttribute("alpha", 255)
end

function TimeInput:OnUnFocus()
	self.panel.text:SetKeyboardInputEnabled(false)
	
	hook.Run("TextEntryUnFocus", self)

	self.text_line:AnimateAttribute("alpha", 0)
end

function TimeInput:StartDragging()
	TimeInput.super.StartDragging(self)

	self:OnUnFocus()

	self.dragger = InputDragger.New(self, {
		default = self.value > 0 and {text = self.panel.text.time_with_colons, value = tonumber(self.panel.text:GetText())} or 500,

		text_generate = function (v)
			return NiceTime(Seconds(v))
		end,

		upper_range_step = 10000,
		upper_range_round = -4,

		options = {
			10000,
			4500,
			3000,
			2000,
			1500,
			1000,
			500,
			{text = "4:20", value = 420},
			200,
			100,
			45,
			30,
			15,
			10,
			5,
			3,
			1
		}
	})

	self.dragger:AnimateAttribute("alpha", 255)
	self.dragger.panel:MakePopup()
	self.dragger.panel:SetKeyboardInputEnabled(false)
end

function TimeInput:StopDragging()
	TimeInput.super.StopDragging(self)

	self:OnFocus()

	local v = self.dragger.generated_options[self.dragger.selected_option_index]

	if v then
		self.panel.text:SetValue(self.dragger.generated_options[self.dragger.selected_option_index])
		self.panel.text:OffsetCaretPos(max_time_digits)
	end

	self.dragger:Finish()
	self.dragger = nil
end