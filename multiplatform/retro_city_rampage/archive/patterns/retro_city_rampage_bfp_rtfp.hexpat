#pragma authors "Pugemon"
#pragma description "Retro City Rampage (Old) gamedata.bfp archive v29"
#pragma endian little
#pragma magic [52 54 46 50] @ 0x00

import std.io;
import std.mem;
import std.string;
import hex.dec;
import type.magic;


const u64 ALIGNMENT = 32;

bool decompress_and_create_sections in;
bool print_verification_report in;


fn format_hash(u32 hash) {
    return std::format("0x{:08X}", hash);
};


struct BlockHeader {
    u32 compressed_size;
    u32 uncompressed_size;
} [[fixed_size(ALIGNMENT)]];

struct DataBlock {
    BlockHeader header;
    u8 compressed_data[header.compressed_size];
};

struct TocEntryFile {
    u32 hash [[format("format_hash")]]; 
    u32 offset;
    u32 uncompressed_size_toc;
};

struct TocEntryScript {
    u32 offset;
    u32 uncompressed_size_toc;
};

// --- Main archive structure ---
struct RCRArchive {
    type::Magic<"RTFP">;
    u32 file_count;
    // The engine checks these fields but doesn't use them. The only thing the game checks is:
    // files_aligned_alloc_size + scripts_aligned_alloc_size does not exceed u32
    u32 files_aligned_alloc_size [[comment("Sum of the sizes of each file, aligned to 32 bytes")]]; 
    u32 scripts_aligned_alloc_size [[comment("Sum of the sizes of each script, aligned to 32 bytes")]];
    std::mem::AlignTo<ALIGNMENT>;
    TocEntryFile files[this.file_count];
    // There is no alignment between the tables, they are packed together
    TocEntryScript scripts[256];
};


fn process_resource(u32 offset, u32 uncompressed_size, str section_name) {
    if (offset > 0 && uncompressed_size > 0) {
        try {
            DataBlock data_block @ offset;
            std::mem::Section section_handle = std::mem::create_section(section_name);
            std::mem::set_section_size(section_handle, uncompressed_size);

            if (data_block.header.compressed_size != data_block.header.uncompressed_size) {
                hex::dec::zlib_decompress(data_block.compressed_data, section_handle, 15);
            } else { 
                std::mem::copy_value_to_section(data_block.compressed_data, section_handle, 0);
            }
        } catch {
            std::print("Error processing resource '{}'\n", section_name);
        }
    }
};


RCRArchive archive @ 0x00;


if (decompress_and_create_sections) {
    for (u64 i = 0, i < archive.file_count, i += 1) {
        TocEntryFile file_entry = archive.files[i];
        str name = "File " + std::string::to_string(i) + " (" + format_hash(file_entry.hash) + ")";
        process_resource(file_entry.offset, file_entry.uncompressed_size_toc, name);
    }
    for (u64 i = 0, i < 256, i += 1) {
        TocEntryScript script_entry = archive.scripts[i];
        str name = "Script " + std::string::to_string(i);
        process_resource(script_entry.offset, script_entry.uncompressed_size_toc, name);
    }
}

// Print the report if enabled
if (print_verification_report) {
    std::print("\n--- ARCHIVE STRUCTURE VERIFICATION REPORT ---\n\n");
    std::print("1. Checking header and file counts:\n");
    std::print("  - Signature: '{}' (OK)\n", "RTFP");
    std::print("  - File count: {}\n", archive.file_count);
    std::print("  - Script count: 256 (const)\n");
    
    // --- Verifying allocation size for FILES ---
    u64 calculated_aligned_files_size = 0;
    for (u64 i = 0, i < archive.file_count, i += 1) {
        TocEntryFile file_entry = archive.files[i];
        u64 unaligned_size = file_entry.uncompressed_size_toc;
        calculated_aligned_files_size += (unaligned_size + ALIGNMENT - 1) & ~(ALIGNMENT - 1);
    }
    
    std::print("\n2. Verifying allocation size for files:\n");
    std::print("  - Expected size (from header): {}\n", archive.files_aligned_alloc_size);
    std::print("  - Calculated size (sum of aligned sizes): {}\n", calculated_aligned_files_size);
    if (archive.files_aligned_alloc_size == calculated_aligned_files_size) {
        std::print("  - Result: OK\n");
    } else {
        std::print("  - Result: MISMATCH! Difference: {}\n", s64(archive.files_aligned_alloc_size) - s64(calculated_aligned_files_size));
    }

    // --- Verifying allocation size for SCRIPTS ---
    u64 calculated_aligned_scripts_size = 0;
    for (u64 j = 0, j < 256, j += 1) {
        TocEntryScript script_entry = archive.scripts[j];
        u64 unaligned_size = script_entry.uncompressed_size_toc;
        calculated_aligned_scripts_size += (unaligned_size + ALIGNMENT - 1) & ~(ALIGNMENT - 1);
    }

    std::print("\n3. Verifying allocation size for scripts:\n");
    std::print("  - Expected size (from header): {}\n", archive.scripts_aligned_alloc_size);
    std::print("  - Calculated size (sum of aligned sizes): {}\n", calculated_aligned_scripts_size);
    if (archive.scripts_aligned_alloc_size == calculated_aligned_scripts_size) {
        std::print("  - Result: OK\n");
    } else {
        std::print("  - Result: MISMATCH! Difference: {}\n", s64(archive.scripts_aligned_alloc_size) - s64(calculated_aligned_scripts_size));
    }
    
    std::print("\n--- Verification complete ---\n");
}