note
    description: "A layer of neurons"

class
    ET_LAYER

inherit
    ET_MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (nin, nout: INTEGER)
            -- Create a layer with `nout` neurons, each with `nin` inputs.
        local
            i: INTEGER
        do
            create {LINKED_LIST [ET_NEURON]} neurons.make
            from
                i := 1
            until
                i > nout
            loop
                neurons.extend (create {ET_NEURON}.make_with_seed (nin, i * 100)) -- spread seeds
                i := i + 1
            end
        end

feature -- Access

    neurons: LIST [ET_NEURON]

    parameters: LIST [ET_VALUE]
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
            across neurons as n loop
                Result.append (n.parameters)
            end
        end

feature -- Operation

    forward (x: LIST [ET_VALUE]): LIST [ET_VALUE]
        local
            outs: LINKED_LIST [ET_VALUE]
        do
            create outs.make
            across neurons as n loop
                outs.extend (n.forward (x))
            end
            Result := outs
        end

end
