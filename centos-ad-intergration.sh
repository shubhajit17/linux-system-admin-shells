#!/bin/bash
# Variables
old_ad_domain="YOUR AD DOMAIN" # E.g. test.com
new_ad_domain="YOUR AD DOMAIN" # E.g. test.com
ad_ou=${ad_ou:-OU=test,dc=test,dc=com} # Replace values against OU and dc as per actual OU and DC values
svc_usr="service user who can add system to Windows AD" # E.g. sv_it_admin
ad_server_hstname="YOUR WINDOWS ACTIVE DIRECTORY SERVER HOSTNAME NAME" # E.g. winsrv.test.com
ad_svr_ip="AD Server IP"

# Load service user credentials securely (e.g., from a credential management tool or environment variable)
svc_usr_password=$(cat /path/to/your/password_file)  # Replace with your secure method

# Leave Realm if already joined
sudo realm leave "$old_ad_domain" || { echo "Failed to leave old domain"; exit 1; }

# Clear Kerberos related data
sudo systemctl stop sssd || { echo "Failed to stop sssd"; exit 1; }
sudo sss_cache -E || { echo "Failed to clear sss cache"; exit 1; }
sudo rm -rf /var/lib/sss/db/* || { echo "Failed to remove sss database"; exit 1; }
sudo rm -rf /etc/krb5.keytab || { echo "Failed to remove krb5 keytab"; exit 1; }

## Install all the required packages ##
sudo yum install ntp ntpdate sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y || { echo "Failed to install packages"; exit 1; }

## Join Realm
/usr/sbin/realm join --user="$svc_usr" --password="$svc_usr_password" "$(echo "$new_ad_domain" | tr '[:lower:]' '[:upper:]')" -v --computer-ou="${ad_ou}" || { echo "Failed to join realm"; exit 1; }

##Update sssd configuration
sudo tee /etc/sssd/sssd.conf > /dev/null <<EOF
[sssd]
##master & data nodes only require nss. Edge nodes require pam.
services = nss,pam
config_file_version = 2
domains = $new_ad_domain
override_space = -
enum_cache_timeout = 10
[nss]
override_shell = /bin/bash
override_homedir = /home/%u

[domain/$(echo "$new_ad_domain" | tr '[:lower:]' '[:upper:]')]
ad_server = $ad_server_hstname
ad_domain = $(echo "$new_ad_domain" | tr '[:lower:]' '[:upper:]')
krb4_realm = $(echo "$new_ad_domain" | tr '[:lower:]' '[:upper:]')
debug_level = 1  # Lower debug level for production
realm_tags = manages-system joined-with-samba
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
fallback_homedir = /home/%u
access_provider = ad
EOF

#Update sssd.conf file permission 
sudo chmod 0600 /etc/sssd/sssd.conf
sudo systemctl start sssd;sudo systemctl enable sssd;chkconfig sssd on 
#Add AD Server in /etc/hosts file
echo "$ad_svr_ip $new_ad_domain" >> /etc/hosts

#Update ntpd details
sed -i 's/^server * /#server /g' /etc/ntp.conf
echo "server $ad_svr_ip" >> /etc/ntp.conf
sudo systemctl restart ntpd;chkconfig ntpd on;ntpdate -u $ad_svr_ip || { echo "Failed to update NTP"; exit 1; }