#Integrate Ubuntu 22 LTS with AD
#!/bin/bash
# Variables
new_ad_domain="YOUR AD DOMAIN" # E.g. test.com
ad_ou=${ad_ou:-OU=test,dc=test,dc=com} # Replace values against OU and dc as per actual OU and DC values
svc_usr="service user who can add system to Windows AD" # E.g. sv_it_admin
ad_server_hstname="YOUR WINDOWS ACTIVE DIRECTORY SERVER HOSTNAME NAME" # E.g. winsrv.test.com
ad_svr_ip="AD Server IP"

# Load service user credentials securely (e.g., from a credential management tool or environment variable)
svc_usr_password=$(cat /path/to/your/password_file)  # Replace with your secure method

## Install all the required packages ##
sudo apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit ntp || { echo "Failed to install packages"; exit 1; }

##Verify if AD is getting discovered ##
sudo realm discover $new_ad_domain || { echo "Failed to discover domain"; exit 1; }

## Join Realm
sudo realm join --user="$svc_usr" --password="$svc_usr_password" "$(echo "$new_ad_domain" | tr '[:lower:]' '[:upper:]')" -v --computer-ou="${ad_ou}" || { echo "Failed to join realm"; exit 1; }

##Update sssd configuration
sudo tee /etc/sssd/sssd.conf > /dev/null <<EOF
[sssd]
##master & data nodes only require nss. Edge nodes require pam.
services = nss,pam
config_file_version = 2
domains = $(echo "$new_ad_domain" | tr '[:lower:]' '[:upper:]')
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

##Allow AD Users to create home directory on login 
sudo nano /etc/pam.d/common-session
session optional pam_mkhomedir.so skel=/etc/skel umask=077

##Restart sssd service 
sudo systemctl restart sssd || { echo "Failed to restart sssd"; exit 1; }