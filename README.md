# AppleADBindWorkAround
Work Around for Apple OSX bug with losing Active Directory binding

This script can be pushed out to clients using Jamf Pro.  If you want email functionality apply the writeSMTPConfig.sh once per machine.
I have the fixADConfig.sh policy set to execute on each checkin with my Jamf server.  

Additionally, added a script to run periodically to force particular clients to use the Wifi that they are supposed to, even when end users want to connect to the wrong wifi!

## references
This is my adaptation of script written by @cddwyer on jamfnation forums:
https://www.jamf.com/jamf-nation/discussions/25234/command-line-to-check-for-ad-bind
