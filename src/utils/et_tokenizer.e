note
    description: "Simple character level tokenizer"

class
    ET_TOKENIZER

create
    make

feature -- Initialization

    make (texts: LIST [READABLE_STRING_GENERAL])
        local
            chars: LINKED_SET [CHARACTER_32]
            sorted_chars: SORTED_TWO_WAY_LIST [CHARACTER_32]
            i: INTEGER
            s: READABLE_STRING_GENERAL
        do
            create chars.make
            across texts as t loop
                -- Iterate using index
                s := t
                from
                    i := 1
                until
                    i > s.count
                loop
                     chars.put (s.item (i).to_character_32)
                     i := i + 1
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
            stoi.put (bos_token_id, {CHARACTER_32} '.') -- Use '.' to represent BOS/PAD if needed for visualization
            itos.put ({CHARACTER_32} '.', bos_token_id)
        end

feature -- Access

    vocab_size: INTEGER
    stoi: HASH_TABLE [INTEGER, CHARACTER_32]
    itos: HASH_TABLE [CHARACTER_32, INTEGER]
    bos_token_id: INTEGER

feature -- Operations

    encode (text: READABLE_STRING_GENERAL): ARRAY [INTEGER]
            -- Encode `text` into a sequence of token IDs.
        local
            res: ARRAYED_LIST [INTEGER]
            i: INTEGER
        do
            create res.make (text.count + 2)
            from
                i := 1
            until
                i > text.count
            loop
                if stoi.has (text.item (i).to_character_32) then
                    res.extend (stoi.item (text.item (i).to_character_32))
                else
                    res.extend (bos_token_id)
                end
                i := i + 1
            end
            res.extend (bos_token_id)
            Result := res.to_array
        end
        
    decode (indices: ARRAY [INTEGER]): STRING_32
            -- Decode sequence of `indices` back to text.
        local
            res: STRING_32
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
