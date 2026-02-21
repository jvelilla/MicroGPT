note
    description: "Multi-Layer Perceptron"

class
    ET_MLP

inherit
    ET_MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (nin: INTEGER; nouts: LIST [INTEGER])
            -- Create MLP with input size `nin` and layer sizes `nouts`.
        local
            sz: INTEGER
            last_n: INTEGER
        do
            create {LINKED_LIST [ET_LAYER]} layers.make
            last_n := nin
            across nouts as n loop
                layers.extend (create {ET_LAYER}.make (last_n, n))
                last_n := n
            end
        end

feature -- Access

    layers: LIST [ET_LAYER]

    parameters: LIST [ET_VALUE]
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
            across layers as l loop
                Result.append (l.parameters)
            end
        end

feature -- Operation

    forward (x: LIST [ET_VALUE]): LIST [ET_VALUE]
        local
            curr: LIST [ET_VALUE]
        do
            curr := x
            across layers as l loop
                curr := l.forward (curr)
            end
            Result := curr
        end

end
