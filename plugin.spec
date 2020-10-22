---
config:
    entry_point: ./ovn_migration/infrared/tripleo-ovn-migration/main.yml
    plugin_type: install
subparsers:
    tripleo-ovn-migration:
        description: Migrate an existing TripleO overcloud from Neutron ML2OVS plugin to OVN
        include_groups: ["Ansible options", "Inventory", "Common options", "Answers file"]
        groups:
            - title: Containers
              options:
                  registry-namespace:
                      type: Value
                      help: The alternative docker registry namespace to use for deployment.

                  registry-prefix:
                      type: Value
                      help: The images prefix

                  registry-tag:
                      type: Value
                      help: The images tag

                  registry-mirror:
                      type: Value
                      help: The alternative docker registry to use for deployment.

            - title: Deployment Description
              options:
                  version:
                      type: Value
                      help: |
                          The product version
                          Numbers are for OSP releases
                          Names are for RDO releases
                          If not given, same version of the undercloud will be used
                      choices:
                        - "7"
                        - "8"
                        - "9"
                        - "10"
                        - "11"
                        - "12"
                        - "13"
                        - "14"
                        - "15"
                        - "16"
                        - "16.1"
                        - kilo
                        - liberty
                        - mitaka
                        - newton
                        - ocata
                        - pike
                        - queens
                        - rocky
                        - stein
                        - train
                  install_from_package:
                      type: Bool
                      help: Install python-networking-ovn-migration-tool rpm
                      default: True

                  dvr:
                      type: Bool
                      help: If the deployment is to be dvr or not
                      default: False

                  sriov:
                      type: Bool
                      help: If the environment uses SR-IOV
                      default: False

                  after_ffu:
                      type: Bool
                      help: If the environment is after Fast Forward Upgrade
                      default: False

                  create_resources:
                      type: Bool
                      help: Create resources to measure downtime
                      default: True

                  resources_type:
                      type: Value
                      help: |
                          Type of resources we want to create
                          normal: creates amount of VMs matching number of compute nodes
                          normal_ext: same as normal but creates VMs on external network
                          dvr: same as normal but creates DVR router instead of HA
                          sriov_int_no_pf: as normal but creates also VMs with SR-IOV VF(direct) ports
                          sriov_int: as sriov_int_no_pf but creates also VMs with SR-IOV PF(direct-physical) ports
                          sriov_ext_no_pf: as sriov_int_no_pf but creates VMs connected to the external network
                          sriov_ext: as sriov_ext_no_pf but creates also VMs with SR-IOV PF(direct-physical) ports
                      choices:
                        - normal
                        - normal_ext
                        - dvr
                        - sriov_int_no_pf
                        - sriov_int
                        - sriov_ext_no_pf
                        - sriov_ext
                      default: normal

                  external_network:
                      type: Value
                      help: External network name to use
                      default: public

                  compute_external_access:
                      type: Bool
                      help: Whether compute nodes have access to the external network (i.e. external interface is under br-ex bridge).
                      default: False

                  image_name:
                      type: Value
                      help: Image name to use
                      default: cirros-0.4.0-x86_64-disk.img

                  server_user_name:
                      type: Value
                      help: User name to use for login to the resources VMs
                      default: cirros

                  stack_name:
                      type: Value
                      help: Name of the stack to update
                      default: overcloud

                  jumbo_mtu:
                      type: Bool
                      help: Whether target environment should support jumbo MTU.
                      default: False
