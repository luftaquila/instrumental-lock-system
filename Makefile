KICAD9_3DMODEL_DIR := /Applications/KiCad/KiCad.app/Contents/SharedSupport/3dmodels
PCB := ils.kicad_pcb

.PHONY: all pcb housing

all: pcb housing

pcb:
	KICAD9_3DMODEL_DIR=$(KICAD9_3DMODEL_DIR) \
	kicad-cli pcb export stl --include-tracks --include-pads --include-zones $(PCB)

housing:
	openscad -o lid.stl  -D 'show="lid"'  housing.scad && \
	openscad -o base.stl -D 'show="base"' housing.scad
