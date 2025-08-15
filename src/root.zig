const std = @import("std");
const spv = @import("spirv.zig");
const mem = std.mem;

pub const Error = error{
    NotReady,
    ParseFailed,
    AllocFailed,
    RangeExceeded,
    NullPointer,
    InternalError,
    CountMismatch,
    ElementNotFound,
    SpirvInvalidCodeSize,
    SpirvInvalidMagicNumber,
    SpirvUnexpectedEof,
    SpirvInvalidIdReference,
    SpirvSetNumberOverflow,
    SpirvInvalidStorageClass,
    SpirvRecursion,
    SpirvInvalidInstruction,
    SpirvUnexpectedBlockData,
    SpirvInvalidBlockMemberReference,
    SpirvInvalidEntryPoint,
    SpirvInvalidExecutionMode,
    SpirvMaxRecursiveExceeded,
};

pub const Result = enum(u32) {
    success,
    not_ready,
    error_parse_failed,
    error_alloc_failed,
    error_range_exceeded,
    error_null_pointer,
    error_internal_error,
    error_count_mismatch,
    error_element_not_found,
    error_spirv_invalid_code_size,
    error_spirv_invalid_magic_number,
    error_spirv_unexpected_eof,
    error_spirv_invalid_id_reference,
    error_spirv_set_number_overflow,
    error_spirv_invalid_storage_class,
    error_spirv_recursion,
    error_spirv_invalid_instruction,
    error_spirv_unexpected_block_data,
    error_spirv_invalid_block_member_reference,
    error_spirv_invalid_entry_point,
    error_spirv_invalid_execution_mode,
    error_spirv_max_recursive_exceeded,
};

pub const ModuleFlags = packed struct(u32) {
    /// Disables copying of SPIR-V code when a SPIRV-Reflect shader module is
    /// created. It is the responsibility of the calling program to ensure that
    /// the pointer remains valid and the memory it's pointing to is not freed
    /// while SPIRV-Reflect operations are taking place. Freeing the backing
    /// memory will cause undefined behavior or most likely a crash. This is
    /// flag is intended for cases where the memory overhead of storing the
    /// copied SPIR-V is undesirable.
    no_copy: bool = false,
    _padding: u31 = 0,
};

pub const TypeFlags = packed struct(u32) {
    void: bool = false,
    bool: bool = false,
    int: bool = false,
    float: bool = false,
    _padding0: u4 = 0,
    vector: bool = false,
    matrix: bool = false,
    _padding1: u6 = 0,
    external_image: bool = false,
    external_sampler: bool = false,
    external_sampled_image: bool = false,
    external_block: bool = false,
    external_acceleration_structure: bool = false,
    _padding2: u3 = 0,
    @"struct": bool = false,
    array: bool = false,
    ref: bool = false,
    _padding: u5 = 0,

    const external_mask = TypeFlags{
        .external_image = true,
        .external_sampler = true,
        .external_sampled_image = true,
        .external_block = true,
        .external_acceleration_structure = true,
        ._padding2 = 0x7,
    };
};

/// Note: HLSL row_major and column_major decorations are reversed in SPIR-V.
/// Meaning that matrices declrations with row_major will get reflected as
/// column_major and vice versa. The row and column decorations get appied
/// during the compilation. SPIRV-Reflect reads the data as is and does not make
/// any attempt to correct it to match what's in the source.
///
/// The Patch, PerVertex, and PerTask are used for Interface variables that can
/// have array
pub const DecorationFlags = packed struct(u32) {
    block: bool = false,
    buffer_block: bool = false,
    row_major: bool = false,
    column_major: bool = false,
    built_in: bool = false,
    noperspective: bool = false,
    flat: bool = false,
    non_writable: bool = false,
    relaxed_precision: bool = false,
    non_readable: bool = false,
    patch: bool = false,
    per_vertex: bool = false,
    per_task: bool = false,
    weight_texture: bool = false,
    block_match_texture: bool = false,
    _padding: u17 = 0,
};

/// Based of SPV_GOOGLE_user_type
pub const UserType = enum(u32) {
    invalid = 0,
    cbuffer,
    tbuffer,
    append_structured_buffer,
    buffer,
    byte_address_buffer,
    constant_buffer,
    consume_structured_buffer,
    input_patch,
    output_patch,
    rasterizer_ordered_buffer,
    rasterizer_ordered_byte_address_buffer,
    rasterizer_ordered_structured_buffer,
    rasterizer_ordered_texture_1d,
    rasterizer_ordered_texture_1d_array,
    rasterizer_ordered_texture_2d,
    rasterizer_ordered_texture_2d_array,
    rasterizer_ordered_texture_3d,
    raytracing_acceleration_structure,
    rw_buffer,
    rw_byte_address_buffer,
    rw_structured_buffer,
    rw_texture_1d,
    rw_texture_1d_array,
    rw_texture_2d,
    rw_texture_2d_array,
    rw_texture_3d,
    structured_buffer,
    subpass_input,
    subpass_input_ms,
    texture_1d,
    texture_1d_array,
    texture_2d,
    texture_2d_array,
    texture_2dms,
    texture_2dms_array,
    texture_3d,
    texture_buffer,
    texture_cube,
    texture_cube_array,
};

pub const ResourceType = packed struct(u32) {
    sampler: bool = false,
    cbv: bool = false,
    srv: bool = false,
    uav: bool = false,
    _padding: u28 = 0,
};

pub const Format = enum(u32) {
    undefined = 0,
    r16_uint = 74,
    r16_sint = 75,
    r16_sfloat = 76,
    r16g16_uint = 81,
    r16g16_sint = 82,
    r16g16_sfloat = 83,
    r16g16b16_uint = 88,
    r16g16b16_sint = 89,
    r16g16b16_sfloat = 90,
    r16g16b16a16_uint = 95,
    r16g16b16a16_sint = 96,
    r16g16b16a16_sfloat = 97,
    r32_uint = 98,
    r32_sint = 99,
    r32_sfloat = 100,
    r32g32_uint = 101,
    r32g32_sint = 102,
    r32g32_sfloat = 103,
    r32g32b32_uint = 104,
    r32g32b32_sint = 105,
    r32g32b32_sfloat = 106,
    r32g32b32a32_uint = 107,
    r32g32b32a32_sint = 108,
    r32g32b32a32_sfloat = 109,
    r64_uint = 110,
    r64_sint = 111,
    r64_sfloat = 112,
    r64g64_uint = 113,
    r64g64_sint = 114,
    r64g64_sfloat = 115,
    r64g64b64_uint = 116,
    r64g64b64_sint = 117,
    r64g64b64_sfloat = 118,
    r64g64b64a64_uint = 119,
    r64g64b64a64_sint = 120,
    r64g64b64a64_sfloat = 121,
};

pub const VariableFlags = packed struct(u32) {
    unused: bool = false,
    /// If variable points to a copy of the PhysicalStorageBuffer struct
    physical_pointer_copy: bool = false,
    _padding: u30 = 0,
};

pub const DescriptorType = enum(u32) {
    sampler = 0,
    combined_image_sampler = 1,
    sampled_image = 2,
    storage_image = 3,
    uniform_texel_buffer = 4,
    storage_texel_buffer = 5,
    uniform_buffer = 6,
    storage_buffer = 7,
    uniform_buffer_dynamic = 8,
    storage_buffer_dynamic = 9,
    input_attachment = 10,
    acceleration_structure_khr = 1000150000,
};

pub const ShaderStageFlags = packed struct(u32) {
    vertex_bit: bool = false,
    tessellation_control_bit: bool = false,
    tessellation_evaluation_bit: bool = false,
    geometry_bit: bool = false,
    fragment_bit: bool = false,
    compute_bit: bool = false,
    task_bit_ext: bool = false,
    mesh_bit_ext: bool = false,
    raygen_bit_khr: bool = false,
    any_hit_bit_khr: bool = false,
    closest_hit_bit_khr: bool = false,
    miss_bit_khr: bool = false,
    intersection_bit_khr: bool = false,
    callable_bit_khr: bool = false,
    _padding: u18 = 0,

    // TODO:
    // pub const task_bit_nv: ShaderStageFlags = .task_bit_ext;
    // pub const mesh_bit_nv: ShaderStageFlags = .mesh_bit_ext;
};

pub const Generator = enum(u32) {
    khronos_llvm_spirv_translator = 6,
    khronos_spirv_tools_assembler = 7,
    khronos_glslang_reference_front_end = 8,
    google_shaderc_over_glslang = 13,
    google_spiregg = 14,
    google_rspirv = 15,
    x_legend_mesa_mesair_spirv_translator = 16,
    khronos_spirv_tools_linker = 17,
    wine_vkd3d_shader_compiler = 18,
    clay_clay_shader_compiler = 19,
};

