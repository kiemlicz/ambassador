{% for deployment_file in '/opt/k8s/' | list_files %}
    {% if deployment_file|is_text_file %}
    deploy_{{ deployment_file }}:
        salt.runner:
            - name: salt.cmd
            - fun: cmd.run
            - "kubectl apply -f {{ deployment_file }}"
            # fixme prepare args for cmd.run...
    {% endif %}
{% endfor %}
