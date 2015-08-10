{% from "zinibu/map.jinja" import zinibu_basic with context %}

python-test:
  cmd.run:
    - name: echo 'Python testing. zinibu_basic.app_user {{ zinibu_basic.app_user }} and zinibu_basic.project.name {{ zinibu_basic.project.name }}'

# See pillar.get() vs salt['pillar.get']() at http://docs.saltstack.com/en/latest/topics/pillar/index.html

pillar-get:
  cmd.run:
    - name: echo 'pillar.get [ {% for pip_package in salt['pillar.get']('pip_packages', []) %}{{ pip_package }} {% endfor %}]'

pillar-dict:
  cmd.run:
    - name: echo 'pillar as dictionary [ {% for pip_package in pillar['pip_packages'] %}{{ pip_package }} {% endfor %}]'

pillar-dict-names:
  cmd.run:
    - names:
{% for pip_package in pillar['pip_packages'] %}
      - echo "pillar as dictionary using names - {{ pip_package }}"
{% endfor %}

show-grains:
  cmd.run:
    - name: echo echo "grains id {{ grains['id'] }} public ip {{ grains['ip_interfaces']['eth1'][0] }}"

python-test-webheads:
  cmd.run:
    - name: echo 'webheads ips [ {% for id, webhead in zinibu_basic.project.webheads.iteritems() %}{{ id }} {{ webhead.public_ip }} {% endfor %}]'

{% for id, webhead in zinibu_basic.project.webheads.iteritems() %}
{% if grains['id'] == id %}
webhead-{{ id }}-test:
  cmd.run:
    - name: echo "{{ id }} {{ webhead.public_ip }}"
{% endif %}
{% endfor %}
