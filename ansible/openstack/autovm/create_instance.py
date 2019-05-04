# This script creates an instance called "instance2"

from keystoneclient.v2_0 import client as keystone_client
from glanceclient import Client as glance_client
from novaclient.v1_1 import client as nova_client

keystone = keystone_client.Client(username='userj', password='Password123', tenant_name='userj', auth_url='http://controller:35357/v2.0')
endpoint = keystone.service_catalog.url_for(service_type='image', endpoint_type='publicURL')
glance = glance_client('2', endpoint, token=keystone.auth_token)
nova = nova_client.Client('userj', 'Password123', 'userj', 'http://controller:35357/v2.0')
nova.servers.create(name='instance2', flavor=nova.flavors.find(name="m1.small"), image=nova.images.find(name="ubuntu-trusty-14.04"), nics=[{'net-id': '71ae39ba-28a0-4635-baa7-8bdc28dac1ea'}], key_name="demo-key")
