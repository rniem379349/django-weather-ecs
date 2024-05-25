FROM grafana/grafana-enterprise:10.0.12-ubuntu
COPY grafana.ini /etc/grafana/grafana.ini
COPY datasources/ /etc/grafana/provisioning/datasources
# VOLUME [ "/var/lib/grafana" ]
EXPOSE 3000
# grafana:
#     <<: *common-config
#     image: grafana/grafana-enterprise
#     container_name: grafana
#     ports:
#       - "3000:3000"
#     volumes:
#       - ./docker/grafana/grafana.ini:/etc/grafana/grafana.ini
#       - ./docker/grafana/datasources:/etc/grafana/provisioning/datasources
#       - grafana_data:/var/lib/grafana
