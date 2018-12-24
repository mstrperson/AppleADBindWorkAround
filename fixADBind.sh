#!/bin/bash

#################################################################
# Parameters: (1-3 are defined by Jamf Pro).
#  4:  Domain Controler IP Address
#  5:  Domain Name (e.g. yourdomain.com)
#  6:  Service Account Username for AD Bind
#  7:  Service Account Password
#  8:  LDAP formatted OU for your computers to be added to.
#  9:  Email Address for report messages to be sent to.  (Requires Postfix configured)
# 10:  Leave this /blank/ to use the computer's local host name.  Enter any value here to use the Jamf Pro computer name instead.
##################################################################

if [[ $4 == "" ]]; then
    DC_IP="192.168.100.100"
else
    DC_IP=$4
fi

if [[ $5 == "" ]]; then
    DOMAIN_NAME="yourdomain.com"
else
    DOMAIN_NAME=$5
fi

if [[ $6 == "" ]]; then
    BIND_USER="service_acct"
else
    BIND_USER=$6
fi

if [[ $7 == "" ]]; then
    BIND_PWD="service_acct_pwd"
else
    BIND_PWD=$7
fi

if [[ $8 == "" ]]; then
    LDAP_OU="CN=Computers,DC=yourdomain,DC=com"
else
    LDAP_OU=$8
fi

if [[ $9 == "" ]]; then
    EMAIL_ADDRESS="somebody@nowhere.com"
else
    EMAIL_ADDRESS=$9
fi

if [[ $10 != "" ]]; then
    # Harvest the hostname from the local computer.
    computer=$( hostname )
    # Drop the .local from the end that mac os tags on sometimes...
    computer=${computer%".local"}
else
    # Use the Jamf Pro Computer Name field.
    computer=$2
fi

# Unlike windows, dsconfigad limits computer names to 15 characters...
adSafeName=$( echo $computer | cut 1-15 )

#ping the Domain or DC
ping -c 3 -o $DC_IP /dev/null 2> /dev/null

# If the ping was successful
if [[ $? == 0 ]]; then
    # Check the domain returned with dsconfigad
    domain=$( dsconfigad -show | awk '/Active Directory Domain/{print $NF}' )
    # If the domain is correct
    if [[ "$domain" == $DOMAIN_NAME ]]; then
	
        # Check the id of a service account
        id -u $BIND_USER
		
        # If the check was successful...
        if [[ $? == 0 ]]; then
            # All is well!  nothing to do!
            exit 0
        else
            # If the check failed
            # Force Rebind
	    # -- First remove the corrupted trust relationship.  username and passwd don't matter.
            dsconfigad -force -remove -u jabber -p yepyepyep
	    
	    # -- sleep to allow the remove to have time to process and sync with domain.
	    sleep 5     
	    # -- Then attempt to rebind the mac to the domain (this command **does NOT** default to mobile accounts!) p.s.  a quick google search will give you the additional flags you need for that.
            response=$( dsconfigad -a $adSafeName -u $BIND_USER -p $BIND_PWD -ou $LDAP_OU -domain $DOMAIN_NAME -localhome enable -useuncpath enable -groups "Domain Admins" -alldomains enable -force )

	    # this requires that you have postfix configured for email.  Check my script for GMail setup, or google it like I did~
            if [[ "$response" == "Settings changed successfully" ]]; then
                echo "$computer ($2) was successfully rebound to the domain automatically when a problem was detected." | mail -s "$computer ($2) rebound to domain" $EMAIL_ADDRESS
            else
                echo "$computer ($2) failed to automatically rebind with the domain.  $response" | mail -s "$computer ($2) needs attention" $EMAIL_ADDRESS
            fi

        fi
    else
        # If the domain returned did not match our expectations
        # Force Rebind
	# -- First remove the corrupted trust relationship.
	dsconfigad -force -remove -u jabber -p yepyepyep
	
	# -- sleep to allow the remove to have time to process and sync with the domain
	sleep 5 
	
	# -- Then attempt to rebind the mac to the domain (this command **does NOT** default to mobile accounts!) p.s.  a quick google search will give you the additional flags you need for that.
	response=$( dsconfigad -a $adSafeName -u $BIND_USER -p $BIND_PWD -ou $LDAP_OU -domain $DOMAIN_NAME -localhome enable -useuncpath enable -groups "Domain Admins" -alldomains enable -force )

        if [[ "$response" == "Settings changed successfully" ]]; then
            echo "$computer ($2) was successfully rebound to the domain automatically when a problem was detected." | mail -s "$computer ($2) rebound to domain" $EMAIL_ADDRESS
        else
            echo "$computer ($2) failed to automatically rebind with the domain.  $response" | mail -s "$computer ($2) needs attention" $EMAIL_ADDRESS
        fi

    fi
elif [[ $bftr == "Bound Correctly" ]]; then
    # We can't see the DCs, so no way to properly check
    echo "$computer ($2) can't see the DC????" | mail -s "$computer ($2) needs attention" $EMAIL_ADDRESS
else
    echo "$computer ($2) couldn't ping DC" | mail -s "$computer ($2) needs attention" $EMAIL_ADDRESS
fi

exit 1
