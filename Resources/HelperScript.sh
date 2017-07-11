#!/bin/sh

logFolder="$HOME/Library/Containers/com.apple.mail/Data/Library/Logs/Mail"
logName="HelperScript"
logFile="com.littleknownsoftware.$logName.log"
currentLogFile="$logFolder/$logFile"

if [ -e $currentLogFile ]; then
	fileSize=`stat -f%z "$currentLogFile"`
	if [ $fileSize -gt 900000 ]; then
		backupLogFile="$logFolder/com.littleknownsoftware.$logName-Previous.log"
		if [ -e $backupLogFile ]; then
			rm $backupLogFile
		fi
		mv $currentLogFile $backupLogFile
		touch $currentLogFile
	fi
else
	touch $currentLogFile
fi

logger -s -t $logName " " 2>> $currentLogFile
logger -s -t $logName "Called with arguments: '$@'" 2>> $currentLogFile


UpdateLoadFileHelper() {
	logger -s -t $logName "Trying to update helper app" 2>> $currentLogFile
	srcHelperPath="$1"
	destHelperPath="$2"
	logger -s -t $logName "Source Path is: '$srcHelperPath'" 2>> $currentLogFile
	logger -s -t $logName "Destination Path is: '$destHelperPath'" 2>> $currentLogFile
    if [ -d "$destHelperPath" ]; then
		logger -s -t $logName "Updating LoadFileHelper" 2>> $currentLogFile
        existingVersion=`defaults read "${destHelperPath}/Contents/Info.plist" CFBundleVersion`
        bundleVersion=`defaults read "${srcHelperPath}/Contents/Info.plist" CFBundleVersion`
		logger -s -t $logName "ExistingVersion ${existingVersion}  bundleVersion: ${bundleVersion}" 2>> $currentLogFile
        if [ $existingVersion != $bundleVersion ]; then
            debugLog "Replacing existing version $existingVersion with bundle version $bundleVersion"
            rm -Rf "$destHelperPath"
            cp -R "$srcHelperPath" "$destHelperPath"
        fi
    else
	    # helper App is missing from Application Support
		logger -s -t $logName "Copying LoadFileHelper" 2>> $currentLogFile
        cp -R "$srcHelperPath" "$destHelperPath"
    fi
}


toolType="$1"
currentUser=$(whoami)

# Test for debugging info
if [[ "${toolType}" == "-debug" ]]; then
	MY_DIR=`dirname "$0"`
	/usr/bin/osascript "${MY_DIR}/GetCompleteDebugInfo.applescript" "${@:2}"
	exit 0;
fi


# Test for Mail
if [[ "${toolType}" == "-mail" ]]; then
	logger -s -t $logName "Relaunching Mail" 2>> $currentLogFile
	/usr/bin/osascript -e "tell application \"Mail\" to quit"
	sleep 1
	pkill -U "${currentUser}" -x "Mail"
	sleep 1
	open -b com.apple.mail
	exit 0
fi

command="$2"

# Test for SPARKLE action
if [[ "${toolType}" == "-sparkle" ]]; then
	sparkleHelper="$3"
	logger -s -t $logName "Doing Sparkle" 2>> $currentLogFile
	if [ "${command}" == "quit" ]; then
		logger -s -t $logName "Trying to quit ${sparkleHelper} with pkill" 2>> $currentLogFile
		pkill -U "${currentUser}" -x "${sparkleHelper}"
	elif [ -d "${sparkleHelper}" ]; then
		logger -s -t $logName "Trying to open ${sparkleHelper}" 2>> $currentLogFile
		open "${sparkleHelper}" --args "${@:4}"
	else
		logger -s -t $logName "Could Not find Sparkle Helper App at ${sparkleHelper}" 2>> $currentLogFile
	fi
	exit 0
fi

