note
	description: "Strategy for REAL_32 tensor operations."

class
	ET_TENSOR_NUMERIC_REAL_32

inherit
	ET_TENSOR_NUMERIC [REAL_32]

feature -- Access

	element_size: INTEGER = 4

	zero_value: REAL_32 = 0.0

	one_value: REAL_32 = 1.0

feature -- Conversion

	from_integer (v: INTEGER): REAL_32
		do
			Result := v.to_real
		end

	from_real_64 (v: REAL_64): REAL_32
		do
			Result := v.truncated_to_real
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: REAL_32)
		do
			a_ptr.put_real_32 (v, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): REAL_32
		do
			Result := a_ptr.read_real_32 (a_offset)
		end

end
