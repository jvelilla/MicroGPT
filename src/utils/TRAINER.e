note
    description: "Trainer for GPT Model"

class
    TRAINER

inherit
    DOUBLE_MATH
        export {NONE} all end

create
    make

feature -- Initialization

    make (a_config: MICROGPT_CONFIG)
        do
            config := a_config
            create tokenizer.make (read_docs)
            io.put_string_32 ({STRING_32} "Vocab size: " + tokenizer.vocab_size.out.to_string_32 + {STRING_32} "%N")
            
            create gpt.make (tokenizer.vocab_size, config.n_embd, config.n_head, config.n_layer, config.block_size, config.dropout)
            io.put_string_32 ({STRING_32} "Model created. Parameters: " + gpt.parameters.count.out.to_string_32 + {STRING_32} "%N")
            
            create adam.make (gpt.parameters, config.learning_rate, 0.9, 0.999, 1.0e-8)
        end

feature -- Access

    config: MICROGPT_CONFIG
    gpt: GPT
    tokenizer: TOKENIZER
    adam: ADAM
    
    docs: ARRAYED_LIST [STRING_32]

feature -- Operations

    train
        local
            iter: INTEGER
            text: STRING_32
            data: ARRAY [INTEGER]
            xb, yb: ARRAY [INTEGER]
            logits_loss: TUPLE [logits: LIST [LIST [VALUE]]; loss: detachable VALUE]
            loss: VALUE
        do
            io.put_string_32 ({STRING_32} "Starting training for " + config.max_iters.out.to_string_32 + {STRING_32} " steps...%N")
            
            from iter := 0 until iter >= config.max_iters loop
                -- 1. Sample document (Sequential for now)
                if docs.count > 0 then
                    text := docs [(iter \\ docs.count) + 1]
                else
                    text := {STRING_32} "Empty"
                end
                
                data := tokenizer.encode (text)
                
                -- Simple batching: just take the first block_size tokens + 1
                xb := get_batch_full (data, config.block_size)
                yb := get_targets_full (data, config.block_size)
                
                if xb.count > 0 and yb.count > 0 then
                    gpt.zero_grad
                    
                    logits_loss := gpt.forward (xb, yb)
                    
                if attached logits_loss.loss as l then
                        loss := l
                        
                        -- Log every step
                        io.put_string_32 ({STRING_32} "step " + (iter + 1).out.to_string_32 + {STRING_32} " / " + config.max_iters.out.to_string_32 + {STRING_32} " | loss " + loss.data.out.to_string_32 + {STRING_32} "%N")
                        
                        loss.backward
                        adam.step
                    end
                end
                
                iter := iter + 1
            end
            
            save_checkpoint
        end
        
    generate_samples
        local
            iter: INTEGER
            gen_idx: ARRAY [INTEGER]
            gen_res: ARRAYED_LIST [INTEGER]
            start_token: INTEGER
        do
            io.put_string_32 ({STRING_32} "%N--- inference (sampling) ---%N")
            start_token := tokenizer.bos_token_id
            
            from iter := 1 until iter > 20 loop
                 create gen_idx.make_filled (start_token, 1, 1) 
                 gen_res := gpt.generate (gen_idx, 20, 0.8, tokenizer.bos_token_id) -- 0.8 temp
                 if not gen_res.is_empty then
                     -- gen_res.start
                     -- gen_res.remove -- Remove BOS if first
                 end
                 io.put_string_32 ({STRING_32} "sample " + iter.out.to_string_32 + {STRING_32} ": " + tokenizer.decode (gen_res.to_array) + {STRING_32} "%N")
                 iter := iter + 1
            end
        end

    interactive_mode
        local
            input: STRING_32

            gen_idx: ARRAY [INTEGER]
            gen_res: ARRAYED_LIST [INTEGER]
        do
            io.put_string_32 ({STRING_32} "%N--- Interactive Mode (type 'exit' to quit) ---%N")
            
            from 
                io.put_string_32 ({STRING_32} "> ")
                io.read_line
            until 
                io.last_string.to_string_32.is_equal ({STRING_32} "exit")
            loop
                input := io.last_string.to_string_32.twin
                gen_idx := tokenizer.encode (input)
                
                gen_res := gpt.generate (gen_idx, 50, 0.7, tokenizer.bos_token_id)
                io.put_string_32 (tokenizer.decode (gen_res.to_array) + {STRING_32} "%N")
                
                io.put_string_32 ({STRING_32} "> ")
                io.read_line
            end
        end

