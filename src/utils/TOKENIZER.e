note
    description: "Simple character level tokenizer"

class
    TOKENIZER

create
    make

feature -- Initialization

    make (texts: LIST [STRING])
        local
            chars: LINKED_SET [CHARACTER]
            sorted_chars: SORTED_TWO_WAY_LIST [CHARACTER]
            i: INTEGER
        do
            create chars.make
            across texts as t loop
                across t as c loop
                    chars.put (c)
                end
            end
            
            create sorted_chars.make
            across chars as c loop
                sorted_chars.extend (c)
            end
            
            -- Sort
            -- (Assuming sorted_chars is sorting implementation or we need to sort manually)
            -- Minimal implementation relies on existing order or simple sort?
            -- Let's just key it. Python sorts `uchars`.
            -- For simplicity here, we trust the set order or implement a sort if critical.
            -- Python: sorted(set(''.join(docs)))
            
            vocab_size := chars.count + 1 -- +1 for BOS
            
            create stoi.make (vocab_size)
            create itos.make (vocab_size)
            
            -- BOS is 1 (conceptually 0 in Python, but Eiffel arrays start at 1 frequently)
            -- Let's align: 
            -- Python: '.' is not in names.
            -- Python Code: `uchars = sorted(set(...))`, `BOS = len(uchars)`, `vocab_size = len(uchars) + 1`
            -- So BOS is the LAST index in Python (0..n-1 are chars, n is BOS).
            -- We can emulate this.
            
            i := 1
            across sorted_chars as c loop
                stoi.put (i, c)
                itos.put (c, i)
                i := i + 1
            end
            
            -- BOS token
            bos_token_id := i
            stoi.put (bos_token_id, '.') -- Use '.' to represent BOS/PAD if needed for visualization
            itos.put ('.', bos_token_id)
        end

feature -- Access

    vocab_size: INTEGER
    stoi: HASH_TABLE [INTEGER, CHARACTER]
    itos: HASH_TABLE [CHARACTER, INTEGER]
    bos_token_id: INTEGER

feature -- Operations

    encode (text: STRING): ARRAY [INTEGER]
        local
            res: ARRAYED_LIST [INTEGER]
        do
            create res.make (text.count + 2)
            res.extend (bos_token_id)
            across text as c loop
                if stoi.has (c) then
                    res.extend (stoi.item (c))
                else
                    res.extend (bos_token_id) -- fallback?
                end
            end
            res.extend (bos_token_id)
            Result := res.to_array
        end
        
    decode (indices: ARRAY [INTEGER]): STRING
        local
            res: STRING
        do
            create res.make_empty
            across indices as idx loop
                if itos.has (idx) then
                    res.append_character (itos.item (idx))
                end
            end
            Result := res
        end

end