pub const ExecutionModeValue = enum(u32) {
    spec_constant = 0xffffffff, // specialization constant
};

pub const MAX_ARRAY_DIMS = 32;
pub const MAX_DESCRIPTOR_SETS = 64;

pub const BINDING_NUMBER_DONT_CHANGE = 0xffffffff;
pub const SET_NUMBER_DONT_CHANGE = 0xffffffff;

pub const NumericTraits = extern struct {
    scalar: Scalar,
    vector: Vector,
    matrix: Matrix,

    pub const Scalar = extern struct {
        width: u32,
        signedness: u32,
    };

    pub const Vector = extern struct {
        component_count: u32,
    };

    pub const Matrix = extern struct {
        column_count: u32,
        row_count: u32,
        stride: u32, // Measured in bytes
    };
};

pub const ImageTraits = extern struct {
    dim: spv.Dim,
    depth: u32,
    arrayed: u32,
    ms: u32, // 0: single-sampled; 1: multisampled
    sampled: u32,
    image_format: spv.ImageFormat,
};

pub const ArrayDimType = enum(u32) {
    runtime = 0, // OpTypeRuntimeArray
};

pub const ArrayTraits = extern struct {
    dims_count: u32,
    /// Each entry is either:
    /// - specialization constant dimension
    /// - OpTypeRuntimeArray
    /// - the array length otherwise
    dims: [MAX_ARRAY_DIMS]u32,
    /// Stores Ids for dimensions that are specialization constants
    spec_constant_op_ids: [MAX_ARRAY_DIMS]u32,
    stride: u32, // Measured in bytes
};

pub const BindingArrayTraits = extern struct {
    dims_count: u32,
    dims: [MAX_ARRAY_DIMS]u32,
};

/// Information about an *OpType instruction
pub const TypeDescription = extern struct {
    id: u32,
    op: spv.Op,
    type_name: [*:0]const u8,
    /// Non-NULL if type is member of a struct
    struct_member_name: ?[*:0]const u8,

    /// The storage class (spv.StorageClass) if the type, and -1 if it does not
    /// have a storage class.
    storage_class: i32,
    type_flags: TypeFlags,
    decoration_flags: DecorationFlags,

    traits: Traits,

    /// If underlying type is a struct (ex. array of structs)
    /// this gives access to the OpTypeStruct
    struct_type_description: *TypeDescription,

    /// Some pointers to TypeDescription are really
    /// just copies of another reference to the same OpType
    copied: u32,

    /// DEPRECATED: use struct_type_description instead
    member_count: u32,
    /// DEPRECATED: use struct_type_description instead
    members: *TypeDescription,

    pub const Traits = extern struct {
        numeric: NumericTraits,
        image: ImageTraits,
        array: ArrayTraits,
    };
};

/// The OpVariable that is either an Input or Output to the module
pub const InterfaceVariable = extern struct {
    spirv_id: u32,
    name: [*:0]const u8,
    location: u32,
    component: u32,
    storage_class: spv.StorageClass,
    semantic: [*:0]const u8,
    decoration_flags: DecorationFlags,

    /// The builtin id (spv.BuiltIn) if the variable is a builtin, and -1 otherwise.
    built_in: i32,
    numeric: NumericTraits,
    array: ArrayTraits,

    member_count: u32,
    members: *InterfaceVariable,

    format: Format,

    /// Note: SPIR-V shares type references for variables that have the same
    /// underlying type. This means that the same type name will appear for
    /// multiple variables.
    type_description: *TypeDescription,

    word_offset: extern struct {
        location: u32,
    },
};

pub const BlockVariable = extern struct {
    spirv_id: u32,
    name: [*:0]const u8,
    /// For Push Constants, this is the lowest offset of all memebers
    offset: u32, // Measured in bytes
    absolute_offset: u32, // Measured in bytes
    size: u32, // Measured in bytes
    padded_size: u32, // Measured in bytes
    decoration_flags: DecorationFlags,
    numeric: NumericTraits,
    array: ArrayTraits,
    flags: VariableFlags,

    member_count: u32,
    members: [*]const BlockVariable,

    type_description: *TypeDescription,

    word_offset: extern struct {
        offset: u32,
    },

    pub fn typeName(self: *const BlockVariable) [*:0]const u8 {
        return c.spvReflectBlockVariableTypeName(self);
    }
};

pub const DescriptorBinding = extern struct {
    spirv_id: u32,
    name: [*:0]const u8,
    binding: u32,
    input_attachment_index: u32,
    set: u32,
    descriptor_type: DescriptorType,
    resource_type: ResourceType,
    image: ImageTraits,
    block: BlockVariable,
    array: BindingArrayTraits,
    count: u32,
    accessed: u32,
    uav_counter_id: u32,
    uav_counter_binding: *DescriptorBinding,
    byte_address_buffer_offset_count: u32,
    byte_address_buffer_offsets: *u32,

    type_description: *TypeDescription,

    word_offset: extern struct {
        binding: u32,
        set: u32,
    },

    decoration_flags: DecorationFlags,
    /// Requires SPV_GOOGLE_user_type
    user_type: UserType,
};

pub const DescriptorSet = extern struct {
    set: u32,
    binding_count: u32,
    bindings: [*]const *const DescriptorBinding,
};

pub const EntryPoint = extern struct {
    name: [*:0]const u8,
    id: u32,

    spirv_execution_model: spv.ExecutionModel,
    shader_stage: ShaderStageFlags,

    input_variable_count: u32,
    input_variables: [*]const *const InterfaceVariable,
    output_variable_count: u32,
    output_variables: [*]const *const InterfaceVariable,
    interface_variable_count: u32,
    interface_variables: [*]const InterfaceVariable,

    descriptor_set_count: u32,
    descriptor_sets: [*]const DescriptorSet,

    used_uniform_count: u32,
    used_uniforms: [*]const u32,
    used_push_constant_count: u32,
    used_push_constants: [*]const u32,

    execution_mode_count: u32,
    execution_modes: [*]const spv.ExecutionMode,

    local_size: LocalSize,
    invocations: u32, // valid for geometry
    output_vertices: u32, // valid for geometry, tesselation

    pub const LocalSize = extern struct {
        x: u32,
        y: u32,
        z: u32,
    };
};

pub const Capability = extern struct {
    value: spv.Capability,
    word_offset: u32,
};

pub const SpecializationConstant = extern struct {
    spirv_id: u32,
    constant_id: u32,
    name: [*:0]const u8,
};

