.PHONY: all

all:
	openscad -o lid.stl  -D 'show="lid"'  housing.scad && \
	openscad -o base.stl -D 'show="base"' housing.scad
