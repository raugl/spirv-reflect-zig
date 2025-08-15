# SPIRV-Reflect-zig

A port of the latest [SPIRV-Reflect](https://github.com/KhronosGroup/SPIRV-Reflect/) to the Zig
build system, and a Zig API for the library.

## Status

Provides zig structs and enums and a method API with zig errors. The `spvReflectEnumerateXXX`
functions were changed to take in an allocator which is used to return a populated slice, instead of
passing in pointers for the size and data. It is recommended to use a `std.head.ArenaAllocator` for
this purpose. If you would still prefer to use a stack buffer for enumerating, you can also use
`std.heap.FixedBufferAllocator`. The only missing feature compared to the C API is the ability to
only query the size.

I may have been too conservative with thy pointer types in places (non-null, const). If you discover
such a case, a PR would be welcome.

## Usage

The simplest way to use the library is via the zig API:

```zig
const spvr = @import("spirv_reflect");

var module = try spvr.ShaderModule.init(spv_code, .{});
defer module.deinit();
const desc_bindings = try module.enumerateDescriptorBindings(scratch);
defer scratch.free(desc_bindings);
```

It also exposes the plain C API with appropriate pointer types.

## SPIRV-Reflect version & upgrade process

The version of SPIRV-Reflect built is set in `build.zig.zon`.

To upgrade the static library, simply update this version.

If you are also using the Zig API, you'll need to also update any public enums or structures that
were changed in `src/root`. I recommend looking at a diff to see what changed. You can run the tests
to check for obvious mistakes in this process.
