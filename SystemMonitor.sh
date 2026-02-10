#!/bin/bash
pkill -f tmux
pkill -f htop
pkill -f nvtop
pkill -f intel_gpu_top
pkill -f sensors
pkill -f iotop

if nvidia-smi
then
    tmux new-session \;  \
      split-window -v -l 20\; \
      select-pane -t 0 \; \
      split-window -h -l 50\; \
      select-pane -t 2 \; \
      split-window -h -l 60\; \
      select-pane -t 3 \; \
      split-window -v -l 40 \; \
      select-pane -t 0 \; \
      send-keys 'htop' C-m \; \
      select-pane -t 1 \; \
      send-keys 'sudo powertop' C-m \; \
      select-pane -t 2 \; \
      send-keys 'nvtop' C-m \; \
      select-pane -t 3 \; \
      send-keys 'watch sudo sensors' C-m \; \
      select-pane -t 4\; \
      send-keys 'sudo iotop' C-m \; \
	  select-pane -t 0
else 
    tmux new-session \;  \
      split-window -v -l 20\; \
      select-pane -t 0 \; \
      split-window -h -l 50\; \
      select-pane -t 2 \; \
      split-window -h -l 40\; \
      select-pane -t 3 \; \
      split-window -v -l 40 \; \
      select-pane -t 0 \; \
      send-keys 'htop' C-m \; \
      select-pane -t 1 \; \
      send-keys 'sudo powertop' C-m \; \
      select-pane -t 2 \; \
      send-keys 'sudo intel_gpu_top' C-m \; \
      select-pane -t 3 \; \
      send-keys 'watch sudo sensors' C-m \; \
      select-pane -t 4\; \
      send-keys 'sudo iotop' C-m \; \
      select-pane -t 0
fi
