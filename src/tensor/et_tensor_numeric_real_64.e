note
	description: "Strategy for REAL_64 tensor operations."

class
	ET_TENSOR_NUMERIC_REAL_64

inherit
	ET_TENSOR_NUMERIC [REAL_64]

feature -- Access

	element_size: INTEGER = 8

	zero_value: REAL_64 = 0.0

	one_value: REAL_64 = 1.0

feature -- Conversion

	from_integer (v: INTEGER): REAL_64
		do
			Result := v.to_double
		end

	from_real_64 (v: REAL_64): REAL_64
		do
			Result := v
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: REAL_64)
		do
			a_ptr.put_real_64 (v, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): REAL_64
		do
			Result := a_ptr.read_real_64 (a_offset)
		end

end
