#! /bin/bash
# in Jamf, pass your SSID and Passwd as parameters 4 and 5

ssid=$4
pwd=$5

# check the current network...
current=$( networksetup -getairportnetwork en0 | grep "$ssid")

# if you're not currently connected to your expected network.......
if [[ $current=="" ]]

	# Look for the expected wifi...
	output=$( /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | grep "$ssid" )

	# if the output of the command isn't blank....
	if [[ $output!="" ]]; then

		# Force a client to use the expected wifi network.
		networksetup -removeallpreferredwirelessnetworks en0
		networksetup -setairportnetwork en0 $ssid $pwd

	fi
fi
