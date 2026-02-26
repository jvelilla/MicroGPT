note
    description: "Trainer for GPT Model"

class
    ET_TRAINER

inherit
    DOUBLE_MATH
        export {NONE} all end

create
    make

feature -- Initialization

    make (a_config: ET_MICROGPT_CONFIG)
        do
            config := a_config
            create tokenizer.make (read_docs)
            io.put_string_32 ({STRING_32} "Vocab size: " + tokenizer.vocab_size.out.to_string_32 + {STRING_32} "%N")

            create gpt.make (tokenizer.vocab_size, config.n_embd, config.n_head, config.n_layer, config.block_size, config.dropout)
            io.put_string_32 ({STRING_32} "Model created. Parameters: " + gpt.parameters.count.out.to_string_32 + {STRING_32} "%N")

            create adam.make (gpt.parameters, config.learning_rate, 0.85, 0.99, 1.0e-8)
        end

feature -- Access

    config: ET_MICROGPT_CONFIG
    gpt: ET_GPT
    tokenizer: ET_TOKENIZER
    adam: ET_ADAM

    docs: ARRAYED_LIST [STRING_32]

feature -- Operations

    train
        local
            iter, seq_idx: INTEGER
            text: STRING_32
            data: ARRAY [INTEGER]
            xb, yb: ARRAY [INTEGER]
            t_xb, t_yb: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            logits_loss: ARRAY [detachable ANY]
            lr, decay_ratio, coeff, warmup_iters, lr_decay_iters, min_lr: REAL_64
            global_norm_sq, grad_clip: REAL_64
            numeric_r32: ET_TENSOR_NUMERIC_REAL_64
            scalar_shape: ARRAY [INTEGER]
            l_pi: REAL_64
            loss_sum, loss_print, loss_t: REAL_64
            idx, n_limit: INTEGER
            logits, loss: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            total_loss_t: detachable ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            l_elem_real: ET_NUMERIC_ELEMENT [REAL_64]
            t_clip_scale: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
        do
            io.put_string_32 ({STRING_32} "Starting training for " + config.max_iters.out.to_string_32 + {STRING_32} " steps...%N")

            warmup_iters := 100.0
            lr_decay_iters := config.max_iters.to_double
            min_lr := config.learning_rate * 0.1
            l_pi := 3.141592653589793
            grad_clip := 0.1
            create numeric_r32
            create scalar_shape.make_empty

            from iter := 0 until iter >= config.max_iters loop
                -- 1. Sample document (Sequential for now)
                if docs.count > 0 then
                    text := docs [(iter \\ docs.count) + 1]
                else
                    text := {STRING_32} "Empty"
                end

                data := tokenizer.encode (text)
                
                n_limit := data.count - 1
                if n_limit > config.block_size then
                    n_limit := config.block_size
                end
                
                gpt.zero_grad
                gpt.reset_cache
                
                total_loss_t := Void
                loss_sum := 0.0

                -- Single forward pass per document (matching Python reference)
                xb := get_batch_full (data, config.block_size)
                yb := get_targets_full (data, config.block_size)

                t_xb := array_to_tensor_i32 (xb)
                t_yb := array_to_tensor_i32 (yb)

                debug
                    io.put_string_32 ({STRING_32} "  -> Starting forward pass for batch length " + xb.count.out.to_string_32 + {STRING_32} "...%N")
                end
                logits_loss := gpt.forward (t_xb, t_yb)
                debug
                    io.put_string_32 ({STRING_32} "  -> Forward pass complete.%N")
                end

                if iter = 0 then
                    if attached {ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]} logits_loss [1] as l_logits then
                        io.put_string_32 ({STRING_32} "Step 1, Pos 0 Logits:%N")
                        from idx := 0 until idx >= 27 loop
                            io.put_string_32 (numeric_r32.read (l_logits.data, idx * 8).item.out.to_string_32 + {STRING_32} "%N")
                            idx := idx + 1
                        end
                    end
                end

                if logits_loss.count >= 2 and then attached {ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]} logits_loss [2] as l_loss then
                    loss_t := numeric_r32.read (l_loss.data, l_loss.offset).item
                    loss_sum := loss_t
                    total_loss_t := l_loss
                end

                if attached total_loss_t as t_acc then
                    loss_print := loss_sum

                    -- Log every step
                    io.put_string_32 ({STRING_32} "step " + (iter + 1).out.to_string_32 + {STRING_32} " / " + config.max_iters.out.to_string_32 + {STRING_32} " | loss " + loss_print.out.to_string_32 + {STRING_32} "%N")

                    if attached total_loss_t as t_loss_b then
                        -- Backward
                        debug
                            io.put_string_32 ({STRING_32} "  -> Starting backward pass...%N")
                        end
                        t_loss_b.backward
                        debug
                            io.put_string_32 ({STRING_32} "  -> Backward pass complete.%N")
                        end
                    end

                    if iter = 0 then
                        debug
                            io.put_string_32 ({STRING_32} "  -> [DEBUG] Step 1 Parameter Gradients:%N")
                        end
                        across gpt.parameters as p loop
                            if attached p.grad as g then
                                debug
                                    io.put_string_32 ({STRING_32} "      param grad mean: " + g.mean.item_scalar.out.to_string_32 + {STRING_32} "%N")
                                end
                            else
                                debug
                                    io.put_string_32 ({STRING_32} "      param grad is NULL!%N")
                                end
                            end
                        end
                    end

                    -- Linear LR Scheduler (matching Python reference)
                    lr := config.learning_rate * (1.0 - (iter.to_double / config.max_iters.to_double))
                    adam.set_lr (lr)

                    -- Gradient Clipping (max_norm = 1.0)
                    global_norm_sq := 0.0
                    across gpt.parameters as p loop
                        if attached p.grad as g then
                            -- sum(g^2) = mean(g^2) * numel
                            global_norm_sq := global_norm_sq + ((g * g).mean.item_scalar.item * g.numel.to_double)
                        end
                    end
                    if global_norm_sq > grad_clip * grad_clip then
                        across gpt.parameters as p_clip loop
                            if attached p_clip.grad as g_clip then
                                create t_clip_scale.make_full (scalar_shape, numeric_r32.from_real_64 (grad_clip / sqrt (global_norm_sq)))
                                p_clip.set_grad (g_clip * t_clip_scale)
                            end
                        end
                    end

                    debug
                        io.put_string_32 ({STRING_32} "  -> Starting optimizer step...%N")
                    end
                    adam.step
                    debug
                        io.put_string_32 ({STRING_32} "  -> Optimizer step complete.%N")
                    end
                    else
                        io.put_string_32 ({STRING_32} "Warning: total_loss_t failed attachment at step " + iter.out.to_string_32 + {STRING_32} "%N")
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
            t_gen: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
        do
            io.put_string_32 ({STRING_32} "%N--- inference (sampling) ---%N")
            start_token := tokenizer.bos_token_id

            from iter := 1 until iter > 20 loop
                 create gen_idx.make_filled (start_token, 1, 1)
                 t_gen := array_to_tensor_i32 (gen_idx)
                 gen_res := gpt.generate (t_gen, (config.block_size - 1).min(50), 0.5, tokenizer.bos_token_id) -- 0.5 temp
                 io.put_string_32 ({STRING_32} "sample " + iter.out.to_string_32 + {STRING_32} ": " + tokenizer.decode (gen_res.to_array) + {STRING_32} "%N")
                 iter := iter + 1
            end
        end

    interactive_mode
        local
            input: STRING_32
            gen_idx: ARRAY [INTEGER]
            gen_res: ARRAYED_LIST [INTEGER]
            t_gen: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
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
                t_gen := array_to_tensor_i32 (gen_idx)

                gen_res := gpt.generate (t_gen, (config.block_size - 1).min(50), 0.7, tokenizer.bos_token_id)
                io.put_string_32 (tokenizer.decode (gen_res.to_array) + {STRING_32} "%N")

                io.put_string_32 ({STRING_32} "> ")
                io.read_line
            end
        end

