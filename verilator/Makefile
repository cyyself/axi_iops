TOP_NAME := axi_iops
INC_FILE := ../axi_iops.v
.PHONY: obj_dir/V$(TOP_NAME) clean
obj_dir/V$(TOP_NAME): $(INC_FILE) *.hpp *.cpp
	verilator --trace --trace-structs --cc -Wno-fatal --exe -LDFLAGS "-lpthread" --build sim.cpp $(INC_FILE) --top $(TOP_NAME) --CFLAGS "-Os" -j 32

clean:
	rm -rf obj_dir