# Test for LoadFile actions
if [[ "${toolType}" == "-loadfile" ]]; then
	if [[ "${command}" == "script-result" ]]; then
		scriptPath="$3"
		isApplescript=false
		scriptExtension=`echo "$scriptPath" | sed 's/.*\.//'`
		if [[ "$scriptExtension" == "scpt" || "$scriptExtension" == "applescript" ]]; then
			isApplescript=true
		fi

		logger -s -t $logName "  Running a script '$scriptPath'" 2>> $currentLogFile
		logger -s -t $logName "  ...with Arguments '${@:5}'" 2>> $currentLogFile
		if [ $isApplescript == true ]; then
			/usr/bin/osascript "$scriptPath" "${@:5}" > "$4"
		else
			"$scriptPath" "${@:5}" > "$4"
		fi
	
		exit 0
	fi


	currentUser=$(whoami)
	loadFileProcess=$(pgrep -U $currentUser -x LoadFileHelper)
	logger -s -t $logName "LoadFileHelper process ID is $loadFileProcess." 2>> $currentLogFile
	if [[ "$loadFileProcess" == "" ]]; then
		logger -s -t $logName "LoadFileHelper is not running yet." 2>> $currentLogFile
		if [[ "${command}" == "start" ]]; then
			SRC_PATH="$3/Contents/Resources/LoadFileHelper.app"
			DEST_PATH="${HOME}/Library/Application Support/LKS"
			DEST_FILE_PATH="${DEST_PATH}/LoadFileHelper.app"
			if [ ! -d "$DEST_PATH" ]; then
				logger -s -t $logName "Creating the LKS App Support folder." 2>> $currentLogFile
				mkdir "$DEST_PATH"
			fi
			UpdateLoadFileHelper "$SRC_PATH" "$DEST_FILE_PATH"
			logger -s -t $logName "Trying to launch with Path: $DEST_FILE_PATH" 2>> $currentLogFile
			open -g "$DEST_FILE_PATH"
		fi
	else
		logger -s -t $logName "LoadFileHelper is already running $loadFileProcess." 2>> $currentLogFile
		if [[ "${command}" == "quit" ]]; then
			logger -s -t $logName "Trying to quit LoadFileHelper using pkill" 2>> $currentLogFile
			pkill -U $currentUser -x LoadFileHelper
		fi
	fi

	exit 0
fi


# Assume older formats
FREQUENCY=""
BETA=""
if [ "$#" -gt 3 ]; then
	if [ "$4" == "beta" ]; then
		BETA="with beta"
	fi
fi
if [ "$#" -gt 2 ]; then
	FREQUENCY="frequency $3"
fi
if [ "$#" -gt 1 ]; then
	ACTION="$1"
	BUNDLE_PATH="$2"
else
	exit 1;
fi

# Test to see if the bundle path is valid
if [[ -d "$BUNDLE_PATH" ]]; then

	case "$ACTION" in
		"-update") ACTION_PHRASE="update \"$BUNDLE_PATH\" $FREQUENCY"
		;;
		"-update-and-crash-reports") ACTION_PHRASE="update and crash reports \"$BUNDLE_PATH\" $FREQUENCY"
		;;
		"-uninstall") ACTION_PHRASE="uninstall \"$BUNDLE_PATH\""
		;;
	esac
	
	logger -s -t $logName "Doing MailPluginTool action phrase 'ACTION_PHRASE'" 2>> $currentLogFile
	TOOL_PATH="$BUNDLE_PATH/Contents/Resources/MailPluginTool.app"
	if [[ ! -d "$TOOL_PATH" ]]; then
		TOOL_PATH="/Applications/Mail Plugin Manager.app/Contents/Resources/MailPluginTool.app"
	fi
	
	# For development purposes only, should not ever be used in real life
	#TOOL_PATH="$HOME/Library/Developer/Xcode/DerivedData/MailPluginManager-awzptkybbxtathdbrfwrddbxaebv/Build/Products/Debug/MailPluginTool.app"
	
	if [[ ! -d "$TOOL_PATH" ]]; then
		exit 3;
	fi
	
	SCRIPT_CONTENT="tell application \"$TOOL_PATH\" to $ACTION_PHRASE $BETA"
	
	/usr/bin/osascript -e "$SCRIPT_CONTENT"

else
	exit 2;
fi

exit 0;
