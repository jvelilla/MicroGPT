note
    description: "Tests for KV Cache in Multi-Head Attention."

class
    ET_TEST_KV_CACHE

inherit
    EQA_TEST_SET
        redefine
            on_prepare
        select
			default_create
        end
    DOUBLE_MATH
        rename
            default_create as dm_default_create
        end

feature -- Initialization

    on_prepare
        do
        end

feature -- Tests

    test_kv_cache_logic
        local
            mha: ET_MULTI_HEAD_ATTENTION
            n_embd, n_head, block_size: INTEGER
            dropout: REAL_64

            x: LINKED_LIST [LIST [ET_VALUE]] -- (T, C)
            out1, out2: LIST [LIST [ET_VALUE]]
            i: INTEGER

            row: LINKED_LIST [ET_VALUE]
            val_gen: REAL_64

            diff: REAL_64
            tol: REAL_64
        do
            print ("  [TEST] KV Cache... ")
            n_embd := 4
            n_head := 2
            block_size := 10
            dropout := 0.0
            tol := 1.0e-5

            create mha.make (n_embd, n_head, block_size, dropout)

            -- Create input sequence T=2
            -- [[0.1, 0.2, 0.3, 0.4],
            --  [0.5, 0.6, 0.7, 0.8]]

            create x.make
            -- Row 1
            create row.make
            row.extend (create {ET_VALUE}.make (0.1))
            row.extend (create {ET_VALUE}.make (0.2))
            row.extend (create {ET_VALUE}.make (0.3))
            row.extend (create {ET_VALUE}.make (0.4))
            x.extend (row)

            -- Row 2
            create row.make
            row.extend (create {ET_VALUE}.make (0.5))
            row.extend (create {ET_VALUE}.make (0.6))
            row.extend (create {ET_VALUE}.make (0.7))
            row.extend (create {ET_VALUE}.make (0.8))
            x.extend (row)

            -- 1. Run without cache (Standard)
            out1 := mha.forward (x)

            -- 2. Run with cache (Step by Step)
            mha.init_cache (10)

            -- Step 1: Input 1

             -- Input 1
             create {LINKED_LIST [LIST [ET_VALUE]]} x.make
             create row.make
            row.extend (create {ET_VALUE}.make (0.1))
            row.extend (create {ET_VALUE}.make (0.2))
            row.extend (create {ET_VALUE}.make (0.3))
            row.extend (create {ET_VALUE}.make (0.4))
            x.extend (row)

            -- Forward 1
            out2 := mha.forward (x) -- returns list of 1 list

            -- Check out2[1] ~ out1[1]
            check_approx (out2.first, out1.first, tol)

            -- Input 2
            create {LINKED_LIST [LIST [ET_VALUE]]} x.make
            create row.make
            row.extend (create {ET_VALUE}.make (0.5))
            row.extend (create {ET_VALUE}.make (0.6))
            row.extend (create {ET_VALUE}.make (0.7))
            row.extend (create {ET_VALUE}.make (0.8))
            x.extend (row)

            -- Forward 2
            out2 := mha.forward (x)

            -- Check out2[1] ~ out1[2]
            check_approx (out2.first, out1.i_th (2), tol)

            print ("OK%N")
        end

    check_approx (l1, l2: LIST [ET_VALUE]; tol: REAL_64)
        local
            i: INTEGER
            v1, v2: REAL_64
            al1, al2: ARRAYED_LIST [ET_VALUE]
        do
            assert ("Length match", l1.count = l2.count)
            create al1.make_from_iterable (l1)
            create al2.make_from_iterable (l2)

            from i := 1 until i > al1.count loop
                v1 := al1.i_th (i).data
                v2 := al2.i_th (i).data
                assert ("Value mismatch at " + i.out + ": " + v1.out + " vs " + v2.out, (v1 - v2).abs <= tol)
                i := i + 1
            end
        end

end
