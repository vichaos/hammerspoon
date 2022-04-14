-- Initialize --
mash = {"⌘", "⌥", "⌃"}
hs.hotkey.bind(mash, "r", function() hs.reload(); end)
hs.alert("Hammerspoon config loaded")
hs.hotkey.bind(mash, "a", function() hs.caffeinate.lockScreen(); end)


-- Window Manager --
-- hs.loadSpoon("ShiftIt")
-- spoon.ShiftIt:bindHotkeys({})
hs.window.animationDuration = 0.0
--- default grid
hs.grid.setGrid('2x1')
hs.grid.setMargins("0,0")
function getWin()
  return hs.window.focusedWindow()
end
--- arrows: move window
hs.hotkey.bind(mash, "left", function() hs.grid.pushWindowLeft() end)
hs.hotkey.bind(mash, "right", function() hs.grid.pushWindowRight() end)
hs.hotkey.bind(mash, "up", function() hs.grid.pushWindowUp() end)
hs.hotkey.bind(mash, "down", function() hs.grid.pushWindowDown() end)
--- ikjl-+: resize window
hs.hotkey.bind(mash, "i", function() hs.grid.resizeWindowShorter() end)
hs.hotkey.bind(mash, "j", function() hs.grid.resizeWindowThinner() end)
hs.hotkey.bind(mash, "k", function() hs.grid.resizeWindowTaller() end)
hs.hotkey.bind(mash, "l", function() hs.grid.resizeWindowWider() end)
hs.hotkey.bind(mash, "-", function() hs.grid.resizeWindowShorter(); hs.grid.resizeWindowThinner() end)
hs.hotkey.bind(mash, "=", function() hs.grid.resizeWindowTaller();hs.grid.resizeWindowWider() end)
--- 12340: resize grid
hs.hotkey.bind(mash, "1", function() hs.grid.setGrid('2x1'); hs.alert.show('Grid set to 2x1'); end)
hs.hotkey.bind(mash, "2", function() hs.grid.setGrid('2x2'); hs.alert.show('Grid set to 2x2'); end)
hs.hotkey.bind(mash, "3", function() hs.grid.setGrid('3x3'); hs.alert.show('Grid set to 3x3'); end)
hs.hotkey.bind(mash, "4", function() hs.grid.setGrid('4x4'); hs.alert.show('Grid set to 4x4'); end)
hs.hotkey.bind(mash, "0", function() hs.grid.setGrid('10x10'); hs.alert.show('Grid set to 10x10'); end)
--- ,: minimize window
hs.hotkey.bind(mash, ",", function() hs.grid.set(getWin(), '0,0 1x1'); end)
--- m: maximize window
hs.hotkey.bind(mash, "m", function() hs.grid.maximizeWindow() end)
--- /: move window to next screen
hs.hotkey.bind(mash, "/", function() local win = getWin(); win:moveToScreen(win:screen():next()) end)
--- .: snap window to grid
hs.hotkey.bind(mash, ".", function() hs.grid.snap(getWin()) end)

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

-- t: search safari tab --
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

