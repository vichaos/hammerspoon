-- Initialize --
mash = {"⌘", "⌥", "⌃"}
hs.hotkey.bind(mash, "r", function() hs.reload(); end)
hs.alert("Hammerspoon config re-loaded")
hs.hotkey.bind(mash, "l", function() hs.caffeinate.lockScreen(); end)

-- Clipboards history --
function setUpClipboardTool()
  ClipboardTool = hs.loadSpoon('ClipboardTool')
  ClipboardTool.show_in_menubar = false
  ClipboardTool.show_copied_alert = false
  ClipboardTool.hist_size = 10
  ClipboardTool.max_size = false
  ClipboardTool.paste_on_select = true
  --- To avoid 1Password clipboard 
  ClipboardTool.honor_ignoredidentifiers = true
  ClipboardTool:start()
  ClipboardTool:bindHotkeys({
    toggle_clipboard = {mash, "v"}
  })
end
setUpClipboardTool()

-- Window Manager --
hs.loadSpoon("MiroWindowsManager")
spoon.MiroWindowsManager:bindHotkeys({
  up = {mash, "up"},
  right = {mash, "right"},
  down = {mash, "down"},
  left = {mash, "left"},
  fullscreen = {mash, "m"},
  nextscreen = {mash, "/"}
})
hs.window.animationDuration = 0.0


-- sfgcpw: APP SHORTCUT --
hs.application.enableSpotlightForNameSearches(true)
local function toggleApplication(name)
  local app = hs.application.find(name)
  if not app or app:isHidden() then
    hs.application.launchOrFocus(name)
  elseif hs.application.frontmostApplication() ~= app then
    app:activate()
  else
    app:hide()
  end
end
hs.hotkey.bind(mash, "s", function() toggleApplication("Safari Technology Preview") end)
hs.hotkey.bind(mash, "f", function() toggleApplication("Finder") end)
hs.hotkey.bind(mash, "g", function() toggleApplication("SourceTree") end)
hs.hotkey.bind(mash, "c", function() toggleApplication("Visual Studio Code.app") end)
hs.hotkey.bind(mash, "p", function() toggleApplication("System Preferences") end)
hs.hotkey.bind(mash, "w", function() toggleApplication("Safari Technology Preview");
                                     toggleApplication("zoom.us");
                                     toggleApplication("Pulse Secure");
                                     local windowLayout = {
                                          {"Safari Technology Preview", nil, laptopScreen, hs.layout.left50,nil, nil},
                                          {"zoom.us", nil, laptopScreen, hs.layout.right50, nil, nil},
                                          {"Pulse Secure", nil, laptopScreen, hs.layout.right50, nil, nil},
                                     }
                                     hs.layout.apply(windowLayout);
                                     end)

-- t: search and navigate to safari tabs --
getTabs = [[
on replaceString(theText, oldString, newString)
	-- From http://applescript.bratis-lover.net/library/string/#replaceString
	local ASTID, theText, oldString, newString, lst
	set ASTID to AppleScript's text item delimiters
	try
		considering case
			set AppleScript's text item delimiters to oldString
			set lst to every text item of theText
			set AppleScript's text item delimiters to newString
			set theText to lst as string
		end considering
		set AppleScript's text item delimiters to ASTID
		return theText
	on error eMsg number eNum
		set AppleScript's text item delimiters to ASTID
		error "Can't replaceString: " & eMsg number eNum
	end try
end replaceString
tell application "Safari Technology Preview"
	set tablist to "{"
	repeat with w in (every window whose visible is true)
		set ok to true
		try
			repeat with t in every tab of w
				set tabName to name of t
				set tabName to my replaceString(tabName, "'", "`")
				set tabId to index of t
				set wId to index of w
				set tablist to tablist & "'" & tabId & "': {'text': '" & tabName & "', 'wid': '" & wId & "'}, "
			end repeat
			set tablist to tablist & "}"
			return tablist
		on error errmsg
			display alert errmsg
			set ok to false
		end try
	end repeat
end tell
]]
function tabChooserCallback(input)
   hs.osascript.applescript("tell window " .. input.wid .. " of application \"Safari Technology Preview\" to set current tab to tab " .. input.id)
   hs.application.launchOrFocus("Safari Technology Preview")
end
function tabSwitcher()
  --  hs.alert("[⌘ ⌥ ⌃] + s")
   hs.application.launchOrFocus("Safari Technology Preview")
   print(hs.application.frontmostApplication():name())
   if hs.application.frontmostApplication():name() == "Safari Technology Preview" then
      local works, obj, tabs = hs.osascript._osascript(getTabs, "AppleScript")
      local tabs = obj:gsub("'", "\"")
      print(tabs)
      local tabTable = hs.json.decode(tabs)
      local ordered_keys = {}

      for k in pairs(tabTable) do
	 table.insert(ordered_keys, tonumber(k))
      end
      table.sort(ordered_keys)
      local chooserTable = {}
      for i = 1, #ordered_keys do
	 local k, v = ordered_keys[i], tabTable[ tostring(ordered_keys[i]) ]
	 table.insert(chooserTable, {["text"] = v['text'], ["id"] = k, ["wid"] = v['wid']})
      end
      local chooser = hs.chooser.new(tabChooserCallback)
      chooser:choices(chooserTable)
      chooser:show()
   end
end 
hs.hotkey.bind(mash, "s", tabSwitcher)


-- Add "NoZz" trigger on titlebar  --
caffeine = hs.menubar.new()
function setCaffeineDisplay(state)
    if state then
        caffeine:setTitle("NoZz")
    else
        caffeine:setTitle("Zz")
    end
end
function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end
if caffeine then
    caffeine:setClickCallback(caffeineClicked)
    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end

