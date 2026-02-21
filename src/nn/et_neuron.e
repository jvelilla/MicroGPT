note
    description: "A single neuron defined by w * x + b"

class
    ET_NEURON

inherit
    ET_MODULE
        redefine
            parameters
        end

    DOUBLE_MATH
        export
            {NONE} all
        end

create
    make,
    make_with_seed

feature -- Initialization

    make (nin: INTEGER)
            -- Initialize neuron with `nin` inputs.
        local
            rng: RANDOM
            i: INTEGER
        do
            create rng.make
            rng.set_seed (123) -- Fixed seed for reproducibility for now? Or better time based?
            -- Actually, for now let's use a simple deterministic init or pseudo-random
            -- But we need random weights.
            -- Let's use `TIME`? Or just a simple LCG here?
            -- For simplicity in this port, I'll use a fixed seed LCG if standard RANDOM is annoying,
            -- but RANDOM is fine.
            -- Wait, standard RANDOM is in base.

            create w.make
            from
                i := 1
            until
                i > nin
            loop
                rng.forth
                -- Random between -1 and 1
                w.extend (create {ET_VALUE}.make (rng.double_item * 2.0 - 1.0))
                i := i + 1
            end

            rng.forth
            create b.make (rng.double_item * 2.0 - 1.0)
        end

    make_with_seed (nin: INTEGER; seed: INTEGER)
        local
            rng: RANDOM
            i: INTEGER
        do
            create rng.make
            rng.set_seed (seed)
            create w.make
            from
                i := 1
            until
                i > nin
            loop
                rng.forth
                w.extend (create {ET_VALUE}.make (rng.double_item * 2.0 - 1.0))
                i := i + 1
            end
            rng.forth
            b := create {ET_VALUE}.make (rng.double_item * 2.0 - 1.0)
        end

feature -- Access

    w: LINKED_LIST [ET_VALUE]
    b: ET_VALUE

    parameters: LIST [ET_VALUE]
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
            Result.append (w)
            Result.extend (b)
        end

feature -- Operation

    forward (x: LIST [ET_VALUE]): ET_VALUE
        require
            same_size: x.count = w.count
        local
            act: ET_VALUE
            wi, xi: ET_VALUE
            cursor_w, cursor_x: CURSOR
        do
            act := b

            -- Can't easily use across for parallel iteration, so using index or cursors
            from
                w.start
                x.start
            until
                w.after
            loop
                act := act + (w.item * x.item)
                w.forth
                x.forth
            end

            -- Activation function?
            -- Karpathy's neuron usually has Relu or Tanh.
            -- MicroGPT tweet says "relu, tanh - if needed".
            -- But for GPT usually we use purely Linear in projections and GELU in MLP.
            -- This NEURON class is for the standard Micrograd demo.
            -- For GPT we might strictly use `LINEAR` layer which is just matmul.

            -- Let's keep it generic: Micrograd Neuron is Tanh or ReLU.
            -- I'll define it as ReLU for now as it's simpler and used in GPT (ReLU/GELU).
            -- Actually, for Micrograd parity it is Tanh?
            -- The prompt says "Training and inference GPT ... atomic operations".
            -- It likely doesn't imply using this `NEURON` class for GPT, but rather `LINEAR`.
            -- But `NEURON` is part of standard Micrograd. I'll include it for completeness as per plan.
            -- I'll return the linear activation act, so the user can apply non-linearity outside or use a subclass?
            -- No, a "Neuron" in Micrograd usually includes the non-linearity.
            -- I'll make it linear + ReLu.

             Result := act.relu
        end

end
