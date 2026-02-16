note
    description: "Abstract base class for all neural network modules"

deferred class
    MODULE

feature -- Access

    parameters: LIST [VALUE]
            -- All parameters of the module.
        do
            create {LINKED_LIST [VALUE]} Result.make
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
