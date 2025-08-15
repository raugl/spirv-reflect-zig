const std = @import("std");
const spv = @import("spirv_reflect");
const c = @cImport({
    @cInclude("spirv_reflect.h");
});

const meta = std.meta;
const testing = std.testing;

fn checkType(C: type, Zig: type) !void {
    inline for (meta.fields(C), meta.fields(Zig)) |c_field, zig_field| {
        try testing.expectEqualStrings(c_field.name, zig_field.name);
        try testing.expectEqual(@sizeOf(c_field.type), @sizeOf(zig_field.type));
        try testing.expectEqual(c_field.alignment, zig_field.alignment);
        try testing.expectEqual(c_field.alignment, zig_field.alignment);
        try testing.expectEqual(
            @offsetOf(C, c_field.name),
            @offsetOf(Zig, zig_field.name),
        );
    }
    try testing.expectEqual(@sizeOf(C), @sizeOf(Zig));
}

test "struct sizes" {
    try checkType(c.SpvReflectNumericTraits, spv.NumericTraits);
    try checkType(c.SpvReflectImageTraits, spv.ImageTraits);
    try checkType(c.SpvReflectArrayTraits, spv.ArrayTraits);
    try checkType(c.SpvReflectBindingArrayTraits, spv.BindingArrayTraits);
    try checkType(c.SpvReflectTypeDescription, spv.TypeDescription);
    try checkType(c.SpvReflectInterfaceVariable, spv.InterfaceVariable);
    try checkType(c.SpvReflectBlockVariable, spv.BlockVariable);
    try checkType(c.SpvReflectDescriptorBinding, spv.DescriptorBinding);
    try checkType(c.SpvReflectDescriptorSet, spv.DescriptorSet);
    try checkType(c.SpvReflectEntryPoint, spv.EntryPoint);
    try checkType(c.SpvReflectCapability, spv.Capability);
    try checkType(c.SpvReflectSpecializationConstant, spv.SpecializationConstant);
    try checkType(c.SpvReflectShaderModule, spv.ShaderModule);
}
