TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests/
CONFIG_HOME := $(abspath ../../..)

.PHONY: test test-e2e

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"

test-e2e:
	@sh tests/e2e_blink_gate.sh
