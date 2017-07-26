{% set osd_ips = [] %}
{% set mon_ips = [] %}
{% set cache = {} %}

{%- for node_name, node_grains in salt['mine.get'](pillar['decapod']['mon_nodes_wildcard'], 'grains.items').iteritems() %}
    {%- do mon_ips.append(node_grains['decapod_mgmt_ip']) %}
{%- endfor %}
{%- for node_name, node_grains in salt['mine.get'](pillar['decapod']['osd_nodes_wildcard'], 'grains.items').iteritems() %}
  {%- do osd_ips.append(node_grains['decapod_mgmt_ip']) %}
  {% if pillar['decapod']['cache_devices'] is defined %}
    {% for device in pillar['decapod']['cache_devices'] %}
      {% if device in node_grains['cache'] %}
        {% do cache.update({node_name: pillar['decapod']['cache_devices']}) %}
      {% else %}
        {% do cache.update({node_name: node_grains['cache']}) %}
        {% break %}
      {% endif %}
    {% endfor %}
  {% endif %}
{%- endfor %}

configure cluster:
  module.run:
    - name: decapod.configure_cluster
    - storage_network: {{ pillar['decapod']['storage_network'] }}
    - frontend_network: {{ pillar['decapod']['frontend_network'] }}
    - osd_ips: {{ osd_ips }}
    - mon_ips: {{ mon_ips }}
    - mode: "cluster_deploy"

{%- for node_name, node_grains in salt['mine.get'](pillar['decapod']['mon_nodes_wildcard'], 'grains.items').iteritems() %}
add new node {{ node_name }}:
  module.run:
    - name: decapod.add_node
    - osd_devices: ''
    - osd_journal_devices: [] 
    - ip: {{ node_grains['decapod_mgmt_ip'] }}
    - mode: 'cluster_deploy'
{%- endfor %}

{%- for node_name, node_grains in salt['mine.get'](pillar['decapod']['osd_nodes_wildcard'], 'grains.items').iteritems() %}
add new node {{ node_name }}:
  module.run:
    - name: decapod.add_node
    {%- if pillar['decapod']['ssdpools'] is defined %}
    - osd_devices: {{ node_grains['pools'] | list + pillar['decapod']['ssdpools']| list }}
    {%- else %}
    - osd_devices: {{ node_grains['pools'] | list }}
    {%- endif %}
    - osd_journal_devices: {{ cache[node_name] | default(node_grains['cache']) }}
    - ip: {{ node_grains['decapod_mgmt_ip'] }}
    - mode: 'cluster_deploy'
{%- endfor %}

#execute configuration:
#  module.run:
#    - name: decapod.execute_configuration
#    - mode: 'cluster_deploy'
