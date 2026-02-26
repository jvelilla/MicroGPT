note
	description: "Strategy for INTEGER_32 tensor operations."

class
	ET_TENSOR_NUMERIC_INTEGER_32

inherit
	ET_TENSOR_NUMERIC [ET_NUMERIC_ELEMENT [INTEGER_32]]

feature -- Access

	element_size: INTEGER = 4

	zero_value: ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result.set_item ({INTEGER_32} 0)
		end

	one_value: ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result.set_item ({INTEGER_32} 1)
		end

feature -- Conversion

	from_integer (v: INTEGER): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result.set_item (v)
		end

	from_real_64 (v: REAL_64): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result.set_item (v.truncated_to_integer)
		end

	to_real_64 (v: ET_NUMERIC_ELEMENT [INTEGER_32]): REAL_64
		do
			Result := v.item.to_double
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: ET_NUMERIC_ELEMENT [INTEGER_32])
		do
			a_ptr.put_integer_32 (v.item, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result.set_item (a_ptr.read_integer_32 (a_offset))
		end

feature -- Operations

	add_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_32]): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result := x.add (y)
		end

	sub_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_32]): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result := x.sub (y)
		end

	mul_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_32]): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result := x.mul (y)
		end

	div_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_32]): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result := x.div (y)
		end

	max_elements (x, y: ET_NUMERIC_ELEMENT [INTEGER_32]): ET_NUMERIC_ELEMENT [INTEGER_32]
		do
			Result := x.max_val_element (y)
		end

end
