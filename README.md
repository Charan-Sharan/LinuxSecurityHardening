# Linux Security Hardening Scripts
This repository contains a collection of scripts that I use to  automate the process of hardening security on Linux systems.

## Current Features
### SSH Hardening:
Modifies SSH configuration to improve security by:  
1. Disabling root login
2. Disabling Password based authentication 
3. Limiting the number of authentication attempts
4. Changing the default port(22) to a non-standard one  

script : [01_ssh_config.sh](./scripts/01_ssh_config.sh)