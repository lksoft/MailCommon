#!/bin/sh

FREQUENCY=""
if [ "$#" == 3 ]; then
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
	
	SCRIPT_CONTENT="tell application \"MailPluginTool\" to $ACTION_PHRASE"
	
	/usr/bin/osascript -e "$SCRIPT_CONTENT"

else
	exit 2;
fi

exit 0;
