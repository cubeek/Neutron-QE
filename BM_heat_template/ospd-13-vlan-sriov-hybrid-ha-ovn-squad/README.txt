This Hybrid setup is based on Titan09, Titan17 & Titan18.
Diagram of this setup you can find here:
https://docs.google.com/drawings/d/1MMc3O3T5Z6bJRh906YVRguTADeQmKpLHXaEZ0U0L8U0/edit


The external network detail are:
cat plugins/tripleo-overcloud/vars/public/subnet/neutron_qe_BM.yml
subnet:
    cidr: 10.46.21.192/26
    name: external_subnet
    # Gateway for ext.net may differ from ExternalInterfaceDefaultRoute.
    # As for ipv6 deployments we use still ipv4 gw, we need to specify
    # it explicitly also here for ext. net. purpose.
    gateway: 10.46.21.254
    allocation_pool:
        start: 10.46.21.213
        end: 10.46.21.232       
        
        
The setup is assign to OVN QE squad.
