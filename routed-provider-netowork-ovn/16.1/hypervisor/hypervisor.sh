sudo yum install -y dhcp.x86_64

sudo dhcrelay --no-pid 192.168.24.10  192.168.24.1

sudo iptables -I FORWARD -s 192.168.34.0/24 -d 192.168.24.0/24 -j ACCEPT
sudo iptables -I FORWARD -s 192.168.24.0/24 -d 192.168.34.0/24 -j ACCEPT
sudo iptables -I FORWARD -s 192.168.24.0/24 -d 192.168.44.0/24 -j ACCEPT
sudo iptables -I FORWARD -s 192.168.44.0/24 -d 192.168.24.0/24 -j ACCEPT
sudo iptables -I FORWARD -j ACCEPT

sudo iptables -t nat -I POSTROUTING -s 192.168.24.0/24 ! -d 192.168.24.0/24 -j MASQUERADE
sudo iptables -t nat -I POSTROUTING -s 192.168.34.0/24 ! -d 192.168.34.0/24 -j MASQUERADE
sudo iptables -t nat -I POSTROUTING -s 192.168.44.0/24 ! -d 192.168.44.0/24 -j MASQUERADE

ip link add link site-management name site.1188 type vlan id 1188
ip a add 172.18.1.254/24 dev site.1188
ip link set dev site.1188 up

ip link add link site-management name site.1189 type vlan id 1189
ip a add 172.19.1.254/24 dev site.1189
ip link set dev site.1189 up

ip link add link site-management name site.1183 type vlan id 1183
ip a add 172.23.1.254/24 dev site.1183
ip link set dev site.1183 up

ip link add link site-management name site.1185 type vlan id 1185
ip a add 172.25.1.254/24 dev site.1185
ip link set dev site.1185 up

#################################################################
ip link add link dcn1-management name dcn1.1178 type vlan id 1178
ip a add 172.18.2.254/24 dev dcn1.1178
ip link set dev dcn1.1178 up

ip link add link dcn1-management name dcn1.1179 type vlan id 1179
ip a add 172.19.2.254/24 dev dcn1.1179
ip link set dev dcn1.1179 up


ip link add link dcn1-management name dcn1.1173 type vlan id 1173
ip a add 172.23.2.254/24 dev dcn1.1173
ip link set dev dcn1.1173 up

ip link add link dcn1-management name dcn1.1175 type vlan id 1175
ip a add 172.25.2.254/24 dev dcn1.1175
ip link set dev dcn1.1175 up
#################################################################
ip link add link dcn2-management name dcn2.1168 type vlan id 1168
ip a add 172.18.3.254/24 dev dcn2.1168
ip link set dev dcn2.1168 up

ip link add link dcn2-management name dcn2.1169 type vlan id 1169
ip a add 172.19.3.254/24 dev dcn2.1169
ip link set dev dcn2.1169 up

ip link add link dcn2-management name dcn2.1163 type vlan id 1163
ip a add 172.23.3.254/24 dev dcn2.1163
ip link set dev dcn2.1163 up

ip link add link dcn2-management name dcn2.1165 type vlan id 1165
ip a add 172.25.3.254/24 dev dcn2.1165
ip link set dev dcn2.1165 up
