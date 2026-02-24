note
	description: "Represents a computing device (CPU, CUDA, NEON, etc.) for tensor operations."

class
	ET_DEVICE

create
	make_cpu

feature {NONE} -- Initialization

	make_cpu
			-- Initialize as CPU device.
		do
			is_cpu := True
		end

feature -- Access

	is_cpu: BOOLEAN
			-- Is this device the CPU?

end
