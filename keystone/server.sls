{%- from "keystone/map.jinja" import server with context %}

{%- if server.enabled %}

keystone_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

{%- if not salt['user.info'](server.user.name) %}
keystone_user:
  user.present:
    - name: {{server.user.name}}
    - home: {{server.user.home}}
    - uid: {{server.user.uid}}
    - gid: {{server.group.gid}}
    - shell: {{server.user.shell}}
    - fullname: {{server.user.fullname}}
    - system: True
    - require_in:
      - pkg: keystone_packages

keystone_group:
  group.present:
    - name: {{server.group.name}}
    - gid: {{server.group.gid}}
    - system: True
    - require_in:
      - pkg: keystone_packages
      - user: keystone_user
{%- endif %}

/etc/keystone/keystone.conf:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/keystone.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: keystone_packages
  - watch_in:
    - cmd: keystone_syncdb

/etc/keystone/keystone-paste.ini:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/keystone-paste.ini.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: keystone_packages
  - watch_in:
    - cmd: keystone_syncdb

/etc/keystone/policy.json:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/policy-v{{ server.api_version }}.json
  - template: jinja
  - require:
    - pkg: keystone_packages
  - watch_in:
    - cmd: keystone_syncdb

{% if server.get("domain", {}) %}
/etc/keystone/domains:
  file.directory:
    - mode: 0755
    - require:
      - pkg: keystone_packages

{% for domain_name, domain in server.domain.iteritems() %}
/etc/keystone/domains/keystone.{{ domain_name }}.conf:
  file.managed:
    - source: salt://keystone/files/keystone.domain.conf
    - template: jinja
    - require:
      - file: /etc/keystone/domains
    - watch_in:
      - cmd: keystone_syncdb
    - defaults:
        domain_name: {{ domain_name }}

{% if domain.get('ldap', {}).get('tls', {}).get('cacert', False) %}
keystone_domain_{{ domain_name }}_cacert:
  file.managed:
    - name: /etc/keystone/domains/{{ domain_name }}.pem
    - contents_pillar: keystone:server:domain:{{ domain_name }}:ldap:tls:cacert
    - require:
      - file: /etc/keystone/domains
    - watch_in:
      - cmd: keystone_syncdb
{% endif %}
{% endfor %}
{% endif %}

{%- if server.get('ldap', {}).get('tls', {}).get('cacert', False) %}
keystone_ldap_default_cacert:
  file.managed:
    - name: {{ server.ldap.tls.cacertfile }}
    - contents_pillar: keystone:server:ldap:tls:cacert
    - require:
      - pkg: keystone_packages
    - watch_in:
      - cmd: keystone_syncdb
{%- endif %}

/root/keystonerc:
  file.managed:
  - source: salt://keystone/files/keystonerc
  - template: jinja
  - require:
    - pkg: keystone_packages

/root/keystonercv3:
  file.managed:
  - source: salt://keystone/files/keystonercv3
  - template: jinja
  - require:
    - pkg: keystone_packages

# running "keystone-manage db_sync" as root 
# would create /var/log/keystone/keystone.log as root:root
# this lets *wsgi* implementation fail, because it runs as keystone
keystone_syncdb:
  cmd.run:
  - name: keystone-manage db_sync
  - user: {{server.user.name}}
  - group: {{server.group.name}}
  - watch_in:
    - module: keystone_restart

# see comment at keystone_syncdb: 
# (just to ensure the logfile has the correct user/group)
/var/log/keystone:
  file.directory:
  - user: {{server.user.name}}
  - group: {{server.group.name}}
  - recurse:
    - user
    - group
  - require:
    - cmd: keystone_syncdb
  - watch_in:
    - module: keystone_restart

{% if server.tokens.engine == 'fernet' %}
keystone_fernet_keys:
  file.directory:
  - name: {{ server.tokens.location }}
  - mode: 750
  - user: keystone
  - group: keystone
  - require:
    - pkg: keystone_packages

#FIXME: this will run on every salt run, this is too much -> needs a sane unless or onlyif
keystone_fernet_setup:
  cmd.run:
  - name: keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
  - require:
    - file: keystone_fernet_keys
    - file: /etc/keystone/keystone.conf
  - watch_in:
    - module: keystone_restart
{% endif %}

{% if server.get('mode') in ['wsgi'] %}
keystone_wsgi__conffile::
  file.managed:
    - name: {{ server.wsgi_conf_target }}
    - source: salt://keystone/files/{{ server.version }}/{{server.wsgi_conf_source }}
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - watch_in:
      - module: keystone_restart
keystone_service:
  service.dead:
    - name: {{ server.service_name }}
    - enable: false
{% else %}
keystone_service:
  service.{{ server.service_state }}:
    - name: {{ server.service_name }}
    {% if server.service_state in [ 'running', 'dead' ] %}
    - enable: {{ server.service_enable }}
    {% endif %}
{% endif %}

keystone_restart:
{% if server.service_state in ['running'] %}
  module.wait:
    - name: service.restart
    - m_name: {{ server.service_name }}
{% else %}
  module.wait:
    - name: cmd.run
    - cmd: {{server.custom_reload_command|default('apachectl graceful')}}
    - python_shell: True
{% endif %}

{%- endif %}
