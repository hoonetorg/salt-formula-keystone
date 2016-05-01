{%- from "keystone/map.jinja" import server with context %}
{%- if server.enabled %}
keystone_service:
  service.running:
  - name: {{ server.service_name }}
  - enable: True
{%- endif %}

