# all: printk.o

# printk.o: printk.c
# 	${GCC} ${CFLAG} -c printk.c

# clean:
# 	$(shell rm *.o 2>/dev/null)
C_SRC = $(sort $(wildcard *.c))
OBJ = $(patsubst %.c, %.o, $(C_SRC))

all: $(OBJ)

%.o: %.c 
	${GCC} ${CFLAG} -c $<

clean:
	$(shell rm *.o 2>/dev/null)