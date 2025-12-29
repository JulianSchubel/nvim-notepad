--Debounce: Reduce multiple rapid events in succession to one controlled action.
--Executes the provided function `fn` once after events stop.
local function debounce(fn)
    return function()
        local resize_timer;
        return function ()
            if resize_timer then
                    resize_timer:stop()
                    resize_timer:close()
            end
            resize_timer = vim.uv.new_timer();
            resize_timer:start(30, 0, function()
                fn();
            end)
        end
    end
end

return debounce;
