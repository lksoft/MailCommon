on run (argv)
	
	set subjectString to ""
	set bodyStart to ""
	
	if ((count of argv) > 0) then
		set subjectString to item 1 of argv
		if ((count of argv) > 1) then
			set bodyStart to (item 2 of argv)
		end if
	end if
	
	set lksPluginList to {"SignatureProfiler", "Sidebar For Infusionsoft", "Tealeaves"}
	set pluginDefaultOne to "LKSBuildBranch"
	set pluginDefaultTwo to "LKSBuildSHA"
	set supportName to "Little Known Support"
	set supportEmail to "support@littleknownsoftware.com"
	set homeFolder to do shell script "cd ~;pwd"
	
	--	Determine the plugins available
	set bundlePath to homeFolder & "/Library/Mail/Bundles"
	set myPluginList to {}
	try
		set bundleAlias to POSIX file bundlePath as alias
		tell application "System Events"
			set bundleItems to the name of every disk item of bundleAlias
		end tell
		repeat with foundBundle in bundleItems
			repeat with aPluginName in lksPluginList
				if (foundBundle starts with aPluginName) then
					set myPluginList to myPluginList & aPluginName
				end if
			end repeat
		end repeat
	on error err
		log err
	end try
	
	log myPluginList
	
	set msgContent to bodyStart & return & return & "Here is the version information that you requesting for support purposes." & return & "=========================================================" & return & return
	set mailIsRunning to false
	
	tell application "System Events"
		if (count of (processes whose name is "Mail")) > 0 then
			set msgContent to msgContent & "Mail is currently running" & return & return
			set mailIsRunning to true
		else
			set msgContent to msgContent & "Mail is not open" & return & return
		end if
	end tell
	
	set mailUUID to do shell script "defaults read /Applications/Mail.app/Contents/Info PluginCompatibilityUUID"
	set mailBuild to do shell script "defaults read /Applications/Mail.app/Contents/Info CFBundleVersion"
	
	set mailVersion to do shell script "defaults read /Applications/Mail.app/Contents/Info CFBundleShortVersionString"
	
	-- Build out the main version info
	set msgContent to msgContent & "Mail Version: " & mailVersion & "(" & mailBuild & ") UUID: " & mailUUID & return
	
	--	Add the list of plugins installed
	set msgContent to msgContent & return & "Installed Plugins:" & return & "====================" & return
	try
		set pluginList to do shell script ("cd " & homeFolder & "/Library/Mail/Bundles;ls -nod *.mailbundle")
		set msgContent to msgContent & return & "User Plugins:" & return & pluginList & return
	on error err
		set msgContent to msgContent & return & "**NONE**" & return
	end try
	
	set localPluginPath to "/Library/Mail/Bundles"
	set msgContent to msgContent & return & "Local Plugins:"
	try
		set test to POSIX file localPluginPath as alias
		set pluginList to do shell script ("cd /Library/Mail/Bundles;ls -nod *.mailbundle")
		set msgContent to msgContent & return & pluginList & return
	on error err
		set msgContent to msgContent & return & "**NONE**" & return
	end try
	
	set msgContent to msgContent & return & "Disabled Plugins:" & return & "====================" & return
	set msgContent to msgContent & return & "User Plugins:"
	set userMailPath to homeFolder & "/Library/Mail"
	try
		set test to POSIX file userMailPath as alias
		set localContent to ""
		tell application "System Events"
			set folderContents to every item of folder userMailPath
			repeat with anItem in folderContents
				if (name of anItem starts with "Bundles (Disabl") then
					set pluginList to do shell script ("cd \"" & POSIX path of anItem & "\";ls -nod *.mailbundle")
					set localContent to localContent & pluginList & return
				end if
			end repeat
		end tell
		if (localContent is "") then
			set localContent to "**NONE**" & return
		end if
		set msgContent to msgContent & return & localContent
	on error err
		set msgContent to msgContent & return & "**NONE**" & return
	end try
	
	set msgContent to msgContent & return & "Local Plugins:"
	set localMailPath to "/Library/Mail"
	try
		set test to POSIX file localMailPath as alias
		set localContent to ""
		tell application "System Events"
			set folderContents to every item of folder localMailPath
			repeat with anItem in folderContents
				if (name of anItem starts with "Bundles (Disabl") then
					set pluginList to do shell script ("cd \"" & POSIX path of anItem & "\";ls -nod *.mailbundle")
					set localContent to localContent & pluginList & return
				end if
			end repeat
		end tell
		if (localContent is "") then
			set localContent to "**NONE**" & return
		end if
		set msgContent to msgContent & return & localContent
	on error err
		set msgContent to msgContent & return & "**NONE**" & return
	end try
	
	set msgContent to msgContent & return & "Preferences:" & return & "====================" & return
	
	--	Then try to determine the status of LaunchAgents and preferences
	try
		set prefInfo to do shell script ("cd " & homeFolder & "/Library/Preferences;ls -no com.littleknownsoftware.*")
		set msgContent to msgContent & return & "Library Prefs Files:" & return & prefInfo & return
	on error err
		set msgContent to msgContent & return & "**NO** Library Prefs Files" & return
	end try
	
	set sandboxedPrefsFolder to homeFolder & "/Library/Containers/com.apple.mail/Data/Library/Preferences"
	try
		set test to POSIX file sandboxedPrefsFolder as alias
		set prefInfo to do shell script ("cd " & homeFolder & "/Library/Containers/com.apple.mail/Data/Library/Preferences;ls -no com.littleknownsoftware.*")
		set msgContent to msgContent & return & "Container Prefs Files:" & return & prefInfo & return
	on error err
		set msgContent to msgContent & return & "**NO** Container Prefs Files" & return
	end try
	
	set msgContent to msgContent & return & "Other Info:" & return & "====================" & return
	
	set msgContent to msgContent & return & "Mail Scripts:"
	set mailScriptPath to homeFolder & "/Library/Application Scripts/com.apple.mail/LKS"
	try
		set test to POSIX file mailScriptPath as alias
		set pluginList to do shell script ("cd \"" & mailScriptPath & "\";ls -no *")
		set msgContent to msgContent & return & pluginList & return
	on error err
		set msgContent to msgContent & return & "**NONE**" & return
	end try
	
	set managerPlistPath to "/Applications/Mail Plugin Manager.app/Contents"
	set pluginManagerInstalled to false
	try
		set test to POSIX file managerPlistPath as alias
		set pluginManagerInstalled to true
	on error err
		log err
		-- do nothing
	end try
	
	--	Only bother with all of this part if the plugin is where we expect it
	if (pluginManagerInstalled is true) then
		
		--	Then look at the launch agent side
		try
			set launchdInfo to do shell script ("cd " & homeFolder & "/Library/LaunchAgents;ls -no com.littleknownsoftware.*")
			set msgContent to msgContent & return & "Launch Agent Files:" & return & launchdInfo & return
		on error err
			set msgContent to msgContent & return & "**NO** Launch Agent Files" & return
		end try
		set launchdInfo1 to tab & "**None**"
		set launchdInfo2 to tab & "**None**"
		try
			set launchdInfo1 to do shell script ("launchctl list | grep com.littleknownsoftware")
			set launchdInfo2 to do shell script ("launchctl list com.littleknownsoftware.MailPluginTool-Watcher")
		on error myErr
		end try
		set msgContent to msgContent & return & "Running Launch Agents:" & return & launchdInfo1 & return
		set msgContent to msgContent & return & "MailPlugin LaunchAgent:" & return & launchdInfo2 & return
		
		set managerPlistPath to quote & managerPlistPath & "/Info" & quote
		set pluginBuild to do shell script "defaults read " & managerPlistPath & " CFBundleVersion"
		set pluginVersion to do shell script "defaults read " & managerPlistPath & " CFBundleShortVersionString"
		set msgContent to msgContent & return & "Plugin Manager Version: " & pluginVersion & "(" & pluginBuild & ")" & return
		
		if (pluginDefaultOne is not "") then
			set pluginDefault1Value to do shell script "defaults read " & managerPlistPath & " " & "\"" & pluginDefaultOne & "\""
			set pluginDefault2Value to do shell script "defaults read " & managerPlistPath & " " & "\"" & pluginDefaultTwo & "\""
			set msgContent to msgContent & return & "Plugin Manager Extra Info: " & pluginDefault1Value & "  --  " & pluginDefault2Value & return
		end if
	else
		set msgContent to msgContent & return & "Plugin Manager cannot be found!" & return
	end if
	
	
	set msgContent to msgContent & return & return & "Little Known Plugins:" & return & "====================" & return
	
	--	Loop for each plugin
	repeat with pluginName in myPluginList
		
		--	Ensure that the plugin is installed
		set pluginPath to homeFolder & "/Library/Mail/Bundles/" & pluginName & ".mailbundle/Contents"
		set pluginInstalled to false
		try
			set test to POSIX file pluginPath as alias
			set pluginInstalled to true
		on error err
			log err
			-- do nothing
		end try
		
		log pluginPath
		
		set pluginPath to quote & pluginPath & "/Info" & quote
		
		--	Add header for this plugin	
		set msgContent to msgContent & return & "**** " & pluginName & " INFORMATION ****" & return
		
		--	Only bother with all of this part if the plugin is where we expect it
		if (pluginInstalled is true) then
			-- Try to see if we should get the version of the plugin
			if (pluginPath is not "") then
				set pluginBuild to do shell script "defaults read " & pluginPath & " CFBundleVersion"
				set pluginVersion to do shell script "defaults read " & pluginPath & " CFBundleShortVersionString"
				set pluginKeys to do shell script "defaults read " & pluginPath & " SupportedPluginCompatibilityUUIDs"
				set msgContent to msgContent & return & "Plugin Version: " & pluginVersion & "(" & pluginBuild & ")" & return
				set msgContent to msgContent & return & "Plugin UUID List: " & pluginKeys & return
			end if
			
			if (pluginDefaultOne is not "") then
				set pluginDefault1Value to do shell script "defaults read " & pluginPath & " " & "\"" & pluginDefaultOne & "\""
				set pluginDefault2Value to do shell script "defaults read " & pluginPath & " " & "\"" & pluginDefaultTwo & "\""
				set msgContent to msgContent & return & "Plugin Extra Info: " & pluginDefault1Value & "  --  " & pluginDefault2Value & return
			end if
		else
			set msgContent to msgContent & return & "There is no plugin installed" & return
		end if
		
	end repeat
	
	--	If there were no plugins found add that to the message and set a valid value for the subject
	set pluginCount to (count of myPluginList)
	if (pluginCount is 0) then
		set msgContent to msgContent & return & "There are no LKS plugins installed" & return
	end if
	if (pluginCount is not 1) then
		set pluginName to "LKS Mail Bundles"
	end if
	
	
	--	See if there are any crash reports to send us
	set localCrashPath to homeFolder & "/Library/Logs/DiagnosticReports"
	set attachmentList to {}
	set found to false
	try
		set reportPathAlias to POSIX file localCrashPath as alias
		tell application "System Events"
			set crashLogList to the name of every disk item of reportPathAlias
		end tell
		repeat with crashLog in crashLogList
			if (crashLog starts with "Mail_") or (crashLog starts with "Mail Plugin Manager_") or (crashLog starts with "LoadFileHelper_") then
				set attachmentList to attachmentList & ((reportPathAlias as string) & crashLog as alias)
				set found to true
			end if
		end repeat
	on error err
		log err
	end try
	
	--	See if there are any log files to send
	set localLogPath to homeFolder & "/Library/Containers/com.apple.mail/Data/Library/Logs/Mail"
	try
		set reportPathAlias to POSIX file localLogPath as alias
		tell application "System Events"
			set logFileList to the name of every disk item of reportPathAlias
		end tell
		repeat with logFile in logFileList
			if (logFile ends with "log") then
				repeat with pluginName in lksPluginList
					if (logFile contains pluginName) then
						set attachmentList to attachmentList & ((reportPathAlias as string) & logFile as alias)
						set found to true
					end if
				end repeat
			end if
		end repeat
	on error err
		log err
	end try
	
	if found then
		set msgContent to msgContent & return & "Possibly Relevant Crash Reports or Log Files:" & return & "======================================" & return & return
	else
		set msgContent to msgContent & return & "There are no relevant Crash Reports or Log Files" & return
	end if
	
	
	tell application "Mail"
		activate
		if not mailIsRunning then
			delay 5
		end if
		set theNewMessage to make new outgoing message with properties {subject:subjectString, content:msgContent, visible:true}
		tell theNewMessage
			make new to recipient at end of to recipients with properties {name:supportName, address:supportEmail}
			repeat with attachmentLog in attachmentList
				make new attachment with properties {file name:attachmentLog} at after last paragraph
			end repeat
		end tell
	end tell
	
end run