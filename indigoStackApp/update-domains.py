import json
import os
import glob
import copy
from pprint import pprint

USER_HOME_FOLDER = '/Users/[your_username]/'
AUTO_DOMAIN_ROOT = '/var/www/'
INDIGOSTACK_CONFIG_FILE = os.path.join(USER_HOME_FOLDER, 'Documents/Indigo/stack.indigostack/config.json')
INDIGOSTACK_CONFIG_LIST_FOLDER = os.path.join(USER_HOME_FOLDER, 'Library/Application Support/com.marmaladesoul.Indigo/states')

# Load the domains from 'domains.json'
with open('./domains.json', 'r') as f:
    domains = json.load(f)

# Resolve absolute paths for each folder in the domains
for domain, folder in domains.items():
    domains[domain] = os.path.realpath(os.path.join(AUTO_DOMAIN_ROOT, folder))

# Load the config from the Indigo stack config file
with open(INDIGOSTACK_CONFIG_FILE, 'r') as f:
    config = json.load(f)

service_nginx_id = -1
original_sites = []

# Find the nginx service in the config
for k, check in enumerate(config['services']):
    if check['type'] == 'nginx':
        service_nginx_id = k
        original_sites = config['services'][service_nginx_id]['config']['sites']
        break

if not original_sites:
    print('nginx service not found')
    exit(1)

# Map existing sites from the config
sites = {site_conf['domain']: site_conf for site_conf in original_sites}

if 'localhost' not in sites:
    print('empty localhost config')
    exit(1)

template = copy.deepcopy(sites['localhost'])

domain_map = {}
folder_map = {}
num = 0xA000
sites['localhost'] = copy.deepcopy(template)
# pprint(template)

# Assign an ID to each domain and update the configuration
for domain, folder in domains.items():
    if not folder:
        continue
    num += 1
    site_id = f"{num:04X}"
    new_site = copy.deepcopy(template)
    new_site['id'] = site_id
    new_site['domain'] = domain
    new_site['reverse_proxy_http'][0]['domains'][0] = domain

    sites[domain] = new_site
    folder_map[site_id] = folder

# Map domain IDs to domains
for domain, conf in sites.items():
    domain_map[conf['id']] = domain

# Output summary
print(f'Update list domain: {len(domains)} found, {len(original_sites)} before in config, {len(sites)} after in config')

# Update the sites in the config
config['services'][service_nginx_id]['config']['sites'] = list(sites.values())

# Write updated config
print("Write main config")
with open(INDIGOSTACK_CONFIG_FILE, 'w') as f:
    json.dump(config, f, indent=4)

# Write the individual nginx site configurations
print("Write link configs")
for site_id, folder in folder_map.items():
    with open(os.path.join(INDIGOSTACK_CONFIG_LIST_FOLDER, f'nginxsite-{site_id}.json'), 'w') as f:
        json.dump({'site_root': folder}, f, indent=4)

# Clean up old config files
print("Clear old link configs")
list_configs = glob.glob(os.path.join(INDIGOSTACK_CONFIG_LIST_FOLDER, 'nginxsite-*.json'))
for file_config in list_configs:
    site_id = os.path.basename(file_config)[10:-5]
    if site_id not in domain_map:
        os.unlink(file_config)
print("Complete")
