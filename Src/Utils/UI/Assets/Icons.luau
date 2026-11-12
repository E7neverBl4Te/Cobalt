local Icons = {}
local AssetManager = require("@src/Utils/UI/Assets/Manager")

type SpriteIcon = {
	Url: string,
	IconName: string,
	ImageRectOffset: Vector2,
	ImageRectSize: Vector2,
}

type FontIcon = {
	FontFace: Font,
	Text: string,
}

type LucideModule = {
	Icons: { string },
	GetAsset: (Name: string) -> SpriteIcon?,
	GetFontAsset: ((Name: string) -> FontIcon?)?,
}

export type IconObject = TextLabel | TextButton | ImageLabel | ImageButton

local Success, Lucide: LucideModule = pcall(function()
	local IconFetchSuccess, IconModuleSource = pcall(request, {
		Url = "https://raw.githubusercontent.com/notpoiu/lucide-roblox-direct/refs/heads/main/source.lua",
		Method = "GET",
	})

	assert(
		IconFetchSuccess and IconModuleSource.Success
			or IconModuleSource.StatusCode >= 200 and IconModuleSource.StatusCode < 300,
		"Failed to fetch lucide icons direct module source"
	)
	return (loadstring(IconModuleSource.Body) :: () -> LucideModule)()
end)

--// Icon Font \\--
local FontFace: Font? = nil

if Success and typeof(Lucide.GetFontAsset) == "function" then
	pcall(function()
		local FontIcon = (Lucide.GetFontAsset :: (Name: string) -> FontIcon?)("circle-alert")
		assert(FontIcon, "Failed to load lucide icon font")

		local TextSize = 16
		local Width = wax.shared.GetTextBounds(FontIcon.Text, FontIcon.FontFace, TextSize)
		assert(math.abs(Width - TextSize) < 1, "Lucide icon font failed to render")

		FontFace = FontIcon.FontFace
	end)
end

--// Helpers \\--
local IconMappings = {
	Glyph = {
		ClassNames = {
			Label = "TextLabel",
			Button = "TextButton",
		},
		Properties = {
			IconColor3 = "TextColor3",
			IconTransparency = "TextTransparency",
		},
	},
	
	Image = {
		ClassNames = {
			Label = "ImageLabel",
			Button = "ImageButton",
		},
		Properties = {
			IconColor3 = "ImageColor3",
			IconTransparency = "ImageTransparency",
		},
	}
}
do
	local ClassKinds = {}
	for Kind, Mapping in IconMappings do
		for _, ClassName in Mapping.ClassNames do
			ClassKinds[ClassName] = Kind
		end
	end
	
	IconMappings.ClassKinds = ClassKinds
	Icons.IconMappings = IconMappings
end

function Icons.GetIconData(Icon: string)
	local MappingKey = (
		(FontFace and table.find(Lucide.Icons, Icon))
			and "Glyph"
			or "Image"
	)
	local Mapping = IconMappings[MappingKey]

	return MappingKey, Mapping
end

function Icons.GetClassName(Icon: string, Button: boolean?): string
	local _, Mapping = Icons.GetIconData(Icon)
	return Mapping.ClassNames[if Button then "Button" else "Label"]
end

function Icons.CanDisplay(Object: IconObject, Icon: string): boolean
	return IconMappings.ClassKinds[Object.ClassName] == Icons.GetIconData(Icon)
end

function Icons.GetProperty(Object: Instance, Property: string): any
	local ObjectKind = IconMappings.ClassKinds[Object.ClassName]
	local PropertyToGet = IconMappings[ObjectKind].Properties[Property] or Property
	return Object[PropertyToGet]
end

function Icons.ResolveProperties(ClassName: string, Properties: { [string]: any }): { [string]: any }
	local Mapping = IconMappings[IconMappings.ClassKinds[ClassName]].Properties
	local Resolved = {}

	for Property, Value in Properties do
		Resolved[Mapping[Property] or Property] = Value
	end

	return Resolved
end

function Icons.SetProperties(Object: Instance, Properties: { [string]: any })
	for Key, Value in Icons.ResolveProperties(Object.ClassName, Properties) do
		Object[Key] = Value
	end
end

function Icons.GetSpriteIcon(IconName: string): SpriteIcon?
	if not Success then
		return
	end

	local Fetched, Icon = pcall(Lucide.GetAsset, IconName)
	if not Fetched then
		return
	end

	return Icon
end

function Icons.SetIcon(Object: IconObject, Icon: string)
	local IconKind = Icons.IconMappings.ClassKinds[Object.ClassName]
	assert(IconKind, `{Object.ClassName} cannot display icon "{Icon}"`)

	if IconKind == "Glyph" then
		local Glyph = Object
		Glyph.FontFace = FontFace :: Font
		Glyph.RichText = false
		Glyph.TextScaled = true
		Glyph.Text = Icon
		return
	end

	local Image = Object :: ImageLabel
	if AssetManager.IsAsset(Icon) then
		Image.Image = Icon
		Image.ImageRectOffset = Vector2.zero
		Image.ImageRectSize = Vector2.zero
		return
	end

	local Sprite = Icons.GetSpriteIcon(Icon)
	if not Sprite then
		return
	end

	Image.Image = Sprite.Url
	Image.ImageRectOffset = Sprite.ImageRectOffset
	Image.ImageRectSize = Sprite.ImageRectSize
end

return Icons
