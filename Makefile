TARGET      := CUDACyclone
SRC         := CUDACyclone.cu CUDAHash.cu
OBJ         := $(SRC:.cu=.o)
CC          := nvcc

# Detecta compute capability do GPU local
GPU_ARCH_RAW := $(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -n1)
GPU_ARCH     := $(shell echo $(GPU_ARCH_RAW) | tr -d '.')

# Lista de arquiteturas suportadas
SM_ARCHS   := 75 80 86 89 120 $(GPU_ARCH)

# Remove duplicadas e inválidas (<50 ou >120)
FILTERED_ARCHS := $(shell for a in $(SM_ARCHS); do \
	if [ $$a -ge 50 ] && [ $$a -le 100 ]; then echo $$a; fi; \
	done | sort -u)

# Monta gencode correto
GENCODE    := $(foreach arch,$(FILTERED_ARCHS),-gencode arch=compute_$(arch),code=sm_$(arch))

# Flags CUDA/NVCC corrigidas
NVCC_FLAGS := -O3 -rdc=true -use_fast_math --ptxas-options=-O3 $(GENCODE)

# Evita modo C23 e glibc nova
CXXFLAGS   := -std=c++17 -Xcompiler "-std=gnu++17"

# Linkagem correta
LDFLAGS    := -lcudadevrt -cudart=static

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(NVCC_FLAGS) $(CXXFLAGS) $(OBJ) -o $@ $(LDFLAGS)

%.o: %.cu
	$(CC) $(NVCC_FLAGS) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJ)
