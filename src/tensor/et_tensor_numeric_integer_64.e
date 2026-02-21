note
	description: "Strategy for INTEGER_64 tensor operations."

class
	ET_TENSOR_NUMERIC_INTEGER_64

inherit
	ET_TENSOR_NUMERIC [ET_NUMERIC_ELEMENT [INTEGER_64]]

feature -- Access

	element_size: INTEGER = 8

	zero_value: ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result.set_item ({INTEGER_64} 0)
		end

	one_value: ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result.set_item ({INTEGER_64} 1)
		end

feature -- Conversion

	from_integer (v: INTEGER): ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result.set_item (v.to_integer_64)
		end

	from_real_64 (v: REAL_64): ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result.set_item (v.truncated_to_integer_64)
		end

	to_real_64 (v: ET_NUMERIC_ELEMENT [INTEGER_64]): REAL_64
		do
			Result := v.item.to_double
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: ET_NUMERIC_ELEMENT [INTEGER_64])
		do
			a_ptr.put_integer_64 (v.item, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result.set_item (a_ptr.read_integer_64 (a_offset))
		end

feature -- Operations

	add_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_64]): ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result := x.add (y)
		end

	sub_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_64]): ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result := x.sub (y)
		end

	mul_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_64]): ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result := x.mul (y)
		end

	div_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_64]): ET_NUMERIC_ELEMENT [INTEGER_64]
		do
			Result := x.div (y)
		end

end
