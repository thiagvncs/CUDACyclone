TARGET := CUDACyclone
SRC := CUDACyclone.cu CUDAHash.cu
OBJ := $(SRC:.cu=.o)
CC := nvcc

# Detecta compute capability do GPU local
GPU_ARCH_RAW := $(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -n1)
GPU_ARCH := $(shell echo $(GPU_ARCH_RAW) | tr -d '.')

# Lista de arquiteturas suportadas padrão (para GPUs RTX 30/40/etc.)
SM_ARCHS_DEFAULT := 75 80 86 89

# Verifica se é RTX 50-series (compute capability 120)
ifeq ($(GPU_ARCH),120)
    SM_ARCHS := 120
else
    SM_ARCHS := $(SM_ARCHS_DEFAULT) $(GPU_ARCH)
endif

# Monta gencode diretamente a partir de SM_ARCHS (sem filtro extra)
GENCODE := $(foreach arch,$(SM_ARCHS),-gencode arch=compute_$(arch),code=sm_$(arch))

# Flags CUDA/NVCC corrigidas
NVCC_FLAGS := -O3 -rdc=true -use_fast_math --ptxas-options=-O3 $(GENCODE)

# Evita modo C23 e glibc nova
CXXFLAGS := -std=c++17 -Xcompiler "-std=gnu++17"

# Linkagem correta
LDFLAGS := -lcudadevrt -cudart=static

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(NVCC_FLAGS) $(CXXFLAGS) $(OBJ) -o $@ $(LDFLAGS)

%.o: %.cu
	$(CC) $(NVCC_FLAGS) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJ)
