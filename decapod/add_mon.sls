{% set osd_ips = [] %}
{% set mon_ips = [] %}

{%- for node_name, node_grains in salt['mine.get'](pillar['decapod']['mon_nodes_wildcard'], 'grains.items').iteritems() %}
    {% set ip = node_grains['decapod_mgmt_ip'] %}
    {%- do mon_ips.append(ip) %}
{%- endfor %}
{%- for node_name, node_grains in salt['mine.get'](pillar['decapod']['osd_nodes_wildcard'], 'grains.items').iteritems() %}
    {% set ip = node_grains['decapod_mgmt_ip'] %}
    {%- do osd_ips.append(ip) %}
{%- endfor %}

configure cluster:
  module.run:
    - name: decapod.configure_cluster
    - decapod_ip: {{ pillar['decapod']['decapod_ip'] }}
    - decapod_user: {{ pillar['decapod']['decapod_user'] }}
    - decapod_pass: {{ pillar['decapod']['decapod_pass'] }}
    - storage_network: {{ pillar['decapod']['storage_network'] }}
    - frontend_network: {{ pillar['decapod']['frontend_network'] }}
    - osd_ips: {{ osd_ips }}
    - mon_ips: {{ mon_ips }}
    - mode: 'add_mon'

