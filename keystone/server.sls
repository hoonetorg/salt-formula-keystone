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


/etc/keystone/keystone-paste.ini:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/keystone-paste.ini.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: keystone_packages

/etc/keystone/policy.json:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/policy-v{{ server.api_version }}.json
  - require:
    - pkg: keystone_packages

{%- if server.get('ldap', {}).get('tls', {}).get('cacert', False) %}

keystone_ldap_default_cacert:
  file.managed:
    - name: {{ server.ldap.tls.cacertfile }}
    - contents_pillar: keystone:server:ldap:tls:cacert
    - require:
      - pkg: keystone_packages

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

{%- endif %}