feature {NONE} -- Implementation

    array_to_tensor_i32 (arr: ARRAY [INTEGER]): ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            -- Convert Eiffel integer array to 1D Tensor.
        local
            t: ET_TENSOR [ET_NUMERIC_ELEMENT [INTEGER_32]]
            elem: ET_NUMERIC_ELEMENT [INTEGER_32]
            i: INTEGER
        do
            create t.make_zeros (<<arr.count>>)
            create elem
            from i := 1 until i > arr.count loop
                elem.set_item (arr [i])
                t.put (elem, <<i>>)
                i := i + 1
            end
            Result := t
        end

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
                until
                    f.end_of_file
                loop
                    f.read_line
                    line := f.last_string.to_string_32
                    line.right_adjust
                    if not line.is_empty then
                        l.extend (line)
                    end
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
            f: RAW_FILE
        do
            create f.make_open_write ("model.ckpt")
            if f.exists and f.is_writable then
               across gpt.parameters as p loop
                   f.put_managed_pointer (p.data, 0, p.data.count)
               end
               f.close
               io.put_string_32 ({STRING_32} "Checkpoint saved to model.ckpt%N")
            else
               io.put_string_32 ({STRING_32} "Error: Cannot write to model.ckpt%N")
            end
        end

    load_checkpoint
        local
            f: RAW_FILE
            params: LIST [ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]]
            p: ET_TENSOR [ET_NUMERIC_ELEMENT [REAL_64]]
            count: INTEGER
        do
            create f.make_open_read ("model.ckpt")
            if f.exists and f.is_readable then
                io.put_string_32 ({STRING_32} "Loading checkpoint from model.ckpt...%N")
                params := gpt.parameters
                from
                    params.start
                until
                    f.exhausted or params.after
                loop
                    p := params.item
                    f.read_to_managed_pointer (p.data, 0, p.data.count)
                    params.forth
                    count := count + 1
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
