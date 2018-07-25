-- # Tool class

ToolType = Class.New()

function ToolType:Init()
    self.description = "Base tool"
    self.Control = {} --Table of control functions
    self.icon_path = "materials/build/tool-icons/default.png"
    self.name = "base"
    self.show_name = "Base Tool"
end

function ToolType:Render()
end

function ToolType:OnMouseScroll(scroll_delta)
    local local_ply = LocalPlayer()
    local tool_distance = local_ply.tool_distance
    local_ply.tool_distance = math.Clamp(tool_distance+5*scroll_delta,0,10000)
    return true --Suppresses whatever the mousewheel is bound to
end

EMM.Include {
    "build/tools/no-tool",
    "build/tools/create-point"
}