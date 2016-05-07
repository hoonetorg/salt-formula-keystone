#!jinja|yaml
{% set node_ids = salt['pillar.get']('keystone:server:pcs:node_ids') -%}
{% set admin_node_id = salt['pillar.get']('keystone:server:pcs:admin_node_id') -%}

# node_ids: {{node_ids|json}}
# admin_node_id: {{admin_node_id}}

{% for node_id in node_ids %}
keystone_orchestration__install_{{node_id}}:
  salt.state:
    - tgt: {{node_id}}
    - expect_minions: True
    - sls: keystone.server
    - require_in:
      - salt: keystone.pcs
{% endfor %}

keystone_orchestration__pcs:
  salt.state:
    - tgt: {{admin_node_id}}
    - expect_minions: True
    - sls: keystone.pcs

keystone_orchestration__deploy:
  salt.state:
    - tgt: {{admin_node_id}}
    - expect_minions: True
    - sls: keystone.deploy
    - require:
      - salt: keystone_orchestration__pcs
