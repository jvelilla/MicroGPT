note
    description: "Adam Optimizer for Tensors"

class
    ET_TENSOR_ADAM [G -> ET_TENSOR_ELEMENT]

create
    make

feature -- Initialization

    make (a_params: LIST [ET_TENSOR [G]]; a_lr, a_beta1, a_beta2, a_eps: REAL_64)
            -- Initialize with parameters and hyperparameters.
        local
            i: INTEGER
            l_m, l_v: ARRAY [REAL_64]
            params_arr: ARRAYED_LIST [ET_TENSOR [G]]
        do
            params := a_params
            lr := a_lr
            beta1 := a_beta1
            beta2 := a_beta2
            eps := a_eps
            
            -- Initialize moment buffers
            create params_arr.make_from_iterable (params)
            create m.make (params_arr.count)
            create v.make (params_arr.count)
            
            from i := 1 until i > params_arr.count loop
                create l_m.make_filled (0.0, 1, params_arr [i].numel)
                create l_v.make_filled (0.0, 1, params_arr [i].numel)
                m.extend (l_m)
                v.extend (l_v)
                i := i + 1
            end
            
            t := 0
        end

feature -- Access

    params: LIST [ET_TENSOR [G]]
    lr, beta1, beta2, eps: REAL_64
    m, v: ARRAYED_LIST [ARRAY [REAL_64]]
    t: INTEGER

feature -- Operations

    step
            -- Perform a single optimization step.
        require
            params_not_empty: not params.is_empty
        local
            i, j: INTEGER
            p, l_grad: ET_TENSOR [G]
            val_p, val_g: REAL_64
            m_j, v_j: REAL_64
            m_hat, v_hat: REAL_64
            params_arr: ARRAYED_LIST [ET_TENSOR [G]]
            l_m, l_v: ARRAY [REAL_64]
            l_helper: ET_TENSOR_HELPER
            l_offset: INTEGER
            l_new_p: REAL_64
            l_t_beta1, l_t_beta2: REAL_64
        do
            t := t + 1
            create params_arr.make_from_iterable (params)
            create l_helper
            
            l_t_beta1 := 1.0 - beta1 ^ t
            l_t_beta2 := 1.0 - beta2 ^ t
            
            from i := 1 until i > params_arr.count loop
                p := params_arr [i]
                if attached p.grad as g then
                	l_grad := g
                	l_m := m [i]
                	l_v := v [i]
                	
                	from j := 1 until j > p.numel loop
                		l_offset := p.offset + (j - 1) * l_helper.element_size (({G}).type_id)
                		
                		if ({G}).type_id = ({REAL_32}).type_id then
                			val_p := l_helper.read_real_32 (p.data, l_offset)
                			val_g := l_helper.read_real_32 (l_grad.data, l_offset)
                		else
                			val_p := l_helper.read_real_64 (p.data, l_offset)
                			val_g := l_helper.read_real_64 (l_grad.data, l_offset)
                		end
                		
                		-- Update moments
                		m_j := beta1 * l_m [j] + (1.0 - beta1) * val_g
                		v_j := beta2 * l_v [j] + (1.0 - beta2) * (val_g * val_g)
                		l_m [j] := m_j
                		l_v [j] := v_j
                		
                		-- Bias correction
                		m_hat := m_j / l_t_beta1
                		v_hat := v_j / l_t_beta2
                		
                		-- Update parameter
                		l_new_p := val_p - lr * m_hat / ({DOUBLE_MATH}.sqrt (v_hat) + eps)
                		
                		if ({G}).type_id = ({REAL_32}).type_id then
                			l_helper.put_real_32 (p.data, l_offset, l_new_p.truncated_to_real)
                		else
                			l_helper.put_real_64 (p.data, l_offset, l_new_p)
                		end
                		
                		j := j + 1
                	end
                end
                
                i := i + 1
            end
        end
        
    zero_grad
            -- Zero gradients of all parameters.
        local
        	l_zero_grad: ET_TENSOR [G]
        	shape: ARRAY [INTEGER]
        do
            across params as p loop
            	if attached p.grad as g then
            		shape := p.shape.deep_twin
            		create l_zero_grad.make_zeros (shape)
            		p.set_grad (l_zero_grad)
            	end
            end
        end

end
