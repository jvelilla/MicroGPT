note
    description: "Abstract base class for all neural network modules"

deferred class
    ET_MODULE

feature -- Access

    parameters: LIST [ET_VALUE]
            -- All parameters of the module.
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
        end

feature -- Training

    zero_grad
            -- Reset gradients of all parameters to zero.
        do
            across parameters as p loop
                p.set_grad (0.0)
            end
        end

end
