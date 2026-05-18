function test-integration --arg filter
	make BIND_DIR=. TEST_INTEGRATION_USE_GRAPHDRIVER=1 DOCKER_GRAPHDRIVER=vfs TEST_IGNORE_CGROUP_CHECK=1 TEST_FILTER=$filter test-integration
end
