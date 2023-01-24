# simple hacky way to convert strings to lowercase, usage: NEW_VAR = $(call lc,$(VAR))
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

CC:=gcc
STD:=c11
CFLAGS:=-Isrc/ -Wall -MMD -MP $(shell pkg-config --cflags freetype2) $(shell pkg-config --cflags sdl2)
LFLAGS:=-lm -lGL $(shell pkg-config --libs freetype2) $(shell pkg-config --libs sdl2)

SDL2_STATIC_LINK:=1
SDL2_LFLAGS:=
SDL2_CFLAGS:=-DSDL_MAIN_HANDLED=1
BUILD_TARGET:=debug

ifeq ($(call lc,$(BUILD_TARGET)),debug)
	CFLAGS+=-g -O0
else
	ifeq ($(call lc,$(BUILD_TARGET)),release)
		CFLAGS+=-O3
	else
$(error Invalid Build Target: "$(BUILD_TARGET)")
	endif
endif

SRCS_C:=$(wildcard src/*.c) $(wildcard demo/*.c)
OBJS_C:=$(SRCS_C:.c=.o)
DEPENDS:=$(patsubst %.c,%.d,$(SRCS_C))
bin:=microui-demo.elf

ifeq ($(call lc,$(BUILD_TARGET)),debug)
	CFLAGS+=-O0 -g
else
	CFLAGS+=-O2
endif

ifeq ($(OS),Windows_NT)
	ifeq ($(SDL2_STATIC_LINK),1)
		SDL2_LFLAGS+=-static-libstdc++ -Wl,-Bstatic -lSDL2main -lSDL2 -Wl,-Bdynamic
	else
		SDL2_LFLAGS+=-lSDL2main -lSDL2
	endif
	LFLAGS+=-lopengl32
	SDL2_LFLAGS+=$(addprefix -l,winmm gdi32 imm32 ole32 oleaut32 shell32 version uuid setupapi)
	ifeq ($(call lc,$(BUILD_TARGET)),debug)
		LFLAGS+=-mconsole
	else
		LFLAGS+=-mwindows
	endif
	bin=microui-demo.exe
else
	UNAME_S:=$(shell uname -s)
	_libs:=m pthread

	ifeq ($(UNAME_S),Linux)
		ifeq ($(SDL2_STATIC_LINK),1)
			SDL2_LFLAGS+=-Wl,-Bstatic -lSDL2 -Wl,-Bdynamic -lX11 -lXext -lXi -lXfixes -lXrandr -lXcursor
		else
			SDL2_LFLAGS+=-lSDL2
		endif

		_libs+=dl
		# On POSX Use Address Sanitizers in Debug Mode
		ifeq ($(CC),gcc)
			ifeq ($(call lc,$(BUILD_TARGET)),debug)
				CFLAGS+=-fsanitize=address -fsanitize=undefined
				LFLAGS+=-fsanitize=address -fsanitize=undefined -lasan -lubsan
			endif
		endif
	endif
	ifeq ($(UNAME_S),Darwin)
		LFLAGS+=$(addprefix -framework , OpenGL Cocoa)
		SDL2_LFLAGS:=-lSDL2
	endif

	LFLAGS+=$(addprefix -l,$(_libs))
endif

# make all BUILD_TARGET=debug/release
all: $(bin)

-include $(DEPENDS)

%.o: %.c
	@echo "CC  -" $<
	@$(CC) --std=$(STD) $(CFLAGS) $(SDL2_CFLAGS) -c $< -o $@

$(bin): $(OBJS_C)
	@echo Linking $@
	@$(CC) --std=$(STD) $(OBJS_C) $(LFLAGS) $(SDL2_LFLAGS) -o $@

.PHONY: run
.PHONY: clean

# make run BUILD_TARGET=debug/release
run: $(bin)
	@./$(bin)

# make clean
clean:
	@$(RM) $(bin) $(OBJS_C) $(DEPENDS)

