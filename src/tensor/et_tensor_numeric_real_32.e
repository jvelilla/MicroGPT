note
	description: "Strategy for REAL_32 tensor operations."

class
	ET_TENSOR_NUMERIC_REAL_32

inherit
	ET_TENSOR_NUMERIC [ET_NUMERIC_ELEMENT [REAL_32]]

feature -- Access

	element_size: INTEGER = 4

	zero_value: ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result.set_item ({REAL_32} 0.0)
		end

	one_value: ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result.set_item ({REAL_32} 1.0)
		end

feature -- Conversion

	from_integer (v: INTEGER): ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result.set_item (v.to_real)
		end

	from_real_64 (v: REAL_64): ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result.set_item (v.truncated_to_real)
		end

	to_real_64 (v: ET_NUMERIC_ELEMENT [REAL_32]): REAL_64
		do
			Result := v.item.to_double
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: ET_NUMERIC_ELEMENT [REAL_32])
		do
			a_ptr.put_real_32 (v.item, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result.set_item (a_ptr.read_real_32 (a_offset))
		end

feature -- Operations

	add_elements (x, y: ET_NUMERIC_ELEMENT [REAL_32]): ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result := x.add (y)
		end

	sub_elements (x, y: ET_NUMERIC_ELEMENT [REAL_32]): ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result := x.sub (y)
		end

	mul_elements (x, y: ET_NUMERIC_ELEMENT [REAL_32]): ET_NUMERIC_ELEMENT [REAL_32]
		do
            -- Add temporary debug trace to detect silent faults
             -- io.put_string_32 ({STRING_32} "      [NUMERIC] Mul elements...%N")
			Result := x.mul (y)
		end

	div_elements (x, y: ET_NUMERIC_ELEMENT [REAL_32]): ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result := x.div (y)
		end

	max_elements (x, y: ET_NUMERIC_ELEMENT [REAL_32]): ET_NUMERIC_ELEMENT [REAL_32]
		do
			Result := x.max_val_element (y)
		end

end
