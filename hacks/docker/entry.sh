#!/bin/bash

if [ -f /root/.vllm/.env ]; then
	source /root/.vllm/.env
fi

vllm "$@"
