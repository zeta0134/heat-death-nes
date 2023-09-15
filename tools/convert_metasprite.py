#!/usr/bin/env python3

from PIL import Image


import sys, math
from dataclasses import dataclass

@dataclass
class RawPattern:
  data: [int]
  x: int
  y: int
  subpalette: int

@dataclass 
class IndexedPattern:
  tile_id: int
  x: int
  y: int
  horizontal_flip: bool
  vertical_flip: bool
  subpalette: int

def bits_to_byte(bit_array):
  byte = 0
  for i in range(0,8):
    byte = byte << 1;
    byte = byte + bit_array[i];
  return byte

def hardware_tile_to_bitplane(index_array):
  # Note: expects an 8x8 array of palette indices. Returns a 16-byte array of raw NES data
  # which encodes this tile's data as a bitplane for the PPU hardware
  low_bits = [x & 0x1 for x in index_array]
  high_bits = [((x & 0x2) >> 1) for x in index_array]
  low_bytes = [bits_to_byte(low_bits[i:i+8]) for i in range(0,64,8)]
  high_bytes = [bits_to_byte(high_bits[i:i+8]) for i in range(0,64,8)]
  return low_bytes + high_bytes

def identify_subpalette(index_array):
  min_subpalette_index = 4
  for i in range(0, len(index_array)):
    palette_index = index_array[i] & 0x3
    if palette_index != 0:
      subpalette_index = index_array[i] >> 2
      if subpalette_index > 0 and subpalette_index < 4 and subpalette_index < min_subpalette_index:
        min_subpalette_index = subpalette_index
  return min_subpalette_index - 1

def read_cels(filename, cel_width, cel_height):
  im = Image.open(filename)
  num_frames = im.width / cel_width
  num_layers = im.height / cel_height
  assert num_frames % 1 == 0, "Animation width must be a multiple of cel width"
  assert num_layers % 1 == 0, "Animation height must be a multiple of cel height"
  assert im.getpalette() != None, "Non-paletted animation found! This is unsupported: " + filename

  num_frames = int(num_frames)
  num_layers = int(num_layers)

  frames = []
  for f in range(0, num_frames):
    cels = []
    for l in range(0, num_layers):
      left  = f * cel_width
      upper = l * cel_height
      right = left + cel_width
      lower = upper + cel_height
      cels.append(im.crop((left, upper, right, lower)))
    frames.append(cels)
  return frames

def is_truly_transparent(palette_index):
  return palette_index in range(0, 4)

def align_tiles_topleft(image):
  leftmost_pixel = image.width
  topmost_pixel  = image.height
  for x in range(0, image.width):
    for y in range(0, image.height):
      palette_index = image.getpixel((x, y))
      if not is_truly_transparent(palette_index):
        if x < leftmost_pixel:
          leftmost_pixel = x
        if y < topmost_pixel:
          topmost_pixel = y
  if leftmost_pixel == image.width or topmost_pixel == image.height:
    return (image, 0, 0)

  left  = leftmost_pixel
  upper = topmost_pixel
  right = math.floor((image.width - leftmost_pixel) / 8) * 8 + leftmost_pixel
  lower = math.floor((image.height - topmost_pixel) / 8) * 8 + topmost_pixel
  cropped_image = image.crop((left, upper, right, lower))

  return (cropped_image, leftmost_pixel, topmost_pixel)

def extract_patterns(image):
  (aligned_image, leftmost_pixel, topmost_pixel) = align_tiles_topleft(image)

  raw_patterns = []
  for x in range(0, aligned_image.width, 8):
    for y in range(0, aligned_image.height, 8):
      candidate_tile = aligned_image.crop((x, y, x+8, y+8)).getdata()
      raw_bytes = hardware_tile_to_bitplane(candidate_tile)
      if sum(raw_bytes) != 0:
        identified_subpalette = identify_subpalette(candidate_tile)
        pos_x = leftmost_pixel + x
        pos_y = topmost_pixel + y
        raw_patterns.append(RawPattern(data=raw_bytes, x=pos_x, y=pos_y, subpalette=identified_subpalette))
  return raw_patterns

def extract_frame_patterns(frame_cels):
  frame_raw_patterns = []
  for f in range(0, len(frame_cels)):
    raw_patterns = []
    for l in reversed(range(0, len(frame_cels[0]))):
      raw_patterns = raw_patterns + extract_patterns(frame_cels[f][l])
    frame_raw_patterns.append(raw_patterns)
  return frame_raw_patterns

def patterns_match(pattern_a, pattern_b):
  for i in range(0, 16):
    if pattern_a[i] != pattern_b[i]:
      return False
  return True

def chr_list_contains_patterns(chr_patterns, candidate_pattern):
  candidate_index = None
  hflip = False
  vflip = False
  for i in range(0, len(chr_patterns)):
    if patterns_match(chr_patterns[i], candidate_pattern):
      return (i, hflip, vflip)
  return (candidate_index, hflip, vflip)

def deduplicate_patterns(frame_raw_patterns):
  chr_patterns = []
  frame_indexed_patterns = []
  for f in range(0, len(frame_raw_patterns)):
    indexed_patterns = []
    for p in range(0, len(frame_raw_patterns[f])):
      pattern = frame_raw_patterns[f][p]
      (candidate_index, hflip, vflip) = chr_list_contains_patterns(chr_patterns, pattern.data)
      if candidate_index != None:
        indexed_patterns.append(IndexedPattern(tile_id=candidate_index, x=pattern.x, y=pattern.y, 
          horizontal_flip=hflip, vertical_flip=vflip, subpalette=pattern.subpalette))
      else:
        chr_patterns.append(pattern.data)
        indexed_patterns.append(IndexedPattern(tile_id=len(chr_patterns)-1, x=pattern.x, y=pattern.y,
          horizontal_flip=False, vertical_flip=False, subpalette=pattern.subpalette))
    frame_indexed_patterns.append(indexed_patterns)
  return (chr_patterns, frame_indexed_patterns)

if __name__ == '__main__':
  if len(sys.argv) != 7:
    print("Usage: convert_metasprite.py input_image.png output.chr output.incs <width> <height> <framebase>")
    sys.exit(-1)
  input_image = sys.argv[1]
  output_chr = sys.argv[2]
  output_animation = sys.argv[3]
  width_pixels = int(sys.argv[4])
  height_pixels = int(sys.argv[5])
  base_framerate = int(sys.argv[6])

  frame_cels = read_cels(input_image, width_pixels, height_pixels)
  print(f"Read {len(frame_cels)} frames, with {len(frame_cels[0])} layers each")
  frame_raw_patterns = extract_frame_patterns(frame_cels)
  (chr_patterns, frame_indexed_patterns) = deduplicate_patterns(frame_raw_patterns)

  print(f"Found {len(chr_patterns)} unique tiles!")
  for f in range(0, len(frame_indexed_patterns)):
    print(f"Frame {f} has these indexed patterns:")
    for p in range(0, len(frame_indexed_patterns[f])):
      print(frame_indexed_patterns[f][p])
