note
	description: "Strategy for INTEGER_64 tensor operations."

class
	ET_TENSOR_NUMERIC_INTEGER_64

inherit
	ET_TENSOR_NUMERIC [INTEGER_64]

feature -- Access

	element_size: INTEGER = 8

	zero_value: INTEGER_64 = 0

	one_value: INTEGER_64 = 1

feature -- Conversion

	from_integer (v: INTEGER): INTEGER_64
		do
			Result := v.to_integer_64
		end

	from_real_64 (v: REAL_64): INTEGER_64
		do
			Result := v.truncated_to_integer_64
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: INTEGER_64)
		do
			a_ptr.put_integer_64 (v, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): INTEGER_64
		do
			Result := a_ptr.read_integer_64 (a_offset)
		end

end
