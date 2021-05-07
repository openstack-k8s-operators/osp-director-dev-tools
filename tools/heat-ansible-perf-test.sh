# Script to perf test Heat --> Ansible generation
# Run this in the t-h-t root to generate fake compute hosts
# add DeployedServerPortMap at bottom of file
cat << EOF_CAT >> deployed-server-map.yaml
  DeployedServerPortMap:
    controller-0-ctlplane:
      fixed_ips:
        - ip_address: 192.168.25.103
      subnets:
        - cidr: 192.168.25.0/24
      network:
        tags:
          - 192.168.25.0/24
    control_virtual_ip:
      fixed_ips:
        - ip_address: 192.168.25.100
      subnets:
        - cidr: 192.168.25.0/24
      network:
        tags:
          - 192.168.25.0/24
    compute-0-ctlplane:
      fixed_ips:
        - ip_address: 192.168.25.101
      subnets:
        - cidr: 192.168.25.0/24
      network:
        tags:
          - 192.168.25.0/24
EOF_CAT


for X in {10..200}; do
ID=$(( $X - 9 ))
cat << EOF_CAT >> deployed-server-map.yaml
    compute-$ID-ctlplane:
      fixed_ips:
        - ip_address: 192.168.25.1$X
      subnets:
        - cidr: 192.168.25.0/24
      network:
        tags:
          - 192.168.25.0/24
EOF_CAT
done

#ip-from-pool
cat << EOF_CAT >> ips-from-pool.yaml
  ComputeIPs:
    internal_api:
EOF_CAT

for X in {10..200}; do
cat << EOF_CAT >> ips-from-pool.yaml
    - 172.16.2.$X
EOF_CAT
done

echo "    storage:" >> ips-from-pool.yaml

for X in {10..200}; do
cat << EOF_CAT >> ips-from-pool.yaml
    - 172.16.1.$X
EOF_CAT
done

echo "    tenant:" >> ips-from-pool.yaml

for X in {10..200}; do
cat << EOF_CAT >> ips-from-pool.yaml
    - 172.16.0.$X
EOF_CAT
done

sed -e "s|ComputeCount.*|ComputeCount: 200|" -i hostnamemap.yaml
