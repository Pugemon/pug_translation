"""
Author: LinXP
Convert an AngelCode BMFont XML (.fnt) into a custom binary format (.dat)
used by Terraria 3DS. 

This script:
  1. Parses the XML .fnt file to extract page and character data.
  2. Writes:
     - Two 32-bit zeroes (placeholder for signature/version).
     - One 8-bit length + filename of the texture page.
     - One 32-bit glyph count.
     - For each glyph:
         • 16-bit ID
         • four 32-bit values: x, y, width, height
         • one 32-bit zero (unused page index placeholder)
"""
import struct
import xml.etree.ElementTree as ET

tree = ET.parse('andy_48.fnt')
out = open("andy_48.dat", "wb")
img = b'0_andy_48.png'


out.write(struct.pack("L", 0))
out.write(struct.pack("L", 1))
out.write(struct.pack("b", len(img)))
out.write(img)

root = tree.getroot()
for count in root.findall('chars'):
   counts = count.get('count')
   out.write(struct.pack("L", int(counts)))

for char in root.iter('char'):
   out.write(struct.pack("h", int(char.attrib['id'])))
   out.write(struct.pack("L", int(char.attrib['x'])))
   out.write(struct.pack("L", int(char.attrib['y'])))
   out.write(struct.pack("L", int(char.attrib['width'])))
   out.write(struct.pack("L", int(char.attrib['height'])))
   out.write(struct.pack("L", 0))
