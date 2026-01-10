#!/usr/bin/env python3
"""
Comprehensive C++ compatibility fixer for ggml files.
Fixes all void* pointer assignments and function call casts.
"""

import re
import sys

def fix_quants_cpp(content):
    """Fix quants.cpp - comprehensive block type pointer fixes"""

    # Fix all block type variable assignments (both const and non-const)
    # Pattern: <type> * GGML_RESTRICT <var> = <source>;
    block_types = [
        'block_q4_0', 'block_q4_1', 'block_q5_0', 'block_q5_1',
        'block_q8_0', 'block_q8_1', 'block_q2_K', 'block_q3_K',
        'block_q4_K', 'block_q5_K', 'block_q6_K', 'block_q8_K',
        'block_tq1_0', 'block_tq2_0', 'block_mxfp4',
        'block_iq1_s', 'block_iq1_m', 'block_iq2_xxs', 'block_iq2_xs',
        'block_iq2_s', 'block_iq3_xxs', 'block_iq3_s', 'block_iq4_xs',
        'block_iq4_nl'
    ]

    for block_type in block_types:
        # Non-const pointer assignment
        pattern = rf'({block_type} \* GGML_RESTRICT \w+) = (v[xy]);'
        replacement = rf'\1 = ({block_type} *)\2;'
        content = re.sub(pattern, replacement, content)

        # Const pointer assignment
        pattern = rf'(const {block_type} \* GGML_RESTRICT \w+) = (v[xy]);'
        replacement = rf'\1 = (const {block_type} *)\2;'
        content = re.sub(pattern, replacement, content)

    # Fix quantize function calls - need to cast the second argument
    quantize_funcs = [
        'quantize_row_q4_0_ref', 'quantize_row_q4_1_ref',
        'quantize_row_q5_0_ref', 'quantize_row_q5_1_ref',
        'quantize_row_q8_0_ref', 'quantize_row_q8_1_ref',
        'quantize_row_mxfp4_ref',
        'quantize_row_q2_K_ref', 'quantize_row_q3_K_ref',
        'quantize_row_q8_K_ref'
    ]

    for func in quantize_funcs:
        # Extract block type from function name
        # quantize_row_q4_0_ref -> block_q4_0
        block_name = func.replace('quantize_row_', '').replace('_ref', '')
        block_type = f'block_{block_name}'

        # Fix function calls: func(x, y, k) -> func(x, (block_type *)y, k)
        pattern = rf'{func}\(([^,]+), ([^,\)]+),'
        replacement = rf'{func}(\1, ({block_type} *)\2,'
        content = re.sub(pattern, replacement, content)

    return content


def fix_ggml_quants_cpp(content):
    """Fix ggml-quants.cpp - fix function call casts"""

    # Map of functions to their block types
    func_to_block = {
        'quantize_row_q2_K_ref': 'block_q2_K',
        'quantize_row_q3_K_ref': 'block_q3_K',
        'quantize_row_q4_K_ref': 'block_q4_K',
        'quantize_row_q5_K_ref': 'block_q5_K',
        'quantize_row_q6_K_ref': 'block_q6_K',
        'quantize_row_q4_0_ref': 'block_q4_0',
        'quantize_row_q4_1_ref': 'block_q4_1',
        'quantize_row_q5_0_ref': 'block_q5_0',
        'quantize_row_q5_1_ref': 'block_q5_1',
        'quantize_row_q8_0_ref': 'block_q8_0',
        'quantize_row_mxfp4_ref': 'block_mxfp4',
        'quantize_row_tq1_0_ref': 'block_tq1_0',
        'quantize_row_tq2_0_ref': 'block_tq2_0',
    }

    for func, block_type in func_to_block.items():
        # Fix calls: func(src, dst, ...) -> func(src, (block_type *)dst, ...)
        pattern = rf'{func}\(([^,]+), ([^,]+),'
        replacement = rf'{func}(\1, ({block_type} *)\2,'
        content = re.sub(pattern, replacement, content)

    return content


def add_version_defines(content):
    """Add GGML_VERSION and GGML_COMMIT defines if missing"""

    # Check if already defined
    if 'GGML_VERSION' not in content:
        # Add at the top after first #include block
        includes_end = content.find('\n\n')
        if includes_end > 0:
            defines = '\n// Version info for Swift Package Manager build\n'
            defines += '#ifndef GGML_VERSION\n'
            defines += '#define GGML_VERSION "0.0.0"\n'
            defines += '#endif\n'
            defines += '#ifndef GGML_COMMIT\n'
            defines += '#define GGML_COMMIT "unknown"\n'
            defines += '#endif\n'
            content = content[:includes_end] + defines + content[includes_end:]

    return content


def main():
    if len(sys.argv) != 3:
        print("Usage: fix-cpp-compat.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Apply appropriate fixes based on filename
    if 'quants.cpp' in input_file and 'ggml-quants' not in input_file:
        # This is ggml-cpu/quants.cpp
        content = fix_quants_cpp(content)
    elif 'ggml-quants.cpp' in input_file:
        content = fix_ggml_quants_cpp(content)
    elif 'ggml.cpp' in input_file:
        content = add_version_defines(content)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Fixed {input_file} -> {output_file}")


if __name__ == '__main__':
    main()
