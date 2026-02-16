note
    description: "Multi-Layer Perceptron"

class
    MLP

inherit
    MODULE
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
            create {LINKED_LIST [LAYER]} layers.make
            last_n := nin
            across nouts as n loop
                layers.extend (create {LAYER}.make (last_n, n))
                last_n := n
            end
        end

feature -- Access

    layers: LIST [LAYER]

    parameters: LIST [VALUE]
        do
            create {LINKED_LIST [VALUE]} Result.make
            across layers as l loop
                Result.append (l.parameters)
            end
        end

feature -- Operation

    forward (x: LIST [VALUE]): LIST [VALUE]
        local
            curr: LIST [VALUE]
        do
            curr := x
            across layers as l loop
                curr := l.forward (curr)
            end
            Result := curr
        end

end
