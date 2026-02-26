note
	description: "Tag class representing a numeric element in an ET_TENSOR."

expanded class
	ET_NUMERIC_ELEMENT [G -> NUMERIC create default_create end]

inherit
	ET_TENSOR_ELEMENT
		redefine
			default_create
		end

feature -- Access

	item: G

feature {NONE} -- Initialization

	default_create
		do
			create item
		end

feature -- Element Change

	set_item (a_item: G)
		do
			item := a_item
		end

feature -- Arithmetic operators (implements ET_TENSOR_ELEMENT deferred features)

	plus alias "+" (other: like Current): like Current
		do
			Result := add (other)
		end

	minus alias "-" (other: like Current): like Current
		do
			Result := sub (other)
		end

	product alias "*" (other: like Current): like Current
		do
			Result := mul (other)
		end

	quotient alias "/" (other: like Current): like Current
		do
			Result := div (other)
		end

	negated alias "-": like Current
		do
			Result := neg
		end

feature -- Typed arithmetic (convenience, used by tensor operations)

	add (other: like Current): like Current
		local
			l_res: like Current
		do
			l_res.set_item (item + other.item)
			Result := l_res
		end

	sub (other: like Current): like Current
		local
			l_res: like Current
		do
			l_res.set_item (item - other.item)
			Result := l_res
		end

	mul (other: like Current): like Current
		local
			l_res: like Current
		do
			l_res.set_item (item * other.item)
			Result := l_res
		end

	div (other: like Current): like Current
		local
			l_res: like Current
		do
			l_res.set_item (item / other.item)
			Result := l_res
		end

	neg: like Current
		local
			l_res: like Current
		do
			l_res.set_item (-item)
			Result := l_res
		end

	max_val_element (other: like Current): like Current
		local
			l_res: like Current
		do
			if is_less (other) then
				l_res.set_item (other.item)
			else
				l_res.set_item (item)
			end
			Result := l_res
		end

feature -- COMPARABLE

	is_less alias "<" (other: like Current): BOOLEAN
		do
			if attached {COMPARABLE} item as c1 and then attached {COMPARABLE} other.item as c2 then
				Result := c1 < c2
			else
				Result := False
			end
		end



feature -- Output

	out: STRING
		do
			Result := item.out
		end

end
