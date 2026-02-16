note
    description: "GPT Feed Forward Module"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    GPT_MLP

inherit
    MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (n_embd: INTEGER; a_dropout: REAL_64)
            -- Initialize with embedding dimension `n_embd`.
        do
            create c_fc.make (n_embd, 4 * n_embd, True)
            create c_proj.make (4 * n_embd, n_embd, True)
            dropout := a_dropout
        end

feature -- Access

    c_fc: NN_LINEAR
    c_proj: NN_LINEAR
    dropout: REAL_64

    parameters: LIST [VALUE]
            -- Learnable parameters.
        do
            create {LINKED_LIST [VALUE]} Result.make
            Result.append (c_fc.parameters)
            Result.append (c_proj.parameters)
        end

feature -- Operation

    forward (x: LIST [VALUE]): LIST [VALUE]
            -- Apply MLP: proj(gelu(fc(x))).
        
        local
            h: LIST [VALUE]
            h_gelu: LINKED_LIST [VALUE]
        do
            h := c_fc.forward (x)
            create h_gelu.make
            across h as val loop
                h_gelu.extend (val.relu)
            end
            Result := c_proj.forward (h_gelu)
        end

end
