package main

import "base:intrinsics"
import "core:fmt"
import "core:os"

FILENAME :: "Main.class"

U4_BUFFER: [4]u8
U2_BUFFER: [2]u8
U1_BUFFER: [1]u8

parse_u1 :: proc(f: os.Handle) -> u8 {
	bytes_read, err := os.read(f, U1_BUFFER[:])
	if err != 0 || bytes_read != 1 {
		panic("couldn't read 1 bytes")
	}
	return transmute(u8)U1_BUFFER
}

parse_u2 :: proc(f: os.Handle) -> u16be {
	bytes_read, err := os.read(f, U2_BUFFER[:])
	if err != 0 || bytes_read != 2 {
		panic("couldn't read 2 bytes")
	}
	return transmute(u16be)U2_BUFFER
}

parse_u4 :: proc(f: os.Handle) -> u32be {
	bytes_read, err := os.read(f, U4_BUFFER[:])
	if err != 0 || bytes_read != 4 {
		panic("couldn't read 4 bytes")
	}
	return transmute(u32be)U4_BUFFER
}

parse_byte_array :: proc(f: os.Handle, length: $T) -> []u8 where intrinsics.type_is_numeric(T) {
	byte_buf := make([]u8, length)
	bytes_read, err := os.read(f, byte_buf[:])
	if err != 0 || T(bytes_read) != length {
		panic("couldn't read length bytes")
	}
	return byte_buf
}

parse_interfaces :: proc(f: os.Handle, count: u16be) -> []u16be {
	interfaces := make([]u16be, count)
	for &interface in interfaces {
		interface = parse_u2(f)
	}
	return interfaces
}

parse_attribute_info :: proc(f: os.Handle, count: u16be) -> []Attribute_Info {
	attributes := make([]Attribute_Info, count)
	for &attribute in attributes {
		attribute.attribute_name_index = parse_u2(f)
		attribute.attribute_length = parse_u4(f)
		attribute.info = parse_byte_array(f, attribute.attribute_length)
	}
	return attributes
}

parse_method_info :: proc(f: os.Handle, count: u16be) -> []Method_Info {
	methods := make([]Method_Info, count)
	for &method in methods {
		method.access_flags = parse_u2(f)
		method.name_index = parse_u2(f)
		method.descriptor_index = parse_u2(f)
		method.attributes_count = parse_u2(f)
		method.attributes = parse_attribute_info(f, method.attributes_count)
	}
	return methods
}

parse_field_info :: proc(f: os.Handle, count: u16be) -> []Field_Info {
	fields := make([]Field_Info, count)
	for &field in fields {
		field.access_flags = parse_u2(f)
		field.name_index = parse_u2(f)
		field.descriptor_index = parse_u2(f)
		field.attributes_count = parse_u2(f)
		field.attributes = parse_attribute_info(f, field.attributes_count)
	}
	return fields
}

parse_cp_info :: proc(f: os.Handle, count: u16be) -> []Cp_Info {
	cp_infos := make([]Cp_Info, count - 1)
	for &cp_info in cp_infos {
		raw_tag := parse_u1(f)
		cp_info.tag = Constant_Kind(raw_tag)

		#partial switch cp_info.tag {
		case .Methodref:
			cp_info.data = CONSTANT_Methodref {
				class_index         = parse_u2(f),
				name_and_type_index = parse_u2(f),
			}
		case .Class:
			cp_info.data = CONSTANT_Class {
				name_index = parse_u2(f),
			}
		case .NameAndType:
			cp_info.data = CONSTANT_NameAndType {
				name_index       = parse_u2(f),
				descriptor_index = parse_u2(f),
			}
		case .Utf8:
			length := parse_u2(f)
			bytes := parse_byte_array(f, length)
			cp_info.data = CONSTANT_Utf8 {
				length = length,
				bytes  = bytes,
			}
			fmt.println(transmute(string)bytes)
		case .Fieldref:
			cp_info.data = CONSTANT_Fieldref {
				class_index         = parse_u2(f),
				name_and_type_index = parse_u2(f),
			}
		case .String:
			cp_info.data = CONSTANT_String {
				string_index = parse_u2(f),
			}
		case:
			fmt.println("Cp_info tag:", raw_tag, "not implemented")
			os.exit(1)
		}

	}
	return cp_infos
}

