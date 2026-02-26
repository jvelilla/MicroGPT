note
    description: "Abstract base class for all neural network modules"

deferred class
    ET_MODULE

feature -- Access

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]
            -- All parameters of the module.
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]]} Result.make
        end

feature -- Training

    zero_grad
            -- Reset gradients of all parameters to zero.
        local
            zero_t: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_32]]
        do
            across parameters as p loop
                create zero_t.make_zeros (p.shape)
                p.set_grad (zero_t)
            end
        end

end
