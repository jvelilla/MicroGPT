note
    description: "MicroGPT Application"

class
    APPLICATION

create
    make

feature {NONE} -- Initialization

    make
            -- Run application.
        local
            config: MICROGPT_CONFIG
            trainer: TRAINER
        do
            create config.make_from_args
            if config.mode.is_equal ("test") then
                print ("To run tests, please use the 'tests' target: ec -target tests ...%N")
            else
                create trainer.make (config)

                if config.mode.is_equal ("train") then
                    trainer.train
                    trainer.generate_samples
                elseif config.mode.is_equal ("interactive") then
                    trainer.load_checkpoint
                    trainer.interactive_mode
                end
            end
        end

end
