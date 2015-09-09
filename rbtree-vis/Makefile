src = $(wildcard *.c)
obj = $(src:.c=.o)
bin = test

CC = gcc
CFLAGS = -pedantic -Wall -g
LDFLAGS = $(libgl) -ldrawtext

ifneq ($(shell uname -s), Darwin)
	libgl = -lGL -lglut
else
	libgl = -framework OpenGL -framework GLUT
endif

$(bin): $(obj)
	$(CC) -o $@ $(obj) $(LDFLAGS)

.PHONY: clean
clean:
	rm -f $(obj) $(bin)
