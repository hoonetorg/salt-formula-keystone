{% from "keystone/map.jinja" import server with context %}

{% if server.mode in ['wsgi'] %}
  {% set service_watch_resource = 'module: keystone_wsgi_reload' %}
{% else %}
  {% set service_watch_resource = 'service: keystone_service' %}
{% endif %}


include:
{% if pillar.keystone.server is defined %}
- keystone.server
{% if server.mode in ['wsgi'] %}
- keystone.wsgi
{% endif %}
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
        - {{ service_watch_resource }}
  #from server.sls
  /etc/keystone/keystone-paste.ini:
    #file.managed:
    file:
      - watch_in:
        - {{ service_watch_resource }}

  #from server.sls
  /etc/keystone/policy.json:
    #file.managed:
    file:
      - watch_in:
        - {{ service_watch_resource }}

  #from server.sls
  {% if server.get('ldap', {}).get('tls', {}).get('cacert', False) %}
  keystone_ldap_default_cacert:
    #file.managed:
    file:
      - watch_in:
        - {{ service_watch_resource }}
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
        - {{ service_watch_resource }}

  #from server.sls
  {% if domain.get('ldap', {}).get('tls', {}).get('cacert', False) %}
  keystone_domain_{{ domain_name }}_cacert:
    #file.managed:
    file:
      - watch_in:
        - {{ service_watch_resource }}
  {% endif %}

  #from deploy.sls
  keystone_domain_{{ domain_name }}:
    #cmd.run:
    cmd:
      - require:
        - file: /root/keystonercv3
        - {{ service_watch_resource }}
  {% endfor %}
  {% endif %}

  #from server.sls
  keystone_syncdb:
    #cmd.run:
    cmd:
    - require_in:
      - {{ service_watch_resource }}

  #from deploy.sls
  {% if server.tokens.engine == 'fernet' %}
  keystone_fernet_keys:
    file.directory:
    - require:
      - pkg: keystone_packages

  keystone_fernet_setup:
    cmd.run:
    - require:
      - {{ service_watch_resource }}

  keystone_service_tenant:
    keystone.tenant_present:
    - require:
      - {{ service_watch_resource }}

  {% endif %}

{% endif %}
{% endif %}
