#!/bin/bash

echo
echo "Press CTRL-C to stop this listing..."


while [ 1 ]; do
	squeue -u hust922
	sleep 30
done

