note
	description: "Strategy for BOOLEAN tensor operations."

class
	ET_TENSOR_NUMERIC_BOOLEAN

inherit
	ET_TENSOR_NUMERIC [ET_BOOLEAN_ELEMENT]

feature -- Access

	element_size: INTEGER = 1

	zero_value: ET_BOOLEAN_ELEMENT
		do
			Result.set_item (False)
		end

	one_value: ET_BOOLEAN_ELEMENT
		do
			Result.set_item (True)
		end

feature -- Conversion

	from_integer (v: INTEGER): ET_BOOLEAN_ELEMENT
		do
			Result.set_item (v /= 0)
		end

	from_real_64 (v: REAL_64): ET_BOOLEAN_ELEMENT
		do
			Result.set_item (v /= 0.0)
		end

	to_real_64 (v: ET_BOOLEAN_ELEMENT): REAL_64
		do
			if v.item then
				Result := 1.0
			else
				Result := 0.0
			end
		end

feature -- Pointer Operations

	put (a_ptr: MANAGED_POINTER; a_offset: INTEGER; v: ET_BOOLEAN_ELEMENT)
		local
			b: INTEGER_8
		do
			if v.item then
				b := 1
			else
				b := 0
			end
			a_ptr.put_integer_8 (b, a_offset)
		end

	read (a_ptr: MANAGED_POINTER; a_offset: INTEGER): ET_BOOLEAN_ELEMENT
		local
			b: INTEGER_8
		do
			b := a_ptr.read_integer_8 (a_offset)
			Result.set_item (b /= 0)
		end

feature -- Operations

	add_elements (x, y: ET_BOOLEAN_ELEMENT): ET_BOOLEAN_ELEMENT
		do
			Result.set_item (x.item or y.item)
		end

	sub_elements (x, y: ET_BOOLEAN_ELEMENT): ET_BOOLEAN_ELEMENT
		do
			Result.set_item (x.item and not y.item)
		end

	mul_elements (x, y: ET_BOOLEAN_ELEMENT): ET_BOOLEAN_ELEMENT
		do
			Result.set_item (x.item and y.item)
		end

	div_elements (x, y: ET_BOOLEAN_ELEMENT): ET_BOOLEAN_ELEMENT
		do
			Result.set_item (x.item)
		end

	max_elements (x, y: ET_BOOLEAN_ELEMENT): ET_BOOLEAN_ELEMENT
		do
			if x.item or y.item then
				Result.set_item (True)
			else
				Result.set_item (False)
			end
		end

end