CONSTANT_String :: struct {
	string_index: u16be,
}

CONSTANT_Fieldref :: struct {
	class_index:         u16be,
	name_and_type_index: u16be,
}

CONSTANT_Methodref :: struct {
	class_index:         u16be,
	name_and_type_index: u16be,
}

CONSTANT_Class :: struct {
	name_index: u16be,
}

CONSTANT_NameAndType :: struct {
	name_index:       u16be,
	descriptor_index: u16be,
}

CONSTANT_Utf8 :: struct {
	length: u16be,
	bytes:  []u8,
}

Constant_Kind :: enum u8 {
	Utf8               = 1,
	Integer            = 3,
	Float              = 4,
	Long               = 5,
	Double             = 6,
	Class              = 7,
	String             = 8,
	Fieldref           = 9,
	Methodref          = 10,
	InterfaceMethodref = 11,
	NameAndType        = 12,
	MethodHandle       = 15,
	MethodType         = 16,
	Dynamic            = 17,
	InvokeDynamic      = 18,
	Module             = 19,
	Package            = 20,
}

Class_File :: struct {
	magic:               u32be,
	minor_version:       u16be,
	major_version:       u16be,
	constant_pool_count: u16be,
	constant_pool:       []Cp_Info,
	// TODO: convert into a bit_set with an enum backing it
	access_flags:        u16be,
	this_class:          u16be,
	super_class:         u16be,
	interfaces_count:    u16be,
	interfaces:          []u16be,
	fields_count:        u16be,
	fields:              []Field_Info,
	methods_count:       u16be,
	methods:             []Method_Info,
	attributes_count:    u16be,
	attributes:          []Attribute_Info,
}

Cp_Info :: struct {
	tag:  Constant_Kind,
	data: union {
		CONSTANT_Methodref,
		CONSTANT_Class,
		CONSTANT_NameAndType,
		CONSTANT_Utf8,
		CONSTANT_Fieldref,
		CONSTANT_String,
	},
}

Field_Info :: struct {
	access_flags:     u16be,
	name_index:       u16be,
	descriptor_index: u16be,
	attributes_count: u16be,
	attributes:       []Attribute_Info,
}

Method_Info :: struct {
	access_flags:     u16be,
	name_index:       u16be,
	descriptor_index: u16be,
	attributes_count: u16be,
	attributes:       []Attribute_Info,
}

Attribute_Info :: struct {
	attribute_name_index: u16be,
	attribute_length:     u32be,
	info:                 []u8,
}

class_file: Class_File

main :: proc() {
	handle, err := os.open(FILENAME, os.O_RDONLY)
	if err != 0 {
		panic("Could not open file")
	}

	class_file.magic = parse_u4(handle)
	class_file.minor_version = parse_u2(handle)
	class_file.major_version = parse_u2(handle)
	class_file.constant_pool_count = parse_u2(handle)
	class_file.constant_pool = parse_cp_info(handle, class_file.constant_pool_count)
	class_file.access_flags = parse_u2(handle)
	class_file.this_class = parse_u2(handle)
	class_file.super_class = parse_u2(handle)
	class_file.interfaces_count = parse_u2(handle)
	class_file.interfaces = parse_interfaces(handle, class_file.interfaces_count)
	class_file.fields_count = parse_u2(handle)
	class_file.fields = parse_field_info(handle, class_file.fields_count)
	class_file.methods_count = parse_u2(handle)
	class_file.methods = parse_method_info(handle, class_file.methods_count)
	class_file.attributes_count = parse_u2(handle)
	class_file.attributes = parse_attribute_info(handle, class_file.attributes_count)

	fmt.println(class_file)
}
