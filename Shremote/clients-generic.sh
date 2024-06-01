#!/bin/bash

./shremote.py prepare_machines.yml clients -- --clients-generic --cmd "$1"
