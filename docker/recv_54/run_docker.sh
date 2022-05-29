export DOCKER_TAG="recv-54"
CMD="docker run -tiv /mnt/huge:/mnt/huge --privileged $DOCKER_TAG"
echo "Running $CMD"
$CMD
