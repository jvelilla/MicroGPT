note
	description: "Tag class representing a boolean element in an ET_TENSOR."

expanded class
	ET_BOOLEAN_ELEMENT

inherit
	ET_TENSOR_ELEMENT

feature -- Access

	item: BOOLEAN

feature -- Element Change

	set_item (a_item: BOOLEAN)
		do
			item := a_item
		end

feature -- Arithmetic operators (ET_TENSOR_ELEMENT deferred implementation)
	-- Boolean tensors do not support arithmetic; these exist to satisfy the interface.

	plus alias "+" (other: like Current): like Current
		do
			Result.set_item (item or other.item) -- Logical OR as addition
		end

	minus alias "-" (other: like Current): like Current
		do
			Result.set_item (item and not other.item)
		end

	product alias "*" (other: like Current): like Current
		do
			Result.set_item (item and other.item) -- Logical AND as multiplication
		end

	quotient alias "/" (other: like Current): like Current
		do
			Result.set_item (item) -- N/A for boolean
		end

	negated alias "-": like Current
		do
			Result.set_item (not item)
		end

feature -- Comparison

	is_less alias "<" (other: like Current): BOOLEAN
		do
			-- False < True
			Result := (not item) and other.item
		end


feature -- Output

	out: STRING
		do
			Result := item.out
		end

end
