#!/bin/sh

logFolder="$HOME/Library/Containers/com.apple.mail/Data/Library/Logs/Mail"
logFolder="$HOME/Downloads/log"
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


if [ "$ACTION" == "-debug" ]; then
	MY_DIR=`dirname "$0"`
	/usr/bin/osascript "$MY_DIR/GetCompleteDebugInfo.applescript" "$2" "$3"
	exit 0;
fi



# Test for SPARKLE action
logger -s -t $logName "Script called for action: '$ACTION'" 2>> $currentLogFile
if [ "$ACTION" == "SPARKLE" ]; then
	sparkleHelper="$2"
	logger -s -t $logName "Doing Sparkle – arguments are '$@'" 2>> $currentLogFile
	if [ "$3" == "quit" ]; then
		logger -s -t $logName "Trying to quit $sparkleHelper with pkill" 2>> $currentLogFile
		currentUser=$(whoami)
		pkill -U $currentUser -x $sparkleHelper
	elif [ -d "$sparkleHelper" ]; then
		logger -s -t $logName "Trying to open $sparkleHelper" 2>> $currentLogFile
		open "$sparkleHelper" --args "${@:3}"
	else
		logger -s -t $logName "Could Not find Sparkle Helper App at $sparklePath" 2>> $currentLogFile
	fi
	exit 0
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
