{%- from "os/lvm/map.jinja" import lvm with context %}

# PV and VG setup only for openEBS purposes for now, to be extended more

lvm_pkgs:
  pkg.latest:
    - pkgs: {{ lvm.pkgs|tojson }}
    - reload_modules: True

lvm_modules:
  kmod.present:
    - names: {{ lvm.modules|tojson }}
    - persist: True
    - require:
        - pkg: lvm_pkgs

# dmeventd monitors thin pools and performs the autoextend
{%- for service in lvm.services %}
lvm_service_{{ service }}:
  service.running:
    - name: {{ service }}
    - enable: True
    - require:
        - pkg: lvm_pkgs
{%- endfor %}

{%- if lvm.config %}
# lvmlocal.conf overrides lvm.conf, the package-owned lvm.conf stays untouched
lvm_config:
  file.managed:
    - name: /etc/lvm/lvmlocal.conf
    - contents: |
        # managed by salt
{%- for section, settings in lvm.config.items() %}
        {{ section }} {
{%- for key, value in settings.items() %}
{%- if value is sameas true or value is sameas false %}
{%- set value = value|int %}
{%- endif %}
            {{ key }} = {{ value if value is number else value|tojson }}
{%- endfor %}
        }
{%- endfor %}
    - require:
        - pkg: lvm_pkgs
{%- endif %}

{%- if lvm.thinpool_monitor %}
# thin pools created outside of the host LVM (OpenEBS lvm-localpv container) aren't registered in dmeventd, thus never autoextend
# register them as soon as the pool's -tpool device appears; it has SYSTEMD_READY=0 so SYSTEMD_WANTS won't fire, hence RUN
lvm_thinpool_monitor_unit:
  file.managed:
    - name: /etc/systemd/system/lvm-thinpool-monitor@.service
    - contents: |
        # managed by salt
        [Unit]
        Description=Monitor LVM thin pools of VG %i with dmeventd
        Documentation=man:lvmthin(7)
        Requires=dm-event.socket
        After=dm-event.socket

        [Service]
        Type=oneshot
        ExecStart=/usr/sbin/vgchange --monitor y %i
    - require:
        - pkg: lvm_pkgs
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
        - file: lvm_thinpool_monitor_unit

lvm_thinpool_monitor_udev_rule:
  file.managed:
    - name: /etc/udev/rules.d/70-lvm-thinpool-monitor.rules
    - contents: |
        # managed by salt
        ACTION=="add|change", SUBSYSTEM=="block", ENV{DM_LV_LAYER}=="tpool", ENV{DM_VG_NAME}=="?*", RUN+="/usr/bin/systemctl --no-block start lvm-thinpool-monitor@$env{DM_VG_NAME}.service"
    - require:
        - cmd: lvm_thinpool_monitor_unit
  cmd.run:
    - name: udevadm control --reload
    - onchanges:
        - file: lvm_thinpool_monitor_udev_rule
{%- endif %}

{%- for vg, pvs in lvm.vgs.items() %}
{%- set stable = pvs|select('match', '^/dev/disk/by-')|list|length == pvs|length %}
{%- set exists = salt['lvm.vgdisplay'](vg, quiet=True) %}

{%- if stable or not exists %}
# /dev/sdX of an existing VG is skipped as it may point to another disk after re-enumeration
# stable paths are always verified (an orphan PV listed here is vgextend'ed)
{%- for pv in pvs %}
lvm_pv_{{ pv }}:
  lvm.pv_present:
    - name: {{ pv }}
    - require:
        - kmod: lvm_modules
{%- endfor %}

lvm_vg_{{ vg }}:
  lvm.vg_present:
    - name: {{ vg }}
    - devices: {{ pvs|tojson }}
    - require:
{%- for pv in pvs %}
        - lvm: lvm_pv_{{ pv }}
{%- endfor %}
{%- endif %}

# activate (honoring the skip-activation flag) and monitor thin pools, covers pools created before the udev rule
lvm_vg_{{ vg }}_activated:
  cmd.run:
    - name: vgchange --activate ay --monitor y {{ vg }}
    - onlyif: lvs --noheadings -o lv_name -S '(lv_active!=active && lv_skip_activation=0) || (segtype=thin-pool && seg_monitor!=monitored)' {{ vg }} | grep -q .
    - require:
        - kmod: lvm_modules
{%- for service in lvm.services %}
        - service: lvm_service_{{ service }}
{%- endfor %}
{%- if stable or not exists %}
        - lvm: lvm_vg_{{ vg }}
{%- endif %}

{%- endfor %}
