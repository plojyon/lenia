# Grid size (default)
N ?= 256

# Compiler
CC = nvcc
COMPUTE_VERSION = 70

# Compiler flags
LDLIBS = -lm
CFLAGS = -Wno-deprecated-gpu-targets \
         -gencode=arch=compute_$(COMPUTE_VERSION),code=sm_$(COMPUTE_VERSION) \
         -O3 -Xcompiler --openmp,-Wall \
         -DLENIA_N=$(N)
		 -USE_CACHE=$(USE_CACHE)

SRC=src

SRCS=$(wildcard $(SRC)/*.cu)
SRCS+=$(wildcard $(SRC)/*.c)

HDRS = $(wildcard $(SRC)/*.h)

OBJS_1 = $(SRCS:$(SRC)/%.c=%.o)
OBJS = $(OBJS_1:$(SRC)/%.cu=%.o)

TARGET = lenia.out

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET) $(LDLIBS)

%.o: $(SRC)/%.cu $(HDRS)
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: $(SRC)/%.c $(HDRS)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)