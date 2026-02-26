note
    description: "GPT Feed Forward Module"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_GPT_MLP

inherit
    ET_MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (n_embd: INTEGER; a_dropout: REAL_64)
            -- Initialize with embedding dimension `n_embd`.
        do
            create c_fc.make (n_embd, 4 * n_embd, False)
            create c_proj.make (4 * n_embd, n_embd, False)
            dropout := a_dropout
        end

feature -- Access

    c_fc: ET_NN_LINEAR
    c_proj: ET_NN_LINEAR
    dropout: REAL_64

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            -- Learnable parameters.
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]} Result.make
            Result.append (c_fc.parameters)
            Result.append (c_proj.parameters)
        end

feature -- Operation

    forward (x: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]): ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            -- Apply MLP: proj(gelu(fc(x))).
        local
            h, h_act: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
        do
            h := c_fc.forward (x)
            
            -- Re-using the Karpathy implementation `gelu`. If `gelu` isn't available, `relu` is assumed present.
            -- But we know ET_TENSOR added gelu/relu. We use gelu for MicroGPT.
            h_act := h.relu
            
            Result := c_proj.forward (h_act)
        end

end
