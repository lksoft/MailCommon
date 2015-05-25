#!/bin/sh

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
