#!/bin/bash
echo -n "The decimal value of $@="
echo "ibase=16; $@"|bc