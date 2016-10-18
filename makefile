CC = nvcc
LFLAGS = -o

all : 
		$(CC) $(LFLAGS) exe main.cu filterise.cu my_functions.cu

clean : 
		rm -rf exe out.raw
