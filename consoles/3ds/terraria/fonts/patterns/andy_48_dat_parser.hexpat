#pragma description "Terraria 3DS Fonts andy_48.dat parser"
#pragma author "Pugemon"
#pragma endian little
#include <std/io.pat>

// -----------------------------------------------------------------------------
// NOTE: In this .dat variant, the first 4 bytes (signature + version)
// are truncated/zero—only the Page and Glyph blocks remain.
// -----------------------------------------------------------------------------
struct BMFontInfo {
    char signature[3];  // Would be "BMF"
    u8   version;       // Would be 3
} [[name("BMFont")]];

// -----------------------------------------------------------------------------
// Page block (type 3):
//   - id           : zero-based index of this texture page
//   - nameLength   : length of the filename string
//   - name         : null-terminated texture filename
//   - gliphsCount  : total number of glyph entries following
// -----------------------------------------------------------------------------
struct Page {
    u32 id;                
    u8  nameLength;        
    char name[nameLength]; 
    u32 gliphsCount;       
} [[name("Page Info")]];

// -----------------------------------------------------------------------------
// Combined header: BMFontInfo (omitted) + single Page block.
// -----------------------------------------------------------------------------
struct Header {
    BMFontInfo bmfInfo;  
    Page      pageInfo;  
} [[name("Header")]];

// -----------------------------------------------------------------------------
// A glyph’s “Symbol” union lets you view the same 16-bit value
// either as its raw numeric ID or directly as a UTF-16 character.
// -----------------------------------------------------------------------------
union Symbol {
    u16    id;      // Raw glyph ID (e.g. Unicode codepoint or reserved sprite)
    char16 symbol;  // Interpreted as a UTF-16 character
} [[inline, single_color]];

// -----------------------------------------------------------------------------
// Glyph block (type 4):
//   We only use these fields from the full BMFont v3 record.
//   IMPORTANT: IDs 128–145 are reserved for 3DS button-sprite icons.
// -----------------------------------------------------------------------------
struct Glyph {
    Symbol symbol;      // Numeric ID <-> UTF-16 char
    u32    x, y;        // Top-left coords in the texture atlas
    u32    width, height; // Sprite dimensions
    u32    page;        // Texture page index
    
    // Validation for reserved button-sprite glyphs
    if (symbol.id >= 128 && symbol.id <= 145 && height != 36) {
        // Use printf-style error formatting instead of string concatenation
        str error_str = std::format(
            "Glyph ID {}: reserved button sprite must have height=36, found height={}",
            symbol.id,
            height
        );
        std::warning(error_str);
    }
};

// -----------------------------------------------------------------------------
// Full glyph table at file offset 0x00:
//   Skip signature/version, read the Page block, then
//   read `pageInfo.gliphsCount` entries of Gliph.
// -----------------------------------------------------------------------------
struct GlyphCoords {
    Header header;                      
    Glyph  glyphs[header.pageInfo.gliphsCount] [[name("Glyphs")]]; 
};

// Base address of the structure in the file:
GlyphCoords coords @ 0x00;
