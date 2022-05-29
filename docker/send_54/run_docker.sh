export DOCKER_TAG="send/image"
CMD="docker run -tiv /dev/hugepages:/dev/hugepages --privileged $DOCKER_TAG"
echo "Running $CMD"
$CMD

