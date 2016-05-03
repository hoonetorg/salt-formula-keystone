{% from "keystone/map.jinja" import server with context %}

keystone_wsgi__conffile::
  file.managed:
    - name: {{ server.wsgi_conf_target }}
    - source: salt://keystone/files/{{ server.version }}/{{server.wsgi_conf_source }}
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
