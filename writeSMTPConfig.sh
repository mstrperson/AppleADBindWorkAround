# configure postfix on mac

echo "# Gmail SMTP Relay" >> /etc/postfix/main.cf
echo "" >> /etc/postfix/main.cf
#echo "inet_protocols = ipv4" >> /etc/postfix/main.cf # uncomment this line if your network chokes on ipv6 for some reason...
echo "relayhost = [smtp.gmail.com]:587" >> /etc/postfix/main.cf
echo "" >> /etc/postfix/main.cf
echo "# sasl authentication" >> /etc/postfix/main.cf
echo "" >> /etc/postfix/main.cf
echo "smtpd_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> /etc/postfix/main.cf
echo "smtp_sasl_security_options = " >> /etc/postfix/main.cf
echo "smtp_sasl_mechanism_filter = AUTH LOGIN" >> /etc/postfix/main.cf
echo "" >> /etc/postfix/main.cf
echo "# TLS configuration" >> /etc/postfix/main.cf
echo "" >> /etc/postfix/main.cf
echo "smtp_use_tls = yes" >> /etc/postfix/main.cf
echo "smtp_tls_security_level = encrypt" >> /etc/postfix/main.cf
echo "tls_random_source = dev:/dev/urandom" >> /etc/postfix/main.cf


# store service account credentials
echo "[smtp.gmail.com]:587 service_acct@your.gmail.com:p@$$wd" > /etc/postfix/sasl_passwd

chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

launchctl stop org.postfix.master
launchctl start org.postfix.master

# Send a confirmation email to let you know it all worked out well.
computer=$( hostname )
computer=${computer%".local"}
echo "$computer can send emails" | mail -s "Set Up Complete" you@your.gmail.com
