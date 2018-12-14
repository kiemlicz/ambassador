{% for deployment_file in '/opt/k8s/' | list_files %}
    {% if deployment_file|is_text_file %}
    deploy_{{ deployment_file }}:
        salt.runner:
            - name: salt.cmd
            - arg:
              - cmd.run
              - "kubectl apply -f {{ deployment_file }}"
            - kwarg:
                env:
                  - KUBECONFIG: {{ salt['saltutil.runner'](name='config.get', arg=['kubeconfig']) }}
    {% endif %}
{% endfor %}
