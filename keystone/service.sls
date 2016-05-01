{% from "keystone/map.jinja" import server with context %}
{% if server.enabled %}
keystone_service:
  service.{{ server.service_state }}:
    - name: {{ server.service_name }}
{% if server.service_state in [ 'running', 'dead' ] %}
    - enable: {{ server.service_enable }}
{% endif %}
{% endif %}
