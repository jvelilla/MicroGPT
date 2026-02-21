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
            rng: RANDOM
            i: INTEGER
            u1, u2, z0: REAL_64
        do
            rng := shared_rng
            
            create {LINKED_LIST [ET_VALUE]} weight.make
            
            from i := 1 until i > vocab_size * n_embd loop
                rng.forth
                u1 := rng.double_item
                rng.forth
                u2 := rng.double_item
                
                -- Box-Muller transform
                z0 := {DOUBLE_MATH}.sqrt (-2.0 * {DOUBLE_MATH}.log (u1)) * {DOUBLE_MATH}.cosine (2.0 * {DOUBLE_MATH}.pi * u2)
                
                weight.extend (create {ET_VALUE}.make (z0 * 0.08))
                i := i + 1
            end
            
            num_embeddings := vocab_size
            embedding_dim := n_embd
        end

    feature {NONE} -- Internals

    shared_rng: RANDOM
        once
            create Result.make
            Result.set_seed (42) 
        end

feature -- Access

    weight: LINKED_LIST [ET_VALUE]
    num_embeddings, embedding_dim: INTEGER

    parameters: LIST [ET_VALUE]
            -- Learnable weight parameters.
        do
            create {LINKED_LIST [ET_VALUE]} Result.make
            Result.append (weight)
        end

feature -- Operation

    forward (idx: INTEGER): LIST [ET_VALUE]
            -- Retrieve embedding vector for index `idx`.
        require
            valid_index: idx >= 1 and idx <= num_embeddings -- 1-based index
        local
            res: LINKED_LIST [ET_VALUE]
            w_arr: ARRAYED_LIST [ET_VALUE]
            start_pos: INTEGER
            i: INTEGER
        do
            create res.make
            create w_arr.make_from_iterable (weight)
            
            -- Get row `idx`
            -- row size is `embedding_dim`
            start_pos := (idx - 1) * embedding_dim
            
            from i := 1 until i > embedding_dim loop
                res.extend (w_arr [start_pos + i])
                i := i + 1
            end
            
            Result := res
        ensure
            correct_size: Result.count = embedding_dim
        end

invariant
    valid_dims: embedding_dim > 0
    valid_num_embeddings: num_embeddings > 0
    weights_sized: weight.count = num_embeddings * embedding_dim

end
