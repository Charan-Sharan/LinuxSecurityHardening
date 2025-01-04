# Linux Security Hardening Scripts
This repository contains a collection of scripts that I use to  automate the process of hardening security on Linux systems.

## Current Features
### SSH user Management:
Modifies users and user permissions to improve ssh security by,
1. enusring that there is atleast one non root user
2. Providing sudo privilages to ssh user
3. Adding autherized keys to SSH user

script : [01_user_management.sh](./scripts/01_user_management.sh)

### SSH Hardening:
Modifies SSH configuration to improve security by,
1. Disabling root login
2. Disabling Password based authentication 
3. Limiting the number of authentication attempts
4. Changing the default port(22) to a non-standard one  

script : [02_ssh_config.sh](./scripts/02_ssh_config.sh)