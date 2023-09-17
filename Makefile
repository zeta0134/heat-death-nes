.PHONY: all clean dir run

ARTDIR := art
SOURCEDIR := prg
BUILDDIR := build
ROM_NAME := $(notdir $(CURDIR)).nes
DBG_NAME := $(notdir $(CURDIR)).dbg

# Assembler files, for building out the banks
PRG_ASM_FILES := $(wildcard $(SOURCEDIR)/*.s)
O_FILES := \
  $(patsubst $(SOURCEDIR)/%.s,$(BUILDDIR)/%.o,$(PRG_ASM_FILES))

LEVEL_TMX_FILES := $(wildcard $(ARTDIR)/levels/*.tmx)
LEVEL_INCS_FILES := \
	$(patsubst $(ARTDIR)/levels/%.tmx,$(BUILDDIR)/levels/%.incs,$(LEVEL_TMX_FILES)) \

ANIMATION_PNG_FILES := $(wildcard $(ARTDIR)/animations/*.png)
ANIMATION_INCS_FILES := \
	$(patsubst $(ARTDIR)/animations/%.png,$(BUILDDIR)/animations/%.anim.incs,$(ANIMATION_PNG_FILES)) \

.PRECIOUS: $(BIN_FILES) $(ANIMATED_CHR_FILES) $(STATIC_CHR_FILES) $(LEVEL_INCS_FILES)

all: dir $(ROM_NAME)

dir:
	@mkdir -p build
	@mkdir -p build/levels
	@mkdir -p build/animations

clean:
	-@rm -rf build
	-@rm -f $(ROM_NAME)
	-@rm -f $(DBG_NAME)

run: dir $(ROM_NAME)
	rusticnes-sdl $(ROM_NAME)

mesen: dir $(ROM_NAME)
	vendor/Mesen $(ROM_NAME)

osx: dir $(ROM_NAME)
	/Users/zeta0134/Github/Mesen2/bin/osx-arm64/Release/osx-arm64/publish/Mesen $(ROM_NAME)

debug: dir $(ROM_NAME)
	mono vendor/Mesen-X-v1.0.0.exe $(ROM_NAME) debug_entity_0.lua

profile: dir $(ROM_NAME)
	mono vendor/Mesen-X-v1.0.0.exe $(ROM_NAME) debug_color_performance.lua

everdrive: dir $(ROM_NAME)
	mono vendor/edlink-n8.exe $(ROM_NAME)

$(ROM_NAME): $(SOURCEDIR)/action53.cfg $(O_FILES)
	ld65 -m $(BUILDDIR)/map.txt --dbgfile $(DBG_NAME) -o $@ -C $^

$(BUILDDIR)/%.o: $(SOURCEDIR)/%.s $(BIN_FILES) $(LEVEL_INCS_FILES) $(ANIMATION_INCS_FILES)
	ca65 -g -o $@ $<

$(BUILDDIR)/animated_tiles/%.chr: $(ARTDIR)/animated_tiles/%.png
	tools/animatedtile.py $< $@

$(BUILDDIR)/static_tiles/%.chr: $(ARTDIR)/static_tiles/%.png
	tools/statictile.py $< $@

$(BUILDDIR)/levels/%.incs: $(ARTDIR)/levels/%.tmx
	tools/convert_level.py $< $@

$(BUILDDIR)/animations/%.anim.incs: $(ARTDIR)/animations/%.png
	tools/convert_metasprite.py $< $(basename $(basename $@)).chr.incs $@ 64 64 4