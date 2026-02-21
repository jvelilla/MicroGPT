note
	description: "Abstract element type for ET_TENSOR. Provides arithmetic and comparison operations."

deferred class
	ET_TENSOR_ELEMENT

inherit
	COMPARABLE
		undefine
			out
		end

feature -- Arithmetic (deferred, implemented by concrete element types)

	plus alias "+" (other: like Current): like Current
			-- Addition.
		deferred
		end

	minus alias "-" (other: like Current): like Current
			-- Subtraction.
		deferred
		end

	product alias "*" (other: like Current): like Current
			-- Multiplication.
		deferred
		end

	quotient alias "/" (other: like Current): like Current
			-- Division.
		deferred
		end

	negated alias "-": like Current
			-- Unary negation.
		deferred
		end

feature -- Output

	out: STRING
		deferred
		end

end
