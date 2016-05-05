{% from "keystone/map.jinja" import server with context %}

include:
{% if pillar.keystone.server is defined %}
- keystone.server
- keystone.deploy
{% endif %}
{% if pillar.keystone.client is defined %}
- keystone.client
{% endif %}
{% if pillar.keystone.control is defined %}
- keystone.control
{% endif %}

#for deploy.sls
{% if pillar.keystone.server is defined %}
{% if server.enabled %}
extend:
  {%- if server.get("domain", {}) %}
  {% for domain_name, domain in server.domain.iteritems() %}
  keystone_domain_{{ domain_name }}:
    #cmd.run:
    cmd:
      - require:
        - file: /root/keystonercv3
        - module: keystone_restart
        - service: keystone_service
  {% endfor %}
  {% endif %}

  keystone_service_tenant:
    #keystone.tenant_present:
    keystone:
      - require:
        - module: keystone_restart
        - service: keystone_service
{% endif %}
{% endif %}
