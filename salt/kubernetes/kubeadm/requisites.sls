#!py


def run():
    states = {}
    swaps = __salt__['mount.swaps']()

    # immediately disable currently mounted swap
    for dev, details in swaps.items():
        states["kubeadm_disable_swap_{}".format(dev)] = {
            'module.run': [
                {'mount.swapoff': [
                    {'name': dev},
                ]},
                {'require_in': [
                    {'pkg': "kubeadm"}
                ]}
            ]
        }

    # wipe entries for good from fstab
    entries = __salt__['mount.fstab']()
    for name, details in entries.items():
        if details['fstype'] == 'swap':
            states["kubeadm_remove_swap_{}".format(name)] = {
                'module.run': [
                    {'mount.rm_fstab': [
                        {'name': name},
                        {'device': details['device']},
                    ]},
                    {'require_in': [
                        {'pkg': "kubeadm"}
                    ]}
                ]
            }

    return states
