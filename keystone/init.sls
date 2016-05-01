{% from "keystone/map.jinja" import server with context %}

include:
{% if pillar.keystone.server is defined %}
- keystone.server
- keystone.service
- keystone.deploy
{% endif %}
{% if pillar.keystone.client is defined %}
- keystone.client
{% endif %}
{% if pillar.keystone.control is defined %}
- keystone.control
{% endif %}


{% if pillar.keystone.server is defined %}
{% if server.enabled %}
extend:
  #from service.sls
  /etc/keystone/keystone.conf:
    #file.managed:
    file:
      - watch_in:
        - service: keystone_service
  #from server.sls
  /etc/keystone/keystone-paste.ini:
    #file.managed:
    file:
      - watch_in:
        - service: keystone_service

  #from server.sls
  /etc/keystone/policy.json:
    #file.managed:
    file:
      - watch_in:
        - service: keystone_service

  #from server.sls
  {% if server.get('ldap', {}).get('tls', {}).get('cacert', False) %}
  keystone_ldap_default_cacert:
    #file.managed:
    file:
      - watch_in:
        - service: keystone_service
  {% endif %}

  {%- if server.get("domain", {}) %}
  #from server.sls
  /etc/keystone/domains:
    #file.directory:
    file:
      - require:
        - pkg: keystone_packages

  {% for domain_name, domain in server.domain.iteritems() %}
  #from server.sls
  /etc/keystone/domains/keystone.{{ domain_name }}.conf:
    #file.managed:
    file:
      - watch_in:
        - service: keystone_service

  #from server.sls
  {% if domain.get('ldap', {}).get('tls', {}).get('cacert', False) %}
  keystone_domain_{{ domain_name }}_cacert:
    #file.managed:
    file:
      - watch_in:
        - service: keystone_service
  {% endif %}

  #from deploy.sls
  keystone_domain_{{ domain_name }}:
    #cmd.run:
    cmd:
      - require:
        - file: /root/keystonercv3
        - service: keystone_service
  {% endfor %}
  {% endif %}

  #from deploy.sls
  keystone_syncdb:
    #cmd.run:
    cmd:
    - require:
      - service: keystone_service

  #from deploy.sls
  {% if server.tokens.engine == 'fernet' %}
  keystone_fernet_keys:
    file.directory:
    - require:
      - pkg: keystone_packages

  keystone_fernet_setup:
    cmd.run:
    - require:
      - service: keystone_service
  {% endif %}

{% endif %}
{% endif %}
