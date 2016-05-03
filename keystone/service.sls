{% from "keystone/map.jinja" import server with context %}

{% if server.enabled %}

{% if server.mode in ['wsgi'] %}
keystone_wsgi_reload:
  module.wait:
    - name: cmd.run
    - cmd: {{server.custom_reload_command|default('apachectl graceful')}}
    - python_shell: True

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

{% endif %}