pub const ShaderModule = extern struct {
    generator: Generator,
    entry_point_name: [*:0]const u8,
    entry_point_id: u32,
    entry_point_count: u32,
    entry_points: [*]const EntryPoint,
    source_language: spv.SourceLanguage,
    source_language_version: u32,
    source_file: [*:0]const u8,
    source_source: [*:0]const u8,
    capability_count: u32,
    capabilities: [*]const spv.Capability,
    spirv_execution_model: spv.ExecutionModel, // Uses value(s) from first entry point
    shader_stage: ShaderStageFlags, // Uses value(s) from first entry point
    descriptor_binding_count: u32, // Uses value(s) from first entry point
    descriptor_bindings: [*]const DescriptorBinding, // Uses value(s) from first entry point
    descriptor_set_count: u32, // Uses value(s) from first entry point
    descriptor_sets: [MAX_DESCRIPTOR_SETS]DescriptorSet, // Uses value(s) from first entry point
    input_variable_count: u32, // Uses value(s) from first entry point
    input_variables: [*]const *const InterfaceVariable, // Uses value(s) from first entry point
    output_variable_count: u32, // Uses value(s) from first entry point
    output_variables: [*]const *const InterfaceVariable, // Uses value(s) from first entry point
    interface_variable_count: u32, // Uses value(s) from first entry point
    interface_variables: [*]const InterfaceVariable, // Uses value(s) from first entry point
    push_constant_block_count: u32, // Uses value(s) from first entry point
    push_constant_blocks: [*]const BlockVariable, // Uses value(s) from first entry point
    spec_constant_count: u32, // Uses value(s) from first entry point
    spec_constants: [*]const SpecializationConstant, // Uses value(s) from first entry point

    _internal: *const Internal,

    pub const Internal = extern struct {
        module_flags: ModuleFlags,
        spirv_size: usize,
        spirv_code: [*]const u32,
        spirv_word_count: u32,

        type_description_count: usize,
        type_descriptions: [*]const TypeDescription,
    };

    pub fn init(code: []align(4) const u8, flags: ModuleFlags) Error!ShaderModule {
        var self: ShaderModule = undefined;
        try checkErr(c.spvReflectCreateShaderModule2(flags, code.len, code.ptr, &self));
        return self;
    }

    pub fn deinit(self: *ShaderModule) void {
        c.spvReflectDestroyShaderModule(self);
        self.* = undefined;
    }

    /// Returns a const pointer to the compiled SPIR-V bytecode.
    pub fn getCode(self: ShaderModule) []const u32 {
        const len = c.spvReflectGetCodeSize(&self) / @sizeOf(u32);
        return c.spvReflectGetCode(&self)[0..len];
    }

    pub fn getSourceFile(self: ShaderModule) [*:0]const u8 {
        return self.source_file;
    }

    pub fn getEntryPoints(self: ShaderModule) []const EntryPoint {
        return self.entry_points[0..self.entry_point_count];
    }

    pub fn getEntryPoint(self: ShaderModule, entry_point: [*:0]const u8) ?*const EntryPoint {
        return c.spvReflectGetEntryPoint(&self, entry_point);
    }

    pub const EnumerateError = Error || mem.Allocator.Error;

    pub fn enumerateDescriptorBindings(
        self: ShaderModule,
        allocator: mem.Allocator,
    ) EnumerateError![]const *DescriptorBinding {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateDescriptorBindings(&self, &count, null));
        const bindings = try allocator.alloc(*DescriptorBinding, count);
        errdefer allocator.free(bindings);
        try checkErr(c.spvReflectEnumerateDescriptorBindings(&self, &count, bindings.ptr));
        return bindings[0..count];
    }

    /// Creates a listing of all descriptor bindings that are used in the static
    /// call tree of the given entry point.
    pub fn enumerateEntryPointDescriptorBindings(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        allocator: mem.Allocator,
    ) EnumerateError![]const *DescriptorBinding {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateEntryPointDescriptorBindings(&self, entry_point, &count, null));
        const bindings = try allocator.alloc(*DescriptorBinding, count);
        errdefer allocator.free(bindings);
        try checkErr(c.spvReflectEnumerateEntryPointDescriptorBindings(&self, entry_point, &count, bindings.ptr));
        return bindings[0..count];
    }

    pub fn enumerateDescriptorSets(
        self: ShaderModule,
        allocator: mem.Allocator,
    ) EnumerateError![]const *DescriptorSet {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateDescriptorSets(&self, &count, null));
        const sets = try allocator.alloc(*DescriptorSet, count);
        errdefer allocator.free(sets);
        try checkErr(c.spvReflectEnumerateDescriptorSets(&self, &count, sets.ptr));
        return sets[0..count];
    }

    /// Creates a listing of all descriptor sets and their bindings that are
    /// used in the static call tree of a given entry point.
    pub fn enumerateEntryPointDescriptorSets(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        allocator: mem.Allocator,
    ) EnumerateError![]const *DescriptorSet {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateEntryPointDescriptorSets(&self, entry_point, &count, null));
        const sets = try allocator.alloc(*DescriptorSet, count);
        errdefer allocator.free(sets);
        try checkErr(c.spvReflectEnumerateEntryPointDescriptorSets(&self, entry_point, &count, sets.ptr));
        return sets[0..count];
    }

    /// If the module contains multiple entry points, this will only get the
    /// interface variables for the first one.
    pub fn enumerateInterfaceVariables(
        self: ShaderModule,
        allocator: mem.Allocator,
    ) EnumerateError![]const *InterfaceVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateInterfaceVariables(&self, &count, null));
        const variables = try allocator.alloc(*InterfaceVariable, count);
        errdefer allocator.free(variables);
        try checkErr(c.spvReflectEnumerateInterfaceVariables(&self, &count, variables.ptr));
        return variables[0..count];
    }

    /// Enumerate the interface variables for a given entry point.
    pub fn enumerateEntryPointInterfaceVariables(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        allocator: mem.Allocator,
    ) EnumerateError![]const *InterfaceVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateEntryPointInterfaceVariables(&self, entry_point, &count, null));
        const variables = try allocator.alloc(*InterfaceVariable, count);
        errdefer allocator.free(variables);
        try checkErr(c.spvReflectEnumerateEntryPointInterfaceVariables(&self, entry_point, &count, variables.ptr));
        return variables[0..count];
    }

    /// If the module contains multiple entry points, this will only get
    pub fn enumerateInputVariables(
        self: ShaderModule,
        allocator: mem.Allocator,
    ) EnumerateError![]const *InterfaceVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateInputVariables(&self, &count, null));
        const variables = try allocator.alloc(*InterfaceVariable, count);
        errdefer allocator.free(variables);
        try checkErr(c.spvReflectEnumerateInputVariables(&self, &count, variables.ptr));
        return variables[0..count];
    }

    /// Enumerate the input variables for a given entry point.
    pub fn enumerateEntryPointInputVariables(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        allocator: mem.Allocator,
    ) EnumerateError![]const *InterfaceVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateEntryPointInputVariables(&self, entry_point, &count, null));
        const variables = try allocator.alloc(*InterfaceVariable, count);
        errdefer allocator.free(variables);
        try checkErr(c.spvReflectEnumerateEntryPointInputVariables(&self, entry_point, &count, variables.ptr));
        return variables[0..count];
    }

    /// Note: If the module contains multiple entry points, this will only get
    /// the output variables for the first one.
    pub fn enumerateOutputVariables(
        self: ShaderModule,
        allocator: mem.Allocator,
    ) EnumerateError![]const *InterfaceVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateOutputVariables(&self, &count, null));
        const variables = try allocator.alloc(*InterfaceVariable, count);
        errdefer allocator.free(variables);
        try checkErr(c.spvReflectEnumerateOutputVariables(&self, &count, variables.ptr));
        return variables[0..count];
    }

    /// Enumerate the output variables for a given entry point.
    pub fn enumerateEntryPointOutputVariables(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        allocator: mem.Allocator,
    ) EnumerateError![]const *InterfaceVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateEntryPointOutputVariables(&self, entry_point, &count, null));
        const variables = try allocator.alloc(*InterfaceVariable, count);
        errdefer allocator.free(variables);
        try checkErr(c.spvReflectEnumerateEntryPointOutputVariables(&self, entry_point, &count, variables.ptr));
        return variables[0..count];
    }

    /// Note: If the module contains multiple entry points, this will only get
    /// the push constant blocks for the first one.
    pub fn enumeratePushConstantBlocks(
        self: ShaderModule,
        allocator: mem.Allocator,
    ) EnumerateError![]const *BlockVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumeratePushConstantBlocks(&self, &count, null));
        const blocks = try allocator.alloc(*BlockVariable, count);
        errdefer allocator.free(blocks);
        try checkErr(c.spvReflectEnumeratePushConstantBlocks(&self, &count, blocks.ptr));
        return blocks[0..count];
    }

    /// Enumerate the push constant blocks used in the static call tree of a
    /// given entry point.
    pub fn enumerateEntryPointPushConstantBlocks(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        allocator: mem.Allocator,
    ) EnumerateError![]const *BlockVariable {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateEntryPointPushConstantBlocks(&self, entry_point, &count, null));
        const blocks = try allocator.alloc(*BlockVariable, count);
        errdefer allocator.free(blocks);
        try checkErr(c.spvReflectEnumerateEntryPointPushConstantBlocks(&self, entry_point, &count, blocks.ptr));
        return blocks[0..count];
    }

    pub fn enumerateSpecializationConstants(
        self: ShaderModule,
        allocator: mem.Allocator,
    ) EnumerateError![]const *SpecializationConstant {
        var count: u32 = undefined;
        try checkErr(c.spvReflectEnumerateSpecializationConstants(&self, &count, null));
        const constants = try allocator.alloc(*SpecializationConstant, count);
        errdefer allocator.free(constants);
        try checkErr(c.spvReflectEnumerateSpecializationConstants(&self, &count, constants.ptr));
        return constants[0..count];
    }

    /// If the module contains a descriptor binding that matches the provided
    /// [binding_number, set_number] values, a pointer to that binding is
    /// returned. The caller must not free this pointer. If no match can be
    /// found, or if an unrelated error occurs, will return an error.
    /// Note: If the module contains multiple desriptor bindings with the same
    /// set and binding numbers, there are no guarantees about which binding
    /// will be returned.
    pub fn getDescriptorBinding(
        self: ShaderModule,
        binding_number: u32,
        set_number: u32,
    ) Error!*const DescriptorBinding {
        var result: Result = undefined;
        const binding = c.spvReflectGetDescriptorBinding(&self, binding_number, set_number, &result);
        try checkErr(result);
        return binding;
    }

    /// Get the descriptor binding with the given binding number and set number that
    /// is used in the static call tree of a certain entry point.
    ///
    /// If the entry point contains a descriptor binding that matches the
    /// provided [binding_number, set_number] values, a pointer to that binding
    /// is returned. The caller must not free this pointer. If no match can be
    /// found, or if an unrelated error occurs, will return an error.
    /// Note: If the entry point contains multiple desriptor bindings with the
    /// same set and binding numbers, there are no guarantees about which
    /// binding will be returned.
    pub fn getEntryPointDescriptorBinding(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        binding_number: u32,
        set_number: u32,
    ) Error!*const DescriptorBinding {
        var result: Result = undefined;
        const binding = c.spvReflectGetEntryPointDescriptorBinding(&self, entry_point, binding_number, set_number, &result);
        try checkErr(result);
        return binding;
    }

    /// If the module contains a descriptor set with the provided set_number, a
    /// pointer to that set is returned. The caller must not free this pointer.
    pub fn getDescriptorSet(
        self: ShaderModule,
        set_number: u32,
    ) Error!*const DescriptorSet {
        var result: Result = undefined;
        const set = c.spvReflectGetDescriptorSet(&self, set_number, &result);
        if (set == null or result != .success) try checkErr(result);
        return set;
    }

    /// If the entry point contains a descriptor set with the provided set_number, a
    /// pointer to that set is returned. The caller must not free this pointer.
    pub fn getEntryPointDescriptorSet(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        set_number: u32,
    ) Error!*const DescriptorSet {
        var result: Result = undefined;
        const set = c.spvReflectGetEntryPointDescriptorSet(&self, entry_point, set_number, &result);
        if (set == null or result != .success) try checkErr(result);
        return set;
    }

    /// If the module contains an input interface variable with the provided
    /// location value, a pointer to that variable is returned. The caller must
    /// not free this pointer.
    ///
    /// `location`: The "location" value of the requested output variable.
    /// A location of 0xFFFFFFFF will always return the error `ElementNotFound`.
    pub fn getInputVariableByLocation(
        self: ShaderModule,
        location: u32,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetInputVariableByLocation(&self, location, &result);
        try checkErr(result);
        return variable;
    }

    /// If the entry point contains an input interface variable with the provided
    /// location value, a pointer to that variable is returned. The caller must
    /// not free this pointer.
    ///
    /// `location`: The "location" value of the requested output variable.
    /// A location of 0xFFFFFFFF will always return the error `ElementNotFound`.
    pub fn getEntryPointInputVariableByLocation(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        location: u32,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetEntryPointInputVariableByLocation(&self, entry_point, location, &result);
        try checkErr(result);
        return variable;
    }

    /// If the module contains an input interface variable with the provided
    /// semantic, a pointer to that variable is returned. The caller must not
    /// free this pointer.
    ///
    /// `semantic`: The "semantic" value of the requested output variable.
    /// A semantic of "" will always return the error `ElementNotFound`.
    pub fn getInputVariableBySemantic(
        self: ShaderModule,
        semantic: [*:0]const u8,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetInputVariableBySemantic(&self, semantic, &result);
        try checkErr(result);
        return variable;
    }

    /// If the entry point contains an input interface variable with the provided
    /// semantic, a pointer to that variable is returned. The caller must not
    /// free this pointer.
    ///
    /// `semantic`: The "semantic" value of the requested output variable.
    /// A semantic of "" will always return the error `ElementNotFound`.
    pub fn getEntryPointInputVariableBySemantic(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        semantic: [*:0]const u8,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetEntryPointInputVariableBySemantic(&self, entry_point, semantic, &result);
        try checkErr(result);
        return variable;
    }

    /// If the module contains an output interface variable with the provided
    /// location value, a pointer to that variable is returned. The caller must
    /// not free this pointer.
    ///
    /// `location`: The "location" value of the requested output variable.
    /// A location of 0xFFFFFFFF will always return the error `ElementNotFound`.
    pub fn getOutputVariableByLocation(
        self: ShaderModule,
        location: u32,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetOutputVariableByLocation(&self, location, &result);
        try checkErr(result);
        return variable;
    }

    /// If the entry point contains an output interface variable with the provided
    /// location value, a pointer to that variable is returned. The caller must
    /// not free this pointer.
    pub fn getEntryPointOutputVariableByLocation(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        location: u32,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetEntryPointOutputVariableByLocation(&self, entry_point, location, &result);
        try checkErr(result);
        return variable;
    }

    /// If the module contains an output interface variable with the provided
    /// semantic, a pointer to that variable is returned. The caller must not
    /// free this pointer.
    ///
    /// `semantic`: The "semantic" value of the requested output variable.
    /// A semantic of "" will always return the error `ElementNotFound`.
    pub fn getOutputVariableBySemantic(
        self: ShaderModule,
        semantic: [*:0]const u8,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetOutputVariableBySemantic(&self, semantic, &result);
        try checkErr(result);
        return variable;
    }

    /// If the entry point contains an output interface variable with the
    /// provided semantic, a pointer to that variable is returned. The caller
    /// must not free this pointer.
    ///
    /// `semantic`: The "semantic" value of the requested output variable.
    /// A semantic of "" will always return the error `ElementNotFound`.
    pub fn getEntryPointOutputVariableBySemantic(
        self: ShaderModule,
        entry_point: [*:0]const u8,
        semantic: [*:0]const u8,
    ) Error!*const InterfaceVariable {
        var result: Result = undefined;
        const variable = c.spvReflectGetEntryPointOutputVariableBySemantic(&self, entry_point, semantic, &result);
        try checkErr(result);
        return variable;
    }

    /// If the provided index is within range, a pointer to the corresponding
    /// push constant block is returned. The caller must not free this pointer.
    pub fn getPushConstantBlock(
        self: ShaderModule,
        index: u32,
    ) Error!*const BlockVariable {
        var result: Result = undefined;
        const block = c.spvReflectGetPushConstantBlock(&self, index, &result);
        try checkErr(result);
        return block;
    }

    /// Get the push constant block corresponding to the given entry point. As
    /// by the Vulkan specification there can be no more than one push constant
    /// block used by a given entry point, so if there is one it will be
    /// returned, otherwise NULL will be returned.
    ///
    /// If the provided index is within range, a pointer to the corresponding
    /// push constant block is returned. The caller must not free this pointer.
    pub fn getEntryPointPushConstantBlock(
        self: ShaderModule,
        entry_point: [*:0]const u8,
    ) Error!*const BlockVariable {
        var result: Result = undefined;
        const block = c.spvReflectGetEntryPointPushConstantBlock(&self, entry_point, &result);
        try checkErr(result);
        return block;
    }

    /// Assign new set and/or binding numbers to a descriptor binding. In
    /// addition to updating the reflection data, this function modifies the
    /// underlying SPIR-V bytecode. The updated code can be retrieved with
    /// spvReflectGetCode().  If the binding is used in multiple entry points
    /// within the module, it will be changed in all of them.
    ///
    /// `new_binding_number`: The new binding number to assign to the provided
    /// descriptor binding. To leave the binding number unchanged, pass
    /// BINDING_NUMBER_DONT_CHANGE.
    ///
    /// `new_set_number`: The new set number to assign to the provided descriptor
    /// binding. Successfully changing a descriptor binding's set number
    /// invalidates all existing DescriptorBinding and DescriptorSet pointers
    /// from this module. To leave the set number unchanged, pass
    /// SET_NUMBER_DONT_CHANGE.
    pub fn changeDescriptorBindingNumbers(
        self: *ShaderModule,
        p_binding: *const DescriptorBinding,
        new_binding_number: u32,
        new_set_number: u32,
    ) Error!void {
        try checkErr(c.spvReflectChangeDescriptorBindingNumbers(self, p_binding, new_binding_number, new_set_number));
    }

    /// Assign a new set number to an entire descriptor set (including all
    /// descriptor bindings in that set). In addition to updating the reflection
    /// data, this function modifies the underlying SPIR-V bytecode. The updated
    /// code can be retrieved with spvReflectGetCode().  If the descriptor set
    /// is used in multiple entry points within the module, it will be modified
    /// in all of them.
    ///
    /// `new_set_number`: The new set number to assign to the provided descriptor
    /// set, and all its descriptor bindings. Successfully changing a descriptor
    /// binding's set number invalidates all existing DescriptorBinding and
    /// DescriptorSet pointers from this module. To leave the set number
    /// unchanged, pass SET_NUMBER_DONT_CHANGE.
    pub fn changeDescriptorSetNumber(
        self: *ShaderModule,
        p_set: *const DescriptorSet,
        new_set_number: u32,
    ) Error!void {
        try checkErr(c.spvReflectChangeDescriptorSetNumber(self, p_set, new_set_number));
    }

    /// Assign a new location to an input interface variable. In addition to
    /// updating the reflection data, this function modifies the underlying
    /// SPIR-V bytecode. The updated code can be retrieved with
    /// spvReflectGetCode(). It is the caller's responsibility to avoid
    /// assigning the same location to multiple input variables.  If the input
    /// variable is used by multiple entry points in the module, it will be
    /// changed in all of them.
    pub fn changeInputVariableLocation(
        self: *ShaderModule,
        p_input_variable: *const InterfaceVariable,
        new_location: u32,
    ) Error!void {
        try checkErr(c.spvReflectChangeInputVariableLocation(self, p_input_variable, new_location));
    }

    /// Assign a new location to an output interface variable. In addition to
    /// updating the reflection data, this function modifies the underlying
    /// SPIR-V bytecode. The updated code can be retrieved with
    /// spvReflectGetCode(). It is the caller's responsibility to avoid
    /// assigning the same location to multiple output variables.  If the output
    /// variable is used by multiple entry points in the module, it will be
    /// changed in all of them.
    pub fn changeOutputVariableLocation(
        self: *ShaderModule,
        p_output_variable: *const InterfaceVariable,
        new_location: u32,
    ) Error!void {
        try checkErr(c.spvReflectChangeOutputVariableLocation(self, p_output_variable, new_location));
    }

    fn checkErr(result: Result) Error!void {
        return switch (result) {
            .success => {},
            .not_ready => error.NotReady,
            .error_parse_failed => error.ParseFailed,
            .error_alloc_failed => error.AllocFailed,
            .error_range_exceeded => error.RangeExceeded,
            .error_null_pointer => error.NullPointer,
            .error_internal_error => error.InternalError,
            .error_count_mismatch => error.CountMismatch,
            .error_element_not_found => error.ElementNotFound,
            .error_spirv_invalid_code_size => error.SpirvInvalidCodeSize,
            .error_spirv_invalid_magic_number => error.SpirvInvalidMagicNumber,
            .error_spirv_unexpected_eof => error.SpirvUnexpectedEof,
            .error_spirv_invalid_id_reference => error.SpirvInvalidIdReference,
            .error_spirv_set_number_overflow => error.SpirvSetNumberOverflow,
            .error_spirv_invalid_storage_class => error.SpirvInvalidStorageClass,
            .error_spirv_recursion => error.SpirvRecursion,
            .error_spirv_invalid_instruction => error.SpirvInvalidInstruction,
            .error_spirv_unexpected_block_data => error.SpirvUnexpectedBlockData,
            .error_spirv_invalid_block_member_reference => error.SpirvInvalidBlockMemberReference,
            .error_spirv_invalid_entry_point => error.SpirvInvalidEntryPoint,
            .error_spirv_invalid_execution_mode => error.SpirvInvalidExecutionMode,
            .error_spirv_max_recursive_exceeded => error.SpirvMaxRecursiveExceeded,
        };
    }
};

