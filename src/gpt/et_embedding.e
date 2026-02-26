note
    description: "Embedding Layer"
    original_source: "Port of https://gist.github.com/karpathy/8627fe009c40f57531cb18360106ce95"

class
    ET_EMBEDDING

inherit
    ET_MODULE
        redefine
            parameters
        end

create
    make

feature -- Initialization

    make (vocab_size, n_embd: INTEGER)
            -- Initialize embedding table.
            -- `vocab_size`: number of embeddings.
            -- `n_embd`: embedding dimension.
        local
            t_scale: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            numeric_helper: ET_TENSOR_NUMERIC_REAL_64
        do
            create numeric_helper
            create weight.make_randn (<<vocab_size, n_embd>>)
            
            -- Scale weights by 0.08
            create t_scale.make_full (<<1>>, numeric_helper.from_real_64 (0.08))
            weight := weight * t_scale
            weight.set_requires_grad (True)
            
            num_embeddings := vocab_size
            embedding_dim := n_embd
        end

feature -- Access

    weight: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
    num_embeddings, embedding_dim: INTEGER

    parameters: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            -- Learnable weight parameters.
        do
            create {LINKED_LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]} Result.make
            Result.extend (weight)
        end

feature -- Operation

    forward (idx: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]): ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            -- Retrieve embedding vectors for indices `idx`.
            -- `idx` shape: [batch_size, seq_len] or [seq_len]
            -- Returns shape: [batch_size, seq_len, embedding_dim] or [seq_len, embedding_dim]
        local
            res_shape: ARRAY [INTEGER]
            i, j, flat_idx, w_offset, res_offset: INTEGER
            numeric_i32: ET_TENSOR_NUMERIC_INTEGER_32
            numeric_r32: ET_TENSOR_NUMERIC_REAL_64
            val: INTEGER_32
            i32_size: INTEGER  -- byte size for INTEGER_32 index tensor
            float_size: INTEGER  -- byte size for REAL_64 weight/result tensors
            w_stride_0: INTEGER
        do
            create res_shape.make_from_array (idx.shape)
            res_shape.force (embedding_dim, res_shape.count + 1)
            
            create Result.make_zeros (res_shape)
            create numeric_i32
            create numeric_r32
            i32_size := 4
            float_size := 8
            
            w_stride_0 := embedding_dim -- elements per row
            -- Gather embeddings efficiently
            from i := 0 until i >= idx.numel loop
                val := numeric_i32.read (idx.data, idx.offset + i * i32_size).item
                if val > 0 and then val <= num_embeddings then 
                    flat_idx := val.to_integer_32 - 1
                    
                    w_offset := weight.offset + flat_idx * w_stride_0 * float_size
                    res_offset := Result.offset + i * embedding_dim * float_size
                    from j := 0 until j >= w_stride_0 loop
                        numeric_r32.put (Result.data, res_offset + j * float_size, numeric_r32.read (weight.data, w_offset + j * float_size))
                        j := j + 1
                    end
                end
                
                i := i + 1
            end
            
            if Result.requires_grad or weight.requires_grad then
                Result.set_requires_grad (True)
                Result.set_backward_fn (agent backward_embedding (Result, Current, idx))
            end
        end

feature {NONE} -- Autograd

    backward_embedding (res: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]; cur: ET_EMBEDDING; idx: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]])
        local
            g: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            grad_w: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            i, j, flat_idx, w_offset, res_offset: INTEGER
            numeric_i32: ET_TENSOR_NUMERIC_INTEGER_32
            numeric_r32: ET_TENSOR_NUMERIC_REAL_64
            val: INTEGER_32
            i32_size, float_size, w_stride_0: INTEGER
            l_gv, l_wv: REAL_64
        do
            if attached res.grad as l_g then
                g := l_g
                if cur.weight.requires_grad then
                    create grad_w.make_zeros (cur.weight.shape)
                    create numeric_i32
                    create numeric_r32
                    i32_size := 4
                    float_size := 8
                    w_stride_0 := cur.embedding_dim

                    from i := 0 until i >= idx.numel loop
                        val := numeric_i32.read (idx.data, idx.offset + i * i32_size).item
                        if val > 0 and then val <= cur.num_embeddings then
                            flat_idx := val.to_integer_32 - 1
                            w_offset := grad_w.offset + flat_idx * w_stride_0 * float_size
                            res_offset := g.offset + i * cur.embedding_dim * float_size

                            from j := 0 until j >= w_stride_0 loop
                                l_gv := numeric_r32.read (g.data, res_offset + j * float_size).item
                                l_wv := numeric_r32.read (grad_w.data, w_offset + j * float_size).item
                                numeric_r32.put (grad_w.data, w_offset + j * float_size, numeric_r32.from_real_64 (l_wv + l_gv))
                                j := j + 1
                            end
                        end
                        i := i + 1
                    end
                    cur.weight.accumulate_grad (grad_w)
                end
            end
        end

invariant
    valid_dims: embedding_dim > 0
    valid_num_embeddings: num_embeddings > 0

end
