local Interface = {}
local Icons = require(script.Parent.Assets.Icons)
local AssetManager = require(script.Parent.Assets.Manager)

local DefaultFont = AssetManager.GetCustomFont("Inter")

local DefaultProperties = {
	["Frame"] = {
		BorderSizePixel = 0,
	},
	["ScrollingFrame"] = {
		BorderSizePixel = 0,
	},
	["ImageLabel"] = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	},
	["ImageButton"] = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	},

	["TextLabel"] = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = DefaultFont,
		RichText = true,
		TextColor3 = Color3.new(1, 1, 1),
	},
	["TextButton"] = {
		AutoButtonColor = false,
		BorderSizePixel = 0,
		FontFace = DefaultFont,
		RichText = true,
		TextColor3 = Color3.new(1, 1, 1),
	},
	["TextBox"] = {
		BorderSizePixel = 0,
		FontFace = DefaultFont,
		ClipsDescendants = true,
		RichText = false,
		TextColor3 = Color3.new(1, 1, 1),
	},

	["UIListLayout"] = {
		SortOrder = Enum.SortOrder.LayoutOrder,
	},
}

function Interface.New(ClassName: string, Properties: { [string | number]: any })
	local Object = Instance.new(ClassName)

	for Key, Value in pairs(DefaultProperties[ClassName] or {}) do
		if Properties and Properties[Key] ~= nil then
			continue
		end

		Object[Key] = Value
	end

	for Key, Value in pairs(Properties or {}) do
		if typeof(Value) == "table" then
			local SubObject = Interface.New(Key, Value)
			SubObject.Parent = Object

			continue
		elseif typeof(Key) ~= "string" and typeof(Value) == "Instance" then
			local SubObject = Value:Clone()
			SubObject.Parent = Object

			continue
		end

		Object[Key] = Value
	end

	return Object
end

local function CreateIcon(Icon: string, Button: boolean, Properties: { [string]: any }?): Icons.IconObject
	local ClassName = Icons.GetClassName(Icon, Button)
	local Resolved = {
		Name = "Icon",
		BackgroundTransparency = 1,
	}

	for Key, Value in Icons.ResolveProperties(ClassName, Properties or {}) do
		Resolved[Key] = Value
	end

	local Object = Interface.New(ClassName, Resolved)
	Icons.SetIcon(Object, Icon)

	return Object
end

function Interface.NewIcon(Icon: string, Properties: { [string]: any }?): Icons.IconObject
	return CreateIcon(Icon, false, Properties)
end

function Interface.NewIconButton(Icon: string, Properties: { [string]: any }?): Icons.IconObject
	return CreateIcon(Icon, true, Properties)
end

local CarriedIconProperties = {
	"Name",
	"AnchorPoint",
	"Position",
	"Size",
	"SizeConstraint",
	"AutomaticSize",
	"LayoutOrder",
	"ZIndex",
	"Rotation",
	"Visible",
	"Active",
	"BackgroundColor3",
	"BackgroundTransparency",
}

function Interface.SetIcon(Object: Icons.IconObject, Icon: string): Icons.IconObject
	if Icons.CanDisplay(Object, Icon) then
		Icons.SetIcon(Object, Icon)
		return Object
	end

	assert(not Object:IsA("GuiButton"), "Icon buttons cannot be replaced, use an icon inside of a button instead")

	local Properties = {
		IconColor3 = Icons.GetProperty(Object, "IconColor3"),
		IconTransparency = Icons.GetProperty(Object, "IconTransparency"),
	}
	for _, Property in CarriedIconProperties do
		Properties[Property] = (Object :: any)[Property]
	end

	local Replacement = Interface.NewIcon(Icon, Properties)
	for _, Child in Object:GetChildren() do
		Child.Parent = Replacement
	end

	Replacement.Parent = Object.Parent
	Object:Destroy()

	return Replacement
end

function Interface.GetScreenParent(): Instance
	local ScreenGui = Interface.New("ScreenGui", {})
	local HiddenUI = wax.shared.gethui()

	for _, Container in { HiddenUI, wax.shared.CoreGui } do
		if pcall(function()
			ScreenGui.Parent = Container
		end) then
			ScreenGui:Destroy()
			return Container
		end
	end

	return wax.shared.LocalPlayer:WaitForChild("PlayerGui")
end

return Interface
