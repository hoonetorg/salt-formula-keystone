{%- from "keystone/map.jinja" import server with context %}
{%- if server.enabled %}

keystone_service_tenant:
  keystone.tenant_present:
  - name: {{ server.service_tenant }}

keystone_admin_tenant:
  keystone.tenant_present:
  - name: {{ server.admin_tenant }}
  - require:
    - keystone: keystone_service_tenant

keystone_roles:
  keystone.role_present:
  - names: {{ server.roles }}
  - require:
    - keystone: keystone_service_tenant

keystone_admin_user:
  keystone.user_present:
  - name: {{ server.admin_name }}
  - password: {{ server.admin_password }}
  - email: {{ server.admin_email }}
  - tenant: {{ server.admin_tenant }}
  - roles:
      {{ server.admin_tenant }}:
      - admin
  - require:
    - keystone: keystone_admin_tenant
    - keystone: keystone_roles

{% if server.get("domain", {}) %}
{% for domain_name, domain in server.domain.iteritems() %}
keystone_domain_{{ domain_name }}:
  cmd.run:
    - name: source /root/keystonercv3 && openstack domain create --description "{{ domain.description }}" {{ domain_name }}
    - unless: source /root/keystonercv3 && openstack domain list | grep " {{ domain_name }}"
    - require:
      - keystone: keystone_admin_user
{% endfor %}
{% endif %}

{% for service_name, service in server.get('service', {}).iteritems() %}

keystone_{{ service_name }}_service:
  keystone.service_present:
  - name: {{ service_name }}
  - service_type: {{ service.type }}
  - description: {{ service.description }}
  - require:
    - keystone: keystone_roles

keystone_{{ service_name }}_endpoint:
  keystone.endpoint_present:
  - name: {{ service.get('service', service_name) }}
  - publicurl: '{{ service.bind.get('public_protocol', 'http') }}://{{ service.bind.public_address }}:{{ service.bind.public_port }}{{ service.bind.public_path }}'
  - internalurl: '{{ service.bind.get('internal_protocol', 'http') }}://{{ service.bind.internal_address }}:{{ service.bind.internal_port }}{{ service.bind.internal_path }}'
  - adminurl: '{{ service.bind.get('admin_protocol', 'http') }}://{{ service.bind.admin_address }}:{{ service.bind.admin_port }}{{ service.bind.admin_path }}'
  - region: {{ service.get('region', 'RegionOne') }}
  - require:
    - keystone: keystone_{{ service_name }}_service

{% if service.user is defined %}

keystone_user_{{ service.user.name }}:
  keystone.user_present:
  - name: {{ service.user.name }}
  - password: {{ service.user.password }}
  - email: {{ server.admin_email }}
  - tenant: {{ server.service_tenant }}
  - roles:
      {{ server.service_tenant }}:
      - admin
  - require:
    - keystone: keystone_roles

{% endif %}

{% endfor %}

{%- for tenant_name, tenant in server.get('tenant', {}).iteritems() %}

keystone_tenant_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
  - require:
    - keystone: keystone_roles

{%- for user_name, user in tenant.get('user', {}).iteritems() %}

keystone_user_{{ user_name }}:
  keystone.user_present:
  - name: {{ user_name }}
  - password: {{ user.password }}
  - email: {{ user.get('email', 'root@localhost') }}
  - tenant: {{ tenant_name }}
  - roles:
      {{ tenant_name }}:
      {%- if user.get('roles', False) %}
        {{ user.roles|json }}
      {%- else %}
        - Member
      {%- endif %}
  - require:
    - keystone: keystone_tenant_{{ tenant_name }}

{%- endfor %}

{%- endfor %}

{%- endif %}
