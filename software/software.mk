include $(ETHERNET_DIR)/config.mk

#submodules
ifneq (INTERCON,$(filter INTERCON, $(SUBMODULES)))
SUBMODULES+=INTERCON
INTERCON_DIR ?=$(DMA_DIR)/submodules/INTERCON
include $(INTERCON_DIR)/software/software.mk
endif

#include
INCLUDE+=-I$(ETHERNET_SW_DIR)

#headers
HDR+=$(ETHERNET_SW_DIR)/*.h

#headers
HDR+=eth_mem_map.h \
eth_frame_struct.h

#sources
SRC+=$(ETHERNET_SW_DIR)/iob-eth.c

#define ETH_RMAC_ADDR
ifneq ($(SIM),)
DEFINE+=$(defmacro)ETH_RMAC_ADDR=0x001200feaa00
else
DEFINE+=$(defmacro)ETH_RMAC_ADDR=0x$(RMAC_ADDR)
endif

#define ETH_DMA
ifeq ($(ETH_DMA),1)
DEFINE+=$(defmacro)ETH_DMA 
endif

#define ETH_DEBUG_PRINT
ifeq ($(ETH_DEBUG_PRINT),1)
DEFINE+=$(defmacro)ETH_DEBUG_PRINT
endif

DEFINE+=$(defmacro)DDR_MEM=$(DDR_MEM)

eth_mem_map.h: $(ETHERNET_DIR)/hardware/include/ETHERNETsw_reg_def.vh
	@sed -n 's/`ETH_ADDR_W//p' $< | sed 's/`/#/g' | sed "s/'d//g" > ./$@

eth_frame_struct.h: $(ETHERNET_DIR)/hardware/include/ETHERNET.vh
	@sed -n '/ ETH_PREAMBLE /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed "s/8'h/0x/g" | sed 's/`//g' > ./$@
	@sed -n '/ ETH_SFD /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed "s/8'h/0x/g" | sed 's/`//g' >> ./$@
	@sed -n '/ ETH_TYPE_H /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed "s/8'h/0x/g" | sed 's/`//g' >> ./$@
	@sed -n '/ ETH_TYPE_L /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed "s/8'h/0x/g" | sed 's/`//g' >> ./$@
	@echo '' >> ./$@
	@sed -n '/ ETH_NBYTES /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed 's/`//g' >> ./$@
	@echo '' >> ./$@
	@sed -n '/ PREAMBLE_LEN /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed 's/`//g' >> ./$@
	@sed -n '/ MAC_ADDR_LEN /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed 's/`//g' >> ./$@
	@sed -n '/ HDR_LEN /p' $(ETHERNET_DIR)/hardware/include/ETHERNET.vh | sed 's/`define/#define/g' | sed 's/`//g' >> ./$@