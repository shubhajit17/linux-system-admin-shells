This repository provides a collection of shell scripts designed to streamline system administration tasks on Ubuntu Linux, particularly those related to integrating with Windows Active Directory (AD).

# Key Features
- **Simplified AD Integration:** The `ad_integration.sh` script automates joining your Ubuntu system to a Windows AD domain. It handles tasks like:
  - Installing necessary packages
  - Configuring sssd
  - Updating NTP settings
  - Adding the AD server to the hosts file
**Usage**
1. **Get the Code:**

*Bash*
`git clone https://github.com/your-username/linux-system-admin-shells`

Replace `your-username` with your actual GitHub username.

2.**Customize for your Environment:**

Open `ad_integration.sh` and edit the following variables:

  - `old_ad_domain`: Your current AD domain (if applicable).
  - `new_ad_domain`: The AD domain you want to join.
  - `ad_ou`: The desired Organizational Unit (OU) within the new AD domain.
  - `svc_usr`: Username of the service account with permissions to join the domain.
  - `ad_server_hstname`: The hostname of your Windows AD server.
  - `ad_svr_ip`: The IP address of your Windows AD server.
**Securely Store the Service User Password:**

Do not store the password directly in the script. Instead, consider using a credential management tool or environment variables.

3. **Run the Script:**

Bash
`./ad_integration.sh`

The script will guide you through the process and provide feedback.

**Requirements**
  - Centos/Ubuntu Linux system
  - Root privileges or equivalent
  - Required packages (`sudo yum install` or sudo apt -y install` for these on most systems):
      - ntp
      - ntpdate
      - sssd
      - realmd
      - oddjob
      - oddjob-mkhomedir
      - adcli
      - samba-common
      - samba-common-tools
      - krb5-workstation
      - openldap-clients
      - policycoreutils-python
        
**Security Considerations**
- Ensure the service user has the necessary permissions for joining the domain.
- Test the script in a non-production environment before applying it to live systems.
- Consider using a dedicated user account solely for joining the domain.
  
**Additional Scripts (Optional)**
This repository can be expanded to include scripts for various system administration tasks, such as:

  - User management
  - Package installation and configuration
  - Server monitoring
  - Automating repetitive tasks
    
Feel free to contribute your own scripts or suggest improvements!
