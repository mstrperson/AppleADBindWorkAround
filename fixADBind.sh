#!/bin/bash

computer=$( hostname )

# Drop the .local from the end that mac os tags on sometimes...
computer=${computer%".local"}

# Unlike windows, dsconfigad limits computer names to 15 characters...
adSafeName=$( echo $computer | cut 1-15 )

#ping the Domain or DC
ping -c 3 -o <DC_IP_Addr> 1> /dev/null 2> /dev/null

# If the ping was successful
if [[ $? == 0 ]]; then
    # Check the domain returned with dsconfigad
    domain=$( dsconfigad -show | awk '/Active Directory Domain/{print $NF}' )
    # If the domain is correct
    if [[ "$domain" == "yourdomain.com" ]]; then
	
        # Check the id of a service account
        id -u <some_valid_user> 
		
        # If the check was successful...
        if [[ $? == 0 ]]; then
            # All is well!  nothing to do!
            exit 0
        else
            # If the check failed
            #echo "<result>Cannot communicate with AD</result>"

            # Force Rebind
			# -- First remove the corrupted trust relationship.
            dsconfigad -force -remove -u jabber -p yepyepyep
			
			# -- Then attempt to rebind the mac to the domain (this command **does NOT** default to mobile accounts!) p.s.  a quick google search will give you the additional flags you need for that.
            response=$( dsconfigad -a $adSafeName -u <ad_service_account> -p <ad_passwd> -ou "CN=Computers,DC=domain,DC=com" -domain domain.com -localhome enable -useuncpath enable -groups "Domain Admins" -alldomains enable -force )

			# this requires that you have postfix configured for email.  Check my script for GMail setup, or google it like I did~
            if [[ "$response" == "Settings changed successfully" ]]; then
                echo "$computer was successfully rebound to the domain automatically when a problem was detected." | mail -s "$computer rebound to domain" somebody@youremail.com
            else
                echo "$computer failed to automatically rebind with the domain.  $response" | mail -s "$computer needs attention" somebody@youremail.com
            fi

        fi
    else
        # If the domain returned did not match our expectations
        #echo "<result>Incomplete bind</result>"

        # Force Rebind
		# -- First remove the corrupted trust relationship.
		dsconfigad -force -remove -u jabber -p yepyepyep
		
		# -- Then attempt to rebind the mac to the domain (this command **does NOT** default to mobile accounts!) p.s.  a quick google search will give you the additional flags you need for that.
		response=$( dsconfigad -a $adSafeName -u <ad_service_account> -p <ad_passwd> -ou "CN=Computers,DC=domain,DC=com" -domain domain.com -localhome enable -useuncpath enable -groups "Domain Admins" -alldomains enable -force )

        if [[ "$response" == "Settings changed successfully" ]]; then
            echo "$computer was successfully rebound to the domain automatically when a problem was detected." | mail -s "$computer rebound to domain" somebody@youremail.com
        else
            echo "$computer failed to automatically rebind with the domain.  $response" | mail -s "$computer needs attention" somebody@youremail.com
        fi

    fi
elif [[ $bftr == "Bound Correctly" ]]; then
    # We can't see the DCs, so no way to properly check
    #echo "<result>Cant see the DC??</result>"
    echo "$computer can't see the DC????" | mail -s "$computer needs attention" somebody@youremail.com
else
#echo "<result>Not in range of a DC</result>"
echo "$computer couldn't ping DC" | mail -s "$computer needs attention" somebody@youremail.com
fi

exit 1
