#!/usr/bin/env bash
# Supabase – Helper-Script (host side) for Proxmox VE
# Maintainer: Brandon Anubis <your@email>
# License: MIT

APP="Supabase"

# -------------------------------------------------------------------------
#               DEFAULTS  (overridable via env or advanced wizard)
# -------------------------------------------------------------------------
var_tags="${var_tags:-docker}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"        # MiB
var_disk="${var_disk:-30}"        # GB
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"
var_hostname="${var_hostname:-supabase}"
var_bridge="${var_bridge:-vmbr0}"
var_ip="${var_ip:-}"              # blank = DHCP

# -------------------------------------------------------------------------
#                 IMPORT COMMUNITY HELPER FUNCTIONS
# -------------------------------------------------------------------------
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

header_info "$APP"
variables; color; catch_errors

# -------------------------------------------------------------------------
#                OPTIONAL "ADVANCED SETUP" INTERACTIVE WIZARD
# -------------------------------------------------------------------------
function advanced_settings() {
  header_info "$APP -- Advanced Setup"
  echo -e "${YW}Press Enter to accept the [default] shown in brackets.${CL}\n"

  read -r -p "Container ID     [next free] : " var_ctid
  read -r -p "Hostname         [${var_hostname}] : " input    && var_hostname="${input:-$var_hostname}"
  read -r -p "Bridge           [${var_bridge}] : "  input    && var_bridge="${input:-$var_bridge}"
  read -r -p "Static IP/CIDR   [DHCP] : "          var_ip
  read -r -p "CPU cores        [${var_cpu}] : "     input    && var_cpu="${input:-$var_cpu}"
  read -r -p "RAM MiB          [${var_ram}] : "     input    && var_ram="${input:-$var_ram}"
  read -r -p "Disk GB          [${var_disk}] : "    input    && var_disk="${input:-$var_disk}"
  read -r -p "Privileged CT?   (y/N) : "            input    && [[ $input =~ ^[Yy] ]] && var_unprivileged=0
  read -r -p "Custom tag list  [${var_tags}] : "    input    && [[ -n $input ]] && var_tags="$input"
}

# Trigger wizard if ADVANCED=y or user presses 'a'
if [[ "${ADVANCED}" =~ ^[Yy]$ ]]; then
  advanced_settings
else
  read -n1 -rp $'\nPress (a)dvanced setup  or  (Enter) to continue with defaults: ' key
  [[ ${key,,} == a ]] && advanced_settings
fi
echo

# -------------------------------------------------------------------------
#                     OPTIONAL UPDATE-ONLY FLOW
# -------------------------------------------------------------------------
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  [[ -d /opt/supabase ]] || { msg_error "No Supabase installation detected!"; exit 1; }

  msg_info "Pulling latest Supabase images"
  docker compose -p supabase                                          \
    -f /opt/supabase/docker-compose.yml                               \
    --env-file /opt/supabase/.env pull

  msg_info "Recreating containers"
  docker compose -p supabase                                          \
    -f /opt/supabase/docker-compose.yml                               \
    --env-file /opt/supabase/.env up -d

  msg_ok "Supabase stack updated"
  exit
}

# -------------------------------------------------------------------------
#                     HAND OFF TO FRAMEWORK BUILDER
# -------------------------------------------------------------------------
start build_container description
msg_ok "Supabase LXC created successfully!"
echo -e "${TAB}${INFO}${YW}Tip:${CL} Reverse-proxy it through your NPM-Plus CT:"
echo -e "${TAB}${TAB}➜  Map  *api.example.tld*  →  http://<CT-IP>:8000"