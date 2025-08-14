function test-integration --arg filter
	make BIND_DIR=. DOCKER_GRAPHDRIVER= TEST_IGNORE_CGROUP_CHECK=1 TEST_FILTER=$filter test-integration
end