feature {NONE} -- Implementation

    read_docs: ARRAYED_LIST [STRING_32]
        local
            f: PLAIN_TEXT_FILE
            l: LINKED_LIST [STRING_32]
            line: STRING_32
        do
            create f.make_open_read (config.input_file)
            create l.make
            if f.exists and f.is_readable then
                from
                    f.read_line
                until
                    f.exhausted
                loop
                    line := f.last_string.to_string_32
                    line.right_adjust
                    if not line.is_empty then
                        l.extend (line)
                    end
                    f.read_line
                end
                f.close
            else
                io.put_string_32 ({STRING_32} "Error: Input file not found: " + config.input_file + {STRING_32} "%N")
            end
            create Result.make_from_iterable (l)
            docs := Result
            
            shuffle (docs)
        end
        
feature -- Persistence

    save_checkpoint
        local
            f: PLAIN_TEXT_FILE
        do
            create f.make_open_write ("model.ckpt")
            if f.exists and f.is_writable then
               across gpt.parameters as p loop
                   f.put_string (p.data.out + "%N")
               end
               f.close
               io.put_string_32 ({STRING_32} "Checkpoint saved to model.ckpt%N")
            else
               io.put_string_32 ({STRING_32} "Error: Cannot write to model.ckpt%N")
            end
        end

    load_checkpoint
        local
            f: PLAIN_TEXT_FILE
            line: STRING_32
            params: LIST [VALUE]
            p: VALUE
            count: INTEGER
        do
            create f.make_open_read ("model.ckpt")
            if f.exists and f.is_readable then
                io.put_string_32 ({STRING_32} "Loading checkpoint from model.ckpt...%N")
                params := gpt.parameters
                from 
                    f.read_line
                    params.start
                until 
                    f.exhausted or params.after 
                loop
                    line := f.last_string.to_string_32
                    line.left_adjust
                    line.right_adjust
                    if not line.is_empty and line.is_double then
                        p := params.item
                        p.set_data (line.to_double)
                        params.forth
                        count := count + 1
                    end
                    f.read_line
                end
                f.close
                io.put_string_32 ({STRING_32} "Loaded " + count.out.to_string_32 + {STRING_32} " parameters.%N")
            else
                io.put_string_32 ({STRING_32} "Warning: Checkpoint not found. Starting with random initialization.%N")
            end
        end

    get_batch_full (data: ARRAY [INTEGER]; block_size: INTEGER): ARRAY [INTEGER]
            -- Get input batch (x) from data, respecting block_size.
        local
            res: ARRAYED_LIST [INTEGER]
            i: INTEGER
            limit: INTEGER
        do
            limit := data.count - 1
            if limit > block_size then
                limit := block_size
            end
            
            create res.make (limit)
            from i := 1 until i > limit loop
                res.extend (data [i])
                i := i + 1
            end
            Result := res.to_array
        end
        
    get_targets_full (data: ARRAY [INTEGER]; block_size: INTEGER): ARRAY [INTEGER]
            -- Get target batch (y) from data, respecting block_size.
        local
            res: ARRAYED_LIST [INTEGER]
            i: INTEGER
            limit: INTEGER
        do
            limit := data.count - 1
            if limit > block_size then
                limit := block_size
            end
            
            create res.make (limit)
            from i := 1 until i > limit loop
                res.extend (data [i+1])
                i := i + 1
            end
            Result := res.to_array
        end
        
    shuffle (list: ARRAYED_LIST [STRING_32])
        local
            rng: RANDOM
            i, j: INTEGER
        do
            create rng.make
            rng.set_seed (config.seed)
            
            from i := list.count until i <= 1 loop
                rng.forth
                j := (rng.double_item * i).truncated_to_integer + 1
                if j > i then j := i end
                if j < 1 then j := 1 end
                
                list.go_i_th (i)
                list.swap (j)
                i := i - 1
            end
        end

end
