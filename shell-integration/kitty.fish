#!/bin/fish

function _ksi_main
    test -z "$KITTY_SHELL_INTEGRATION" && return
    set --local _ksi (string split " " -- "$KITTY_SHELL_INTEGRATION")
    set --erase KITTY_SHELL_INTEGRATION

    function _ksi_osc
        printf "\e]%s\a" "$argv[1]"
    end

    if ! contains "no-prompt-mark" $_ksi
        set --global _ksi_prompt_state "first-run"

        function _ksi_function_is_not_empty -d "Check if the specified function exists and is not empty"
            test (functions $argv[1] | grep -cvE '^ *(#|function |end$|$)') != 0
        end

        function _ksi_mark -d "tell kitty to mark the current cursor position using OSC 133"
            _ksi_osc "133;$argv[1]";
        end

        function _ksi_start_prompt
            if test "$_ksi_prompt_state" != "postexec" -a "$_ksi_prompt_state" != "first-run"
                _ksi_mark "D"
            end
            set --global _ksi_prompt_state "prompt_start"
            _ksi_mark "A"
        end

        function _ksi_end_prompt
            _ksi_original_fish_prompt
            set --global _ksi_prompt_state "prompt_end"
            _ksi_mark "B"
        end

        functions -c fish_prompt _ksi_original_fish_prompt

        if _ksi_function_is_not_empty fish_mode_prompt
            # see https://github.com/starship/starship/issues/1283
            # for why we have to test for a non-empty fish_mode_prompt
            functions -c fish_mode_prompt _ksi_original_fish_mode_prompt
            function fish_mode_prompt
                _ksi_start_prompt
                _ksi_original_fish_mode_prompt
            end
            function fish_prompt
                _ksi_end_prompt
            end
        else
            function fish_prompt
                _ksi_start_prompt
                _ksi_end_prompt
            end
        end

        function _ksi_mark_output_start --on-event fish_preexec
            set --global _ksi_prompt_state "preexec"
            _ksi_mark "C"
        end

        function _ksi_mark_output_end --on-event fish_postexec
            set --global _ksi_prompt_state "postexec"
            _ksi_mark "D;$status"
        end
        # with prompt marking kitty clears the current prompt on resize so we need
        # fish to redraw it
        set --global fish_handle_reflow 1
    end
    functions --erase _ksi_main
    functions --erase _ksi_schedule
end

if status --is-interactive
    function _ksi_schedule --on-event fish_prompt -d "Setup kitty integration after other scripts have run, we hope"
        _ksi_main
    end
else
    functions --erase _ksi_main
end