pub const c = struct {
    /// @fn spvReflectCreateShaderModule
    /// @param  size      Size in bytes of SPIR-V code.
    /// @param  p_code    Pointer to SPIR-V code.
    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @return           RESULT_SUCCESS on success.
    extern fn spvReflectCreateShaderModule(
        size: usize,
        p_code: [*]align(4) const u8,
        p_module: *ShaderModule,
    ) Result;

    /// @param  flags     Flags for module creations.
    /// @param  size      Size in bytes of SPIR-V code.
    /// @param  p_code    Pointer to SPIR-V code.
    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @return           RESULT_SUCCESS on success.
    extern fn spvReflectCreateShaderModule2(
        flags: ModuleFlags,
        size: usize,
        p_code: [*]align(4) const u8,
        p_module: *ShaderModule,
    ) Result;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    extern fn spvReflectDestroyShaderModule(p_module: *ShaderModule) void;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @return           Returns the size of the SPIR-V in bytes
    extern fn spvReflectGetCodeSize(p_module: *const ShaderModule) u32;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @return           Returns a const pointer to the compiled SPIR-V bytecode.
    extern fn spvReflectGetCode(p_module: *const ShaderModule) [*]const u32;

    /// @param  p_module     Pointer to an instance of ShaderModule.
    /// @param  entry_point  Name of the requested entry point.
    /// @return              Returns a const pointer to the requested entry point,
    ///                      or NULL if it's not found.
    extern fn spvReflectGetEntryPoint(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
    ) ?*const EntryPoint;

    /// @param  p_module     Pointer to an instance of ShaderModule.
    /// @param  p_count      If pp_bindings is NULL, the module's descriptor binding
    ///                      count (across all descriptor sets) will be stored here.
    ///                      If pp_bindings is not NULL, *p_count must contain the
    ///                      module's descriptor binding count.
    /// @param  pp_bindings  If NULL, the module's total descriptor binding count
    ///                      will be written to *p_count.
    ///                      If non-NULL, pp_bindings must point to an array with
    ///                      *p_count entries, where pointers to the module's
    ///                      descriptor bindings will be written. The caller must not
    ///                      free the binding pointers written to this array.
    /// @return              If successful, returns RESULT_SUCCESS.
    ///                      Otherwise, the error code indicates the cause of the
    ///                      failure.
    extern fn spvReflectEnumerateDescriptorBindings(
        p_module: *const ShaderModule,
        p_count: *u32,
        pp_bindings: ?[*]*DescriptorBinding,
    ) Result;

    /// @brief  Creates a listing of all descriptor bindings that are used in the
    ///         static call tree of the given entry point.
    /// @param  p_module     Pointer to an instance of ShaderModule.
    /// @param  entry_point  The name of the entry point to get the descriptor bindings for.
    /// @param  p_count      If pp_bindings is NULL, the entry point's descriptor binding
    ///                      count (across all descriptor sets) will be stored here.
    ///                      If pp_bindings is not NULL, *p_count must contain the
    ///                      entry points's descriptor binding count.
    /// @param  pp_bindings  If NULL, the entry point's total descriptor binding count
    ///                      will be written to *p_count.
    ///                      If non-NULL, pp_bindings must point to an array with
    ///                      *p_count entries, where pointers to the entry point's
    ///                      descriptor bindings will be written. The caller must not
    ///                      free the binding pointers written to this array.
    /// @return              If successful, returns RESULT_SUCCESS.
    ///                      Otherwise, the error code indicates the cause of the
    ///                      failure.
    extern fn spvReflectEnumerateEntryPointDescriptorBindings(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        p_count: *u32,
        pp_bindings: ?[*]*DescriptorBinding,
    ) Result;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  p_count   If pp_sets is NULL, the module's descriptor set
    ///                   count will be stored here.
    ///                   If pp_sets is not NULL, *p_count must contain the
    ///                   module's descriptor set count.
    /// @param  pp_sets   If NULL, the module's total descriptor set count
    ///                   will be written to *p_count.
    ///                   If non-NULL, pp_sets must point to an array with
    ///                   *p_count entries, where pointers to the module's
    ///                   descriptor sets will be written. The caller must not
    ///                   free the descriptor set pointers written to this array.
    /// @return           If successful, returns RESULT_SUCCESS.
    ///                   Otherwise, the error code indicates the cause of the
    ///                   failure.
    extern fn spvReflectEnumerateDescriptorSets(
        p_module: *const ShaderModule,
        p_count: *u32,
        pp_sets: ?[*]*DescriptorSet,
    ) Result;

    /// @brief  Creates a listing of all descriptor sets and their bindings that are
    ///         used in the static call tree of a given entry point.
    /// @param  p_module    Pointer to an instance of ShaderModule.
    /// @param  entry_point The name of the entry point to get the descriptor bindings for.
    /// @param  p_count     If pp_sets is NULL, the module's descriptor set
    ///                     count will be stored here.
    ///                     If pp_sets is not NULL, *p_count must contain the
    ///                     module's descriptor set count.
    /// @param  pp_sets     If NULL, the module's total descriptor set count
    ///                     will be written to *p_count.
    ///                     If non-NULL, pp_sets must point to an array with
    ///                     *p_count entries, where pointers to the module's
    ///                     descriptor sets will be written. The caller must not
    ///                     free the descriptor set pointers written to this array.
    /// @return             If successful, returns RESULT_SUCCESS.
    ///                     Otherwise, the error code indicates the cause of the
    ///                     failure.
    extern fn spvReflectEnumerateEntryPointDescriptorSets(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        p_count: *u32,
        pp_sets: ?[*]*DescriptorSet,
    ) Result;

    /// @brief  If the module contains multiple entry points, this will only get
    ///         the interface variables for the first one.
    /// @param  p_module      Pointer to an instance of ShaderModule.
    /// @param  p_count       If pp_variables is NULL, the module's interface variable
    ///                       count will be stored here.
    ///                       If pp_variables is not NULL, *p_count must contain
    ///                       the module's interface variable count.
    /// @param  pp_variables  If NULL, the module's interface variable count will be
    ///                       written to *p_count.
    ///                       If non-NULL, pp_variables must point to an array with
    ///                       *p_count entries, where pointers to the module's
    ///                       interface variables will be written. The caller must not
    ///                       free the interface variables written to this array.
    /// @return               If successful, returns RESULT_SUCCESS.
    ///                       Otherwise, the error code indicates the cause of the
    ///                       failure.
    extern fn spvReflectEnumerateInterfaceVariables(
        p_module: *const ShaderModule,
        p_count: *u32,
        pp_variables: ?[*]*InterfaceVariable,
    ) Result;

    /// @brief  Enumerate the interface variables for a given entry point.
    /// @param  entry_point The name of the entry point to get the interface variables for.
    /// @param  p_module      Pointer to an instance of ShaderModule.
    /// @param  p_count       If pp_variables is NULL, the entry point's interface variable
    ///                       count will be stored here.
    ///                       If pp_variables is not NULL, *p_count must contain
    ///                       the entry point's interface variable count.
    /// @param  pp_variables  If NULL, the entry point's interface variable count will be
    ///                       written to *p_count.
    ///                       If non-NULL, pp_variables must point to an array with
    ///                       *p_count entries, where pointers to the entry point's
    ///                       interface variables will be written. The caller must not
    ///                       free the interface variables written to this array.
    /// @return               If successful, returns RESULT_SUCCESS.
    ///                       Otherwise, the error code indicates the cause of the
    ///                       failure.
    extern fn spvReflectEnumerateEntryPointInterfaceVariables(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        p_count: *u32,
        pp_variables: ?[*]*InterfaceVariable,
    ) Result;

    /// @brief  If the module contains multiple entry points, this will only get
    ///         the input variables for the first one.
    /// @param  p_module      Pointer to an instance of ShaderModule.
    /// @param  p_count       If pp_variables is NULL, the module's input variable
    ///                       count will be stored here.
    ///                       If pp_variables is not NULL, *p_count must contain
    ///                       the module's input variable count.
    /// @param  pp_variables  If NULL, the module's input variable count will be
    ///                       written to *p_count.
    ///                       If non-NULL, pp_variables must point to an array with
    ///                       *p_count entries, where pointers to the module's
    ///                       input variables will be written. The caller must not
    ///                       free the interface variables written to this array.
    /// @return               If successful, returns RESULT_SUCCESS.
    ///                       Otherwise, the error code indicates the cause of the
    ///                       failure.
    extern fn spvReflectEnumerateInputVariables(
        p_module: *const ShaderModule,
        p_count: *u32,
        pp_variables: ?[*]*InterfaceVariable,
    ) Result;

    /// @brief  Enumerate the input variables for a given entry point.
    /// @param  entry_point The name of the entry point to get the input variables for.
    /// @param  p_module      Pointer to an instance of ShaderModule.
    /// @param  p_count       If pp_variables is NULL, the entry point's input variable
    ///                       count will be stored here.
    ///                       If pp_variables is not NULL, *p_count must contain
    ///                       the entry point's input variable count.
    /// @param  pp_variables  If NULL, the entry point's input variable count will be
    ///                       written to *p_count.
    ///                       If non-NULL, pp_variables must point to an array with
    ///                       *p_count entries, where pointers to the entry point's
    ///                       input variables will be written. The caller must not
    ///                       free the interface variables written to this array.
    /// @return               If successful, returns RESULT_SUCCESS.
    ///                       Otherwise, the error code indicates the cause of the
    ///                       failure.
    extern fn spvReflectEnumerateEntryPointInputVariables(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        p_count: *u32,
        pp_variables: ?[*]*InterfaceVariable,
    ) Result;

    /// @brief  Note: If the module contains multiple entry points, this will only get
    ///         the output variables for the first one.
    /// @param  p_module      Pointer to an instance of ShaderModule.
    /// @param  p_count       If pp_variables is NULL, the module's output variable
    ///                       count will be stored here.
    ///                       If pp_variables is not NULL, *p_count must contain
    ///                       the module's output variable count.
    /// @param  pp_variables  If NULL, the module's output variable count will be
    ///                       written to *p_count.
    ///                       If non-NULL, pp_variables must point to an array with
    ///                       *p_count entries, where pointers to the module's
    ///                       output variables will be written. The caller must not
    ///                       free the interface variables written to this array.
    /// @return               If successful, returns RESULT_SUCCESS.
    ///                       Otherwise, the error code indicates the cause of the
    ///                       failure.
    extern fn spvReflectEnumerateOutputVariables(
        p_module: *const ShaderModule,
        p_count: *u32,
        pp_variables: ?[*]*InterfaceVariable,
    ) Result;

    /// @brief  Enumerate the output variables for a given entry point.
    /// @param  p_module      Pointer to an instance of ShaderModule.
    /// @param  entry_point   The name of the entry point to get the output variables for.
    /// @param  p_count       If pp_variables is NULL, the entry point's output variable
    ///                       count will be stored here.
    ///                       If pp_variables is not NULL, *p_count must contain
    ///                       the entry point's output variable count.
    /// @param  pp_variables  If NULL, the entry point's output variable count will be
    ///                       written to *p_count.
    ///                       If non-NULL, pp_variables must point to an array with
    ///                       *p_count entries, where pointers to the entry point's
    ///                       output variables will be written. The caller must not
    ///                       free the interface variables written to this array.
    /// @return               If successful, returns RESULT_SUCCESS.
    ///                       Otherwise, the error code indicates the cause of the
    ///                       failure.
    extern fn spvReflectEnumerateEntryPointOutputVariables(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        p_count: *u32,
        pp_variables: ?[*]*InterfaceVariable,
    ) Result;

    /// @brief  Note: If the module contains multiple entry points, this will only get
    ///         the push constant blocks for the first one.
    /// @param  p_module   Pointer to an instance of ShaderModule.
    /// @param  p_count    If pp_blocks is NULL, the module's push constant
    ///                    block count will be stored here.
    ///                    If pp_blocks is not NULL, *p_count must
    ///                    contain the module's push constant block count.
    /// @param  pp_blocks  If NULL, the module's push constant block count
    ///                    will be written to *p_count.
    ///                    If non-NULL, pp_blocks must point to an
    ///                    array with *p_count entries, where pointers to
    ///                    the module's push constant blocks will be written.
    ///                    The caller must not free the block variables written
    ///                    to this array.
    /// @return            If successful, returns RESULT_SUCCESS.
    ///                    Otherwise, the error code indicates the cause of the
    ///                    failure.
    extern fn spvReflectEnumeratePushConstantBlocks(
        p_module: *const ShaderModule,
        p_count: *u32,
        pp_blocks: ?[*]*BlockVariable,
    ) Result;

    /// @brief  Enumerate the push constant blocks used in the static call tree of a
    ///         given entry point.
    /// @param  p_module   Pointer to an instance of ShaderModule.
    /// @param  p_count    If pp_blocks is NULL, the entry point's push constant
    ///                    block count will be stored here.
    ///                    If pp_blocks is not NULL, *p_count must
    ///                    contain the entry point's push constant block count.
    /// @param  pp_blocks  If NULL, the entry point's push constant block count
    ///                    will be written to *p_count.
    ///                    If non-NULL, pp_blocks must point to an
    ///                    array with *p_count entries, where pointers to
    ///                    the entry point's push constant blocks will be written.
    ///                    The caller must not free the block variables written
    ///                    to this array.
    /// @return            If successful, returns RESULT_SUCCESS.
    ///                    Otherwise, the error code indicates the cause of the
    ///                    failure.
    extern fn spvReflectEnumerateEntryPointPushConstantBlocks(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        p_count: *u32,
        pp_blocks: ?[*]*BlockVariable,
    ) Result;

    /// @param  p_module      Pointer to an instance of ShaderModule.
    /// @param  p_count       If pp_constants is NULL, the module's specialization constant
    ///                       count will be stored here. If pp_constants is not NULL, *p_count
    ///                       must contain the module's specialization constant count.
    /// @param  pp_constants  If NULL, the module's specialization constant count
    ///                       will be written to *p_count. If non-NULL, pp_blocks must
    ///                       point to an array with *p_count entries, where pointers to
    ///                       the module's specialization constant blocks will be written.
    ///                       The caller must not free the  variables written to this array.
    /// @return               If successful, returns RESULT_SUCCESS.
    ///                       Otherwise, the error code indicates the cause of the failure.
    extern fn spvReflectEnumerateSpecializationConstants(
        p_module: *const ShaderModule,
        p_count: *u32,
        pp_constants: ?[*]*SpecializationConstant,
    ) Result;

    /// @param  p_module        Pointer to an instance of ShaderModule.
    /// @param  binding_number  The "binding" value of the requested descriptor
    ///                         binding.
    /// @param  set_number      The "set" value of the requested descriptor binding.
    /// @param  p_result        If successful, RESULT_SUCCESS will be
    ///                         written to *p_result. Otherwise, a error code
    ///                         indicating the cause of the failure will be stored
    ///                         here.
    /// @return                 If the module contains a descriptor binding that
    ///                         matches the provided [binding_number, set_number]
    ///                         values, a pointer to that binding is returned. The
    ///                         caller must not free this pointer.
    ///                         If no match can be found, or if an unrelated error
    ///                         occurs, the return value will be NULL. Detailed
    ///                         error results are written to *pResult.
    /// @note                   If the module contains multiple desriptor bindings
    ///                         with the same set and binding numbers, there are
    ///                         no guarantees about which binding will be returned.
    extern fn spvReflectGetDescriptorBinding(
        p_module: *const ShaderModule,
        binding_number: u32,
        set_number: u32,
        p_result: *Result,
    ) ?*const DescriptorBinding;

    /// @brief  Get the descriptor binding with the given binding number and set
    ///         number that is used in the static call tree of a certain entry
    ///         point.
    /// @param  p_module        Pointer to an instance of ShaderModule.
    /// @param  entry_point     The entry point to get the binding from.
    /// @param  binding_number  The "binding" value of the requested descriptor
    ///                         binding.
    /// @param  set_number      The "set" value of the requested descriptor binding.
    /// @param  p_result        If successful, RESULT_SUCCESS will be
    ///                         written to *p_result. Otherwise, a error code
    ///                         indicating the cause of the failure will be stored
    ///                         here.
    /// @return                 If the entry point contains a descriptor binding that
    ///                         matches the provided [binding_number, set_number]
    ///                         values, a pointer to that binding is returned. The
    ///                         caller must not free this pointer.
    ///                         If no match can be found, or if an unrelated error
    ///                         occurs, the return value will be NULL. Detailed
    ///                         error results are written to *pResult.
    /// @note                   If the entry point contains multiple desriptor bindings
    ///                         with the same set and binding numbers, there are
    ///                         no guarantees about which binding will be returned.
    extern fn spvReflectGetEntryPointDescriptorBinding(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        binding_number: u32,
        set_number: u32,
        p_result: *Result,
    ) ?*const DescriptorBinding;

    /// @param  p_module    Pointer to an instance of ShaderModule.
    /// @param  set_number  The "set" value of the requested descriptor set.
    /// @param  p_result    If successful, RESULT_SUCCESS will be
    ///                     written to *p_result. Otherwise, a error code
    ///                     indicating the cause of the failure will be stored
    ///                     here.
    /// @return             If the module contains a descriptor set with the
    ///                     provided set_number, a pointer to that set is
    ///                     returned. The caller must not free this pointer.
    ///                     If no match can be found, or if an unrelated error
    ///                     occurs, the return value will be NULL. Detailed
    ///                     error results are written to *pResult.
    extern fn spvReflectGetDescriptorSet(
        p_module: *const ShaderModule,
        set_number: u32,
        p_result: *Result,
    ) ?*const DescriptorSet;

    /// @param  p_module    Pointer to an instance of ShaderModule.
    /// @param  entry_point The entry point to get the descriptor set from.
    /// @param  set_number  The "set" value of the requested descriptor set.
    /// @param  p_result    If successful, RESULT_SUCCESS will be
    ///                     written to *p_result. Otherwise, a error code
    ///                     indicating the cause of the failure will be stored
    ///                     here.
    /// @return             If the entry point contains a descriptor set with the
    ///                     provided set_number, a pointer to that set is
    ///                     returned. The caller must not free this pointer.
    ///                     If no match can be found, or if an unrelated error
    ///                     occurs, the return value will be NULL. Detailed
    ///                     error results are written to *pResult.
    extern fn spvReflectGetEntryPointDescriptorSet(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        set_number: u32,
        p_result: *Result,
    ) ?*const DescriptorSet;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  location  The "location" value of the requested input variable.
    ///                   A location of 0xFFFFFFFF will always return NULL
    ///                   with *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result  If successful, RESULT_SUCCESS will be
    ///                   written to *p_result. Otherwise, a error code
    ///                   indicating the cause of the failure will be stored
    ///                   here.
    /// @return           If the module contains an input interface variable
    ///                   with the provided location value, a pointer to that
    ///                   variable is returned. The caller must not free this
    ///                   pointer.
    ///                   If no match can be found, or if an unrelated error
    ///                   occurs, the return value will be NULL. Detailed
    ///                   error results are written to *pResult.
    extern fn spvReflectGetInputVariableByLocation(
        p_module: *const ShaderModule,
        location: u32,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module    Pointer to an instance of ShaderModule.
    /// @param  entry_point The entry point to get the input variable from.
    /// @param  location    The "location" value of the requested input variable.
    ///                     A location of 0xFFFFFFFF will always return NULL
    ///                     with *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result    If successful, RESULT_SUCCESS will be
    ///                     written to *p_result. Otherwise, a error code
    ///                     indicating the cause of the failure will be stored
    ///                     here.
    /// @return             If the entry point contains an input interface variable
    ///                     with the provided location value, a pointer to that
    ///                     variable is returned. The caller must not free this
    ///                     pointer.
    ///                     If no match can be found, or if an unrelated error
    ///                     occurs, the return value will be NULL. Detailed
    ///                     error results are written to *pResult.
    extern fn spvReflectGetEntryPointInputVariableByLocation(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        location: u32,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  semantic  The "semantic" value of the requested input variable.
    ///                   A semantic of NULL will return NULL.
    ///                   A semantic of "" will always return NULL with
    ///                   *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result  If successful, RESULT_SUCCESS will be
    ///                   written to *p_result. Otherwise, a error code
    ///                   indicating the cause of the failure will be stored
    ///                   here.
    /// @return           If the module contains an input interface variable
    ///                   with the provided semantic, a pointer to that
    ///                   variable is returned. The caller must not free this
    ///                   pointer.
    ///                   If no match can be found, or if an unrelated error
    ///                   occurs, the return value will be NULL. Detailed
    ///                   error results are written to *pResult.
    extern fn spvReflectGetInputVariableBySemantic(
        p_module: *const ShaderModule,
        semantic: [*:0]const u8,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  entry_point The entry point to get the input variable from.
    /// @param  semantic  The "semantic" value of the requested input variable.
    ///                   A semantic of NULL will return NULL.
    ///                   A semantic of "" will always return NULL with
    ///                   *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result  If successful, RESULT_SUCCESS will be
    ///                   written to *p_result. Otherwise, a error code
    ///                   indicating the cause of the failure will be stored
    ///                   here.
    /// @return           If the entry point contains an input interface variable
    ///                   with the provided semantic, a pointer to that
    ///                   variable is returned. The caller must not free this
    ///                   pointer.
    ///                   If no match can be found, or if an unrelated error
    ///                   occurs, the return value will be NULL. Detailed
    ///                   error results are written to *pResult.
    extern fn spvReflectGetEntryPointInputVariableBySemantic(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        semantic: [*:0]const u8,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  location  The "location" value of the requested output variable.
    ///                   A location of 0xFFFFFFFF will always return NULL
    ///                   with *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result  If successful, RESULT_SUCCESS will be
    ///                   written to *p_result. Otherwise, a error code
    ///                   indicating the cause of the failure will be stored
    ///                   here.
    /// @return           If the module contains an output interface variable
    ///                   with the provided location value, a pointer to that
    ///                   variable is returned. The caller must not free this
    ///                   pointer.
    ///                   If no match can be found, or if an unrelated error
    ///                   occurs, the return value will be NULL. Detailed
    ///                   error results are written to *pResult.
    extern fn spvReflectGetOutputVariableByLocation(
        p_module: *const ShaderModule,
        location: u32,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module     Pointer to an instance of ShaderModule.
    /// @param  entry_point  The entry point to get the output variable from.
    /// @param  location     The "location" value of the requested output variable.
    ///                      A location of 0xFFFFFFFF will always return NULL
    ///                      with *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result     If successful, RESULT_SUCCESS will be
    ///                      written to *p_result. Otherwise, a error code
    ///                      indicating the cause of the failure will be stored
    ///                      here.
    /// @return              If the entry point contains an output interface variable
    ///                      with the provided location value, a pointer to that
    ///                      variable is returned. The caller must not free this
    ///                      pointer.
    ///                      If no match can be found, or if an unrelated error
    ///                      occurs, the return value will be NULL. Detailed
    ///                      error results are written to *pResult.
    extern fn spvReflectGetEntryPointOutputVariableByLocation(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        location: u32,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  semantic  The "semantic" value of the requested output variable.
    ///                   A semantic of NULL will return NULL.
    ///                   A semantic of "" will always return NULL with
    ///                   *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result  If successful, RESULT_SUCCESS will be
    ///                   written to *p_result. Otherwise, a error code
    ///                   indicating the cause of the failure will be stored
    ///                   here.
    /// @return           If the module contains an output interface variable
    ///                   with the provided semantic, a pointer to that
    ///                   variable is returned. The caller must not free this
    ///                   pointer.
    ///                   If no match can be found, or if an unrelated error
    ///                   occurs, the return value will be NULL. Detailed
    ///                   error results are written to *pResult.
    extern fn spvReflectGetOutputVariableBySemantic(
        p_module: *const ShaderModule,
        semantic: [*:0]const u8,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  entry_point  The entry point to get the output variable from.
    /// @param  semantic  The "semantic" value of the requested output variable.
    ///                   A semantic of NULL will return NULL.
    ///                   A semantic of "" will always return NULL with
    ///                   *p_result == ELEMENT_NOT_FOUND.
    /// @param  p_result  If successful, RESULT_SUCCESS will be
    ///                   written to *p_result. Otherwise, a error code
    ///                   indicating the cause of the failure will be stored
    ///                   here.
    /// @return           If the entry point contains an output interface variable
    ///                   with the provided semantic, a pointer to that
    ///                   variable is returned. The caller must not free this
    ///                   pointer.
    ///                   If no match can be found, or if an unrelated error
    ///                   occurs, the return value will be NULL. Detailed
    ///                   error results are written to *pResult.
    extern fn spvReflectGetEntryPointOutputVariableBySemantic(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        semantic: [*:0]const u8,
        p_result: *Result,
    ) ?*const InterfaceVariable;

    /// @param  p_module  Pointer to an instance of ShaderModule.
    /// @param  index     The index of the desired block within the module's
    ///                   array of push constant blocks.
    /// @param  p_result  If successful, RESULT_SUCCESS will be
    ///                   written to *p_result. Otherwise, a error code
    ///                   indicating the cause of the failure will be stored
    ///                   here.
    /// @return           If the provided index is within range, a pointer to
    ///                   the corresponding push constant block is returned.
    ///                   The caller must not free this pointer.
    ///                   If no match can be found, or if an unrelated error
    ///                   occurs, the return value will be NULL. Detailed
    ///                   error results are written to *pResult.
    extern fn spvReflectGetPushConstantBlock(
        p_module: *const ShaderModule,
        index: u32,
        p_result: *Result,
    ) ?*const BlockVariable;

    /// @brief  Get the push constant block corresponding to the given entry point.
    ///         As by the Vulkan specification there can be no more than one push
    ///         constant block used by a given entry point, so if there is one it will
    ///         be returned, otherwise NULL will be returned.
    /// @param  p_module     Pointer to an instance of ShaderModule.
    /// @param  entry_point  The entry point to get the push constant block from.
    /// @param  p_result     If successful, RESULT_SUCCESS will be
    ///                      written to *p_result. Otherwise, a error code
    ///                      indicating the cause of the failure will be stored
    ///                      here.
    /// @return              If the provided index is within range, a pointer to
    ///                      the corresponding push constant block is returned.
    ///                      The caller must not free this pointer.
    ///                      If no match can be found, or if an unrelated error
    ///                      occurs, the return value will be NULL. Detailed
    ///                      error results are written to *pResult.
    extern fn spvReflectGetEntryPointPushConstantBlock(
        p_module: *const ShaderModule,
        entry_point: [*:0]const u8,
        p_result: *Result,
    ) ?*const BlockVariable;

    /// @brief  Assign new set and/or binding numbers to a descriptor binding.
    ///         In addition to updating the reflection data, this function modifies
    ///         the underlying SPIR-V bytecode. The updated code can be retrieved
    ///         with spvReflectGetCode().  If the binding is used in multiple
    ///         entry points within the module, it will be changed in all of them.
    /// @param  p_module            Pointer to an instance of ShaderModule.
    /// @param  p_binding           Pointer to the descriptor binding to modify.
    /// @param  new_binding_number  The new binding number to assign to the
    ///                             provided descriptor binding.
    ///                             To leave the binding number unchanged, pass
    ///                             BINDING_NUMBER_DONT_CHANGE.
    /// @param  new_set_number      The new set number to assign to the
    ///                             provided descriptor binding. Successfully changing
    ///                             a descriptor binding's set number invalidates all
    ///                             existing DescriptorBinding and
    ///                             DescriptorSet pointers from this module.
    ///                             To leave the set number unchanged, pass
    ///                             SET_NUMBER_DONT_CHANGE.
    /// @return                     If successful, returns RESULT_SUCCESS.
    ///                             Otherwise, the error code indicates the cause of
    ///                             the failure.
    extern fn spvReflectChangeDescriptorBindingNumbers(
        p_module: *ShaderModule,
        p_binding: *const DescriptorBinding,
        new_binding_number: u32,
        new_set_number: u32,
    ) Result;

    /// @brief  Assign a new set number to an entire descriptor set (including
    ///         all descriptor bindings in that set).
    ///         In addition to updating the reflection data, this function modifies
    ///         the underlying SPIR-V bytecode. The updated code can be retrieved
    ///         with spvReflectGetCode().  If the descriptor set is used in
    ///         multiple entry points within the module, it will be modified in all
    ///         of them.
    /// @param  p_module        Pointer to an instance of ShaderModule.
    /// @param  p_set           Pointer to the descriptor binding to modify.
    /// @param  new_set_number  The new set number to assign to the
    ///                         provided descriptor set, and all its descriptor
    ///                         bindings. Successfully changing a descriptor
    ///                         binding's set number invalidates all existing
    ///                         DescriptorBinding and
    ///                         DescriptorSet pointers from this module.
    ///                         To leave the set number unchanged, pass
    ///                         SET_NUMBER_DONT_CHANGE.
    /// @return                 If successful, returns RESULT_SUCCESS.
    ///                         Otherwise, the error code indicates the cause of
    ///                         the failure.
    extern fn spvReflectChangeDescriptorSetNumber(
        p_module: *ShaderModule,
        p_set: *const DescriptorSet,
        new_set_number: u32,
    ) Result;

    /// @brief  Assign a new location to an input interface variable.
    ///         In addition to updating the reflection data, this function modifies
    ///         the underlying SPIR-V bytecode. The updated code can be retrieved
    ///         with spvReflectGetCode().
    ///         It is the caller's responsibility to avoid assigning the same
    ///         location to multiple input variables.  If the input variable is used
    ///         by multiple entry points in the module, it will be changed in all of
    ///         them.
    /// @param  p_module          Pointer to an instance of ShaderModule.
    /// @param  p_input_variable  Pointer to the input variable to update.
    /// @param  new_location      The new location to assign to p_input_variable.
    /// @return                   If successful, returns RESULT_SUCCESS.
    ///                           Otherwise, the error code indicates the cause of
    ///                           the failure.
    extern fn spvReflectChangeInputVariableLocation(
        p_module: *ShaderModule,
        p_input_variable: *const InterfaceVariable,
        new_location: u32,
    ) Result;

    /// @brief  Assign a new location to an output interface variable.
    ///         In addition to updating the reflection data, this function modifies
    ///         the underlying SPIR-V bytecode. The updated code can be retrieved
    ///         with spvReflectGetCode().
    ///         It is the caller's responsibility to avoid assigning the same
    ///         location to multiple output variables.  If the output variable is used
    ///         by multiple entry points in the module, it will be changed in all of
    ///         them.
    /// @param  p_module          Pointer to an instance of ShaderModule.
    /// @param  p_output_variable Pointer to the output variable to update.
    /// @param  new_location      The new location to assign to p_output_variable.
    /// @return                   If successful, returns RESULT_SUCCESS.
    ///                           Otherwise, the error code indicates the cause of
    ///                           the failure.
    extern fn spvReflectChangeOutputVariableLocation(
        p_module: *ShaderModule,
        p_output_variable: *const InterfaceVariable,
        new_location: u32,
    ) Result;

    /// @param  source_lang  The source language code.
    /// @return Returns string of source language specified in \a source_lang.
    ///         The caller must not free the memory associated with this string.
    extern fn spvReflectSourceLanguage(source_lang: spv.SourceLanguage) [*:0]const u8;

    /// @param  p_var Pointer to block variable.
    /// @return Returns string of block variable's type description type name
    ///         or NULL if p_var is NULL.
    extern fn spvReflectBlockVariableTypeName(p_var: *const BlockVariable) [*:0]const u8;
};
