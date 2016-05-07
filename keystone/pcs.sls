# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "keystone/map.jinja" import server with context %}
{% set pcs = server.get('pcs', {}) %}

{# set pcs = salt['pillar.get']('keystone:server:pcs', {}) #}

{% if pcs.keystone_cib is defined and pcs.keystone_cib %}
keystone_pcs__cib_present_{{pcs.keystone_cib}}:
  pcs.cib_present:
    - cibname: {{pcs.keystone_cib}}
{% endif %}

{% if 'resources' in pcs %}
{% for resource, resource_data in pcs.resources.items()|sort %}
keystone_pcs__resource_present_{{resource}}:
  pcs.resource_present:
    - resource_id: {{resource}}
    - resource_type: "{{resource_data.resource_type}}"
    - resource_options: {{resource_data.resource_options|json}}
{% if pcs.keystone_cib is defined and pcs.keystone_cib %}
    - require:
      - pcs: keystone_pcs__cib_present_{{pcs.keystone_cib}}
    - require_in:
      - pcs: keystone_pcs__cib_pushed_{{pcs.keystone_cib}}
    - cibname: {{pcs.keystone_cib}}
{% endif %}
{% endfor %}
{% endif %}

{% if 'constraints' in pcs %}
{% for constraint, constraint_data in pcs.constraints.items()|sort %}
keystone_pcs__constraint_present_{{constraint}}:
  pcs.constraint_present:
    - constraint_id: {{constraint}}
    - constraint_type: "{{constraint_data.constraint_type}}"
    - constraint_options: {{constraint_data.constraint_options|json}}
{% if pcs.keystone_cib is defined and pcs.keystone_cib %}
    - require:
      - pcs: keystone_pcs__cib_present_{{pcs.keystone_cib}}
    - require_in:
      - pcs: keystone_pcs__cib_pushed_{{pcs.keystone_cib}}
    - cibname: {{pcs.keystone_cib}}
{% endif %}
{% endfor %}
{% endif %}

{% if pcs.keystone_cib is defined and pcs.keystone_cib %}
keystone_pcs__cib_pushed_{{pcs.keystone_cib}}:
  pcs.cib_pushed:
    - cibname: {{pcs.keystone_cib}}
{% endif %}

keytone_pcs__empty_sls_prevent_error:
  cmd.run:
    - name: true
    - unless: true
