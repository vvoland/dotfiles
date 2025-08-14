function test-integration-c8d --arg filter
	make BIND_DIR=. BUILDFLAGS='-race' DOCKER_GRAPHDRIVER=overlayfs TEST_INTEGRATION_USE_SNAPSHOTTER=1 TEST_IGNORE_CGROUP_CHECK=1 TEST_FILTER=$filter test-integration
end
