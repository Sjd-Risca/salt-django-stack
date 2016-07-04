zinibu_basic:
  app_user: exampleuser
  app_group: examplegroup
  do_token: xyz
  root_user: root
  project:
    name: zinibu_dev
    pyvenvs_dir: pyvenvs

    # keys of webheads must match minion ids
    webheads:
      django5:
          public_ip: pub1
          private_ip: priv1
          nginx_port: 81
          gunicorn_port: 8000
          maxconn_dynamic: 250
          maxconn_static: 50
          slowstart: 10s

    varnish_check: '/varnishcheck'

    # keys must match minion ids
    varnish_servers:
      django5:
          public_ip: pub1
          private_ip: priv1
          port: 83
          maxconn_cache: 1000

    # if using keepalived, put the floating IP here
    haproxy_frontend_public_ip: pub1
    # optional ssl certificate
    #haproxy_ssl_cert: /etc/haproxy/ssl/haproxy.pem
    haproxy_frontend_port: 80
    haproxy_frontend_secure_port: 443
    haproxy_check: '/haproxycheck'
    haproxy_app_check_url: '/app-check'
    haproxy_app_check_expect: '[oO][kK]'
    haproxy_static_check_url: '/static/znbmain/static-check.txt'

    # keys must match minion ids
    # set anchor_ip when using floating IPs with Digital Ocean
    haproxy_servers:
      django5:
          anchor_ip: 0.0.0.0
          public_ip: pub1
          private_ip: priv1
          port: 80
          keepalived_priority: 101
          stats_port: 8998
          stats:
            enable: True
            hide-version: ""
            uri: "/admin?stats"
            show-desc: "Primary load balancer"
            refresh: "20s"
            realm: "HAProxyStatistics1"
            auth: 'admin:admin'

    # keys must match minion ids
    glusterfs_nodes:
      django5:
          private_ip: priv1

    # keys must match minion ids
    redis_nodes:
      django5:
          private_ip: priv1

    postgresql_servers:
      django5:
          public_ip: pub1
          private_ip: priv1
          port: 5432

    # YAML alternative list of objects syntax
    #webheads:
    #  - {public_ip: 192.168.33.15, nginx_port: 80, gunicorn_port: 8000}
    #  - {public_ip: 192.168.33.16, nginx_port: 80, gunicorn_port: 8000}
    #  - {public_ip: 192.168.33.17, nginx_port: 80, gunicorn_port: 8000}