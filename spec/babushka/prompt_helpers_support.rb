include PromptHelpers

def read_from_prompt prompt = '? ', choices = nil
  (@values.shift || '').to_s
end
