note
	description: "Strategy for INTEGER_32 tensor operations."

class
	ET_TENSOR_NUMERIC_INTEGER_32

inherit
	ET_TENSOR_NUMERIC [INTEGER_32]

feature -- Access

	element_size: INTEGER = 4

	zero_value: INTEGER_32 = 0

	one_value: INTEGER_32 = 1

feature -- Conversion

	from_integer (v: INTEGER): INTEGER_32
		do
			Result := v.to_integer_32
		end

	from_real_64 (v: REAL_64): INTEGER_32
		do
			Result := v.truncated_to_integer
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: INTEGER_32)
		do
			a_ptr.put_integer_32 (v, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): INTEGER_32
		do
			Result := a_ptr.read_integer_32 (a_offset)
		end

end
