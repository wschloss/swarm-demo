# PREP WORK
# ---------------------
# Create the initial docker machines
docker-machine create manager && \
    docker-machine create worker1 && \
    docker-machine create worker2

# OPTIONAL
# Build the images for the basic service and log ip service on your own machine
# Be sure to tag with your own dockerhub account and push there if desired
docker build -t basic-service:0.1.0 . && \
    docker tag basic-service:0.1.0 wcschlosser/basic-service:0.1.0 && \
    docker push wcschlosser/basic-service:0.1.0

docker build -t log-ip-service:0.1.0 . && \
    docker tag log-ip-service:0.1.0 wcschlosser/log-ip-service:0.1.0 && \
    docker push wcschlosser/log-ip-service:0.1.0

# Copy the stack file onto the manager
docker-machine scp ./stack.yaml manager:~/stack.yaml

# SSH into the three machines in separate terminal windows
docker-machine ssh manager
docker-machine ssh worker1
docker-machine ssh worker2

# OPTIONAL
# Pre pull the images for both services so they are available on all machines
docker pull wcschlosser/basic-service:0.1.0 && \
    docker pull wcschlosser/log-ip-service:0.1.0 && \
    docker pull dockersamples/visualizer

# DEMO STUFF
# -------------------
# Create the visualizer container manually for easy swarm state viewing
docker run -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer

# Nothing there yet since swarm hasn't been created
# Now create the swarm on the manager docker-machine
docker swarm init --advertise-addr 192.168.99.100 # Note that your manager IP may be different

# It's easy to get tokens for joining the swarm. Try these on the manager.
docker swarm join-token manager # Token to join as a manager
docker swarm join-token worker # Token to join as a worker
# Join the two workers by executing the command from the join-token output on both worker machines

# Deploy a basic service to the swarm
docker service ls # Nothing shows up yet, this command only works on manager
docker service create --name basic-service --publish 8000:8080 --replicas 6 wcschlosser/basic-service:0.1.0 # Will result in two per node with the service exposed on port 8000 for all swarm hosts

# You can stream logs from all containers into one output
docker service ls # The service resource now exists
docker service logs basic-service # All basic service container logs will show up
docker service ps basic-service # Lists all containers backing this service

# Hit port 80 on a manager or worker to see load balancing. Note your machine IPs may differ
curl 192.168.99.100:8000
curl 192.168.99.101:8000
curl 192.168.99.102:8000

# Kill a container and the swarm will bring it back up. You should do a 'docker ps' to find a container id to try here
docker kill cefacc2a9fa1 # Use a container ID from your swarm on any node

# PART 2
# ---------------------
# Auto created ingress network is handling load balancing using the exposed port on each swarm host
docker network ls
docker network inspect ingress # Note the network has been synced across the nodes 'swarm' scope

# Service containers are in the ingress network, so they can ping each other. Replace container IDs and IP here with your own containers
docker exec -it ea601e42fe4d ping 10.255.0.9 # ping one service container from another
# But can't ping from the visualizer since it wasn't part of the service
docker exec -it c7e2e6a557d7 ping 10.255.0.9 # ping a service container from the viz container

# Could create docker networks and then attach containers to them
# But stack model makes it easier
# Stack file has basic service published and on workers only, and log service internal to the swarm (not in ingress network) and on managers only
docker stack deploy -c stack.yaml stack # Execute from the manager host
docker stack ls # The stack will show
docker stack services stack # Check out the services in the stack
docker stack ps stack # Check out the containers in the stack

# Note the default stack network is created and all stack containers attached, and the log service is not in the ingress network
docker network ls
docker network inspect stack_default
docker network inspect ingress
docker inspect 7674b2febce1 # log ip container id, use one of your own from the manager host

# Can ping the logging service from within the stack network though (service to service without exposing everything to the outside world)
docker exec -it d6bbcfb5fc53 ping 10.0.0.9 # ping log ip service container ip from a  basic-service container in the stack
docker exec -it d6bbcfb5fc53 curl 10.0.0.9:8080 # Same, but try a curl
docker service logs stack_log_ip_service
# The overlay network also allows service discovery through DNS
docker exec -it d6bbcfb5fc53 curl stack_log_ip_service:8080 # Curl the log ip service from basic-service container in the stack, but let DNS find the ip
docker exec -it d6bbcfb5fc53 curl log_ip_service:8080 # also aliased so stack name isn't needed

# Want to continue digging into docker swarm? Check out:
# Adding stack service to your own docker network (play with inter-stack calls)
# Updating / scaling containers and using DNS for service discovery
# Using Docker volumes and sharing them between service containers (can you implement a sidecar style pattern?)
# Using docker secrets for sharing secure tokens across containers
# Digging into multi manager setups and the RAFT protocol
# Schedule containers on other labels / features, such as equivalent containers across two separate data centers where each data center has a different number of hosts in the swarm
