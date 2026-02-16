note
    description: "Transformer Block"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    BLOCK

inherit
    MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (n_embd, n_head, block_size: INTEGER; dropout: REAL_64)
            -- Initialize with `n_embd` scale, `n_head` heads, `block_size` context.
        do
            create ln1.make (n_embd)
            create attn.make (n_embd, n_head, block_size, dropout)
            create ln2.make (n_embd)
            create mlp.make (n_embd, dropout)
        end

feature -- Access

    ln1, ln2: RMS_NORM
    attn: MULTI_HEAD_ATTENTION
    mlp: GPT_MLP

    parameters: LIST [VALUE]
            -- Learnable parameters.
        do
            create {LINKED_LIST [VALUE]} Result.make
            Result.append (ln1.parameters)
            Result.append (attn.parameters)
            Result.append (ln2.parameters)
            Result.append (mlp.parameters)
        end

feature -- Operation

    forward (x: LIST [LIST [VALUE]]): LIST [LIST [VALUE]]
            -- Apply block transformation: x + attn(ln1(x)) + mlp(ln2(x)).
        require
            input_valid: not x.is_empty
        local
            x_norm: LIST [LIST [VALUE]] -- (T, C)
            attn_out: LIST [LIST [VALUE]]
            x_res: LINKED_LIST [LIST [VALUE]]
            i: INTEGER
            row_orig, row_attn: ARRAYED_LIST [VALUE]
            row: LINKED_LIST [VALUE]
            j: INTEGER
            val: VALUE
            
            x_norm2: LINKED_LIST [LIST [VALUE]]
            mlp_out: LIST [LIST [VALUE]]
            x_final: LINKED_LIST [LIST [VALUE]]
            row_mlp: ARRAYED_LIST [VALUE]
             -- reuse row variable, distinct from above? No, local vars are function scoped.
             -- I need to ensure `row` is not redeclared if I used specific list above.
             -- Checked previous edit, `row` is local.
             -- I assume `row` handles both sections.
             -- Just check line 102.
            
            t_count: INTEGER
        do
            t_count := x.count
            
            -- x = x + attn(ln1(x))
            
            -- 1. ln1(x)
            create {LINKED_LIST [LIST [VALUE]]} x_norm.make
            across x as row_x loop
                x_norm.extend (ln1.forward (row_x))
            end
            
            -- 2. attn(x_norm)
            attn_out := attn.forward (x_norm)
            
            -- 3. x + attn_out
            create x_res.make
            -- We need to zip x and attn_out
            -- Using index
            from i := 1 until i > t_count loop
                create row_orig.make_from_iterable (x.i_th (i))
                create row_attn.make_from_iterable (attn_out.i_th (i))
                create {LINKED_LIST [VALUE]} row.make
                
                from j := 1 until j > row_orig.count loop
                    val := row_orig [j] + row_attn [j]
                    row.extend (val)
                    j := j + 1
                end
                x_res.extend (row)
                i := i + 1
            end
            
            -- x = x + mlp(ln2(x))
            
            -- 4. ln2(x_res)
            create x_norm2.make
            across x_res as row_r loop
                x_norm2.extend (ln2.forward (row_r))
            end
            
            -- 5. mlp(x_norm2) -> applied row-wise
            create {LINKED_LIST [LIST [VALUE]]} mlp_out.make
            across x_norm2 as row_n loop
                mlp_out.extend (mlp.forward (row_n))
            end
            
            -- 6. x_res + mlp_out
            create x_final.make
            from i := 1 until i > t_count loop
                create row_orig.make_from_iterable (x_res.i_th (i))
                create row_mlp.make_from_iterable (mlp_out.i_th (i))
                create {LINKED_LIST [VALUE]} row.make
                
                from j := 1 until j > row_orig.count loop
                    val := row_orig [j] + row_mlp [j]
                    row.extend (val)
                    j := j + 1
                end
                x_final.extend (row)
                i := i + 1
            end
            
            Result := x_final
        ensure
            shape_preserved: Result.count = x.count
        end

end